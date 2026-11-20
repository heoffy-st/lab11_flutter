import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/src/domain/entities/task_entity.dart';
import 'package:taskflow/src/domain/repositories/task_repository.dart';
import 'package:taskflow/src/domain/usecases/change_task_status_usecase.dart';
import 'package:taskflow/src/domain/usecases/create_task_usecase.dart';
import 'package:taskflow/src/domain/usecases/delete_task_usecase.dart';
import 'package:taskflow/src/domain/usecases/permanently_delete_task_usecase.dart';
import 'package:taskflow/src/domain/usecases/reassign_task_usecase.dart';
import 'package:taskflow/src/domain/usecases/restore_task_usecase.dart';
import 'package:taskflow/src/domain/usecases/undo_task_status_usecase.dart';
import 'package:taskflow/src/domain/usecases/update_task_usecase.dart';
import 'package:taskflow/src/domain/usecases/watch_tasks_usecase.dart';
import 'package:taskflow/src/presentation/providers/task_list_controller.dart';
import 'package:taskflow/src/presentation/providers/task_list_state.dart';

class _FakeTaskRepository implements TaskRepository {
  final List<String> watchedQueries = [];

  @override
  Stream<List<TaskEntity>> watchTasks({
    int? projectId,
    String? status,
    String? priority,
    int? assigneeId,
    String query = '',
    bool trash = false,
    bool sortByDeadline = false,
    int limit = 30,
    int offset = 0,
  }) {
    watchedQueries.add(query);
    return Stream.value(const []);
  }

  @override
  Future<int> createTask({
    required String title,
    required String description,
    required int projectId,
    int? assigneeId,
    String priority = 'medium',
    String status = 'todo',
    int? deadline,
    int? changedBy,
  }) async => 1;

  @override
  Future<void> updateTask(
    int id, {
    required String title,
    required String description,
    required String priority,
    int? deadline,
  }) async {}

  @override
  Future<void> changeStatus(int taskId, String next, {int? changedBy}) async {}

  @override
  Future<void> softDeleteTask(int id) async {}

  @override
  Future<void> reassignTask(int taskId, int? userId, {int? changedBy}) async {}

  @override
  Future<void> undoStatus(int taskId, {int? changedBy}) async {}

  @override
  Future<void> restoreTask(int id) async {}

  @override
  Future<void> permanentlyDeleteTask(int id) async {}
}

void main() {
  late _FakeTaskRepository repository;
  late TaskListController controller;

  setUp(() {
    repository = _FakeTaskRepository();
    controller = TaskListController(
      watchTasksUseCase: WatchTasksUseCase(repository),
      createTaskUseCase: CreateTaskUseCase(repository),
      updateTaskUseCase: UpdateTaskUseCase(repository),
      changeTaskStatusUseCase: ChangeTaskStatusUseCase(repository),
      deleteTaskUseCase: DeleteTaskUseCase(repository),
      reassignTaskUseCase: ReassignTaskUseCase(repository),
      undoTaskStatusUseCase: UndoTaskStatusUseCase(repository),
      restoreTaskUseCase: RestoreTaskUseCase(repository),
      permanentlyDeleteTaskUseCase: PermanentlyDeleteTaskUseCase(repository),
    );
  });

  tearDown(() => controller.dispose());

  test('search waits until typing is paused', () async {
    controller.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    repository.watchedQueries.clear();

    controller.updateSearch('t');
    controller.updateSearch('ta');
    controller.updateSearch('task');

    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(repository.watchedQueries, isEmpty);

    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(repository.watchedQueries, ['task']);
    expect(controller.status, TaskListStatus.empty);
  });
}
