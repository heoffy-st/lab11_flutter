import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/error/failures.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/watch_tasks_usecase.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../domain/usecases/update_task_usecase.dart';
import '../../domain/usecases/change_task_status_usecase.dart';
import '../../domain/usecases/delete_task_usecase.dart';
import '../../domain/usecases/reassign_task_usecase.dart';
import '../../domain/usecases/undo_task_status_usecase.dart';
import '../../domain/usecases/restore_task_usecase.dart';
import '../../domain/usecases/permanently_delete_task_usecase.dart';
import 'task_list_state.dart';

class TaskListController extends ChangeNotifier {
  final WatchTasksUseCase watchTasksUseCase;
  final CreateTaskUseCase createTaskUseCase;
  final UpdateTaskUseCase updateTaskUseCase;
  final ChangeTaskStatusUseCase changeTaskStatusUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;
  final ReassignTaskUseCase reassignTaskUseCase;
  final UndoTaskStatusUseCase undoTaskStatusUseCase;
  final RestoreTaskUseCase restoreTaskUseCase;
  final PermanentlyDeleteTaskUseCase permanentlyDeleteTaskUseCase;

  TaskListController({
    required this.watchTasksUseCase,
    required this.createTaskUseCase,
    required this.updateTaskUseCase,
    required this.changeTaskStatusUseCase,
    required this.deleteTaskUseCase,
    required this.reassignTaskUseCase,
    required this.undoTaskStatusUseCase,
    required this.restoreTaskUseCase,
    required this.permanentlyDeleteTaskUseCase,
  });

  static const searchDebounceDuration = Duration(milliseconds: 400);

  StreamSubscription<List<TaskEntity>>? _subscription;
  Timer? _searchTimer;
  List<TaskEntity> tasks = const [];
  TaskListStatus status = TaskListStatus.initial;
  String? errorMessage;
  String query = '';
  String? selectedStatus;
  String? selectedPriority;
  int? selectedAssignee;
  bool sortByDeadline = false;
  int limit = 30;

  void start() => loadTasks();

  Stream<List<TaskEntity>> watchTrashTasks() =>
      watchTasksUseCase(trash: true, limit: 1000);

  void loadTasks() {
    _searchTimer?.cancel();
    _subscription?.cancel();
    status = TaskListStatus.loading;
    errorMessage = null;
    notifyListeners();
    _subscription = watchTasksUseCase(
      query: query,
      status: selectedStatus,
      priority: selectedPriority,
      assigneeId: selectedAssignee,
      sortByDeadline: sortByDeadline,
      limit: limit,
    ).listen((items) {
      tasks = items;
      status = items.isEmpty ? TaskListStatus.empty : TaskListStatus.success;
      errorMessage = null;
      notifyListeners();
    }, onError: (Object error) {
      status = TaskListStatus.error;
      errorMessage = error is Failure
          ? error.message
          : const UnknownFailure().message;
      notifyListeners();
    });
  }

  Future<int> createTask({
    required String title,
    required String description,
    required int projectId,
    int? assigneeId,
    String priority = 'medium',
    int? deadline,
    int? changedBy,
  }) =>
      createTaskUseCase(
        title: title,
        description: description,
        projectId: projectId,
        assigneeId: assigneeId,
        priority: priority,
        deadline: deadline,
        changedBy: changedBy,
      );

  Future<void> updateTask(
    int id, {
    required String title,
    required String description,
    required String priority,
    int? deadline,
  }) =>
      updateTaskUseCase(
        id,
        title: title,
        description: description,
        priority: priority,
        deadline: deadline,
      );

  Future<void> changeStatus(int id, String status, {int? changedBy}) =>
      changeTaskStatusUseCase(id, status, changedBy: changedBy);

  Future<void> deleteTask(int id) => deleteTaskUseCase(id);

  Future<void> reassignTask(int id, int? userId, {int? changedBy}) =>
      reassignTaskUseCase(id, userId, changedBy: changedBy);

  Future<void> undoStatus(int id, {int? changedBy}) =>
      undoTaskStatusUseCase(id, changedBy: changedBy);

  Future<void> restoreTask(int id) => restoreTaskUseCase(id);

  Future<void> permanentlyDeleteTask(int id) =>
      permanentlyDeleteTaskUseCase(id);

  /// Search is applied only after the user pauses typing for 400 ms.
  void updateSearch(String value) {
    query = value;
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDebounceDuration, loadTasks);
  }

  void updateStatus(String? value) {
    selectedStatus = value;
    loadTasks();
  }

  void updatePriority(String? value) {
    selectedPriority = value;
    loadTasks();
  }

  void updateAssignee(int? value) {
    selectedAssignee = value;
    loadTasks();
  }

  void toggleSort() {
    sortByDeadline = !sortByDeadline;
    loadTasks();
  }

  void loadMore() {
    limit += 30;
    loadTasks();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
