import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/watch_tasks_usecase.dart';
import 'task_list_state.dart';

class TaskListController extends ChangeNotifier {
  final WatchTasksUseCase watchTasksUseCase;

  TaskListController(this.watchTasksUseCase);

  StreamSubscription<List<TaskEntity>>? _subscription;
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

  void loadTasks() {
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
    ).listen(
      (items) {
        tasks = items;
        status = items.isEmpty ? TaskListStatus.empty : TaskListStatus.success;
        errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        status = TaskListStatus.error;
        errorMessage = 'Не удалось загрузить задачи. Попробуйте ещё раз.';
        notifyListeners();
      },
    );
  }

  void updateSearch(String value) {
    query = value;
    loadTasks();
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
    _subscription?.cancel();
    super.dispose();
  }
}
