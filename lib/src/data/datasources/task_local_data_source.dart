import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../models/task_model.dart';

abstract class TaskLocalDataSource {
  Stream<List<TaskModel>> watchTasks({
    int? projectId,
    String? status,
    String? priority,
    int? assigneeId,
    String query,
    bool trash,
    bool sortByDeadline,
    int limit,
    int offset,
  });

  Future<int> createTask({
    required String title,
    required String description,
    required int projectId,
    int? assigneeId,
    String priority,
    String status,
    int? deadline,
    int? changedBy,
  });
  Future<void> updateTask(int id, {required String title, required String description, required String priority, int? deadline});
  Future<void> changeStatus(int taskId, String next, {int? changedBy});
  Future<void> softDeleteTask(int id);
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final AppDatabase database;

  const TaskLocalDataSourceImpl(this.database);

  int _now() => DateTime.now().millisecondsSinceEpoch;

  @override
  Stream<List<TaskModel>> watchTasks({
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
    final request = database.select(database.tasks)
      ..limit(limit, offset: offset)
      ..orderBy([
        (task) => sortByDeadline
            ? OrderingTerm.asc(task.deadline)
            : OrderingTerm.desc(task.createdAt),
      ]);

    request.where((task) {
      Expression<bool> condition = trash
          ? task.deletedAt.isNotNull()
          : task.deletedAt.isNull();
      if (projectId != null) condition = condition & task.projectId.equals(projectId);
      if (status != null) condition = condition & task.status.equals(status);
      if (priority != null) condition = condition & task.priority.equals(priority);
      if (assigneeId != null) condition = condition & task.assigneeId.equals(assigneeId);
      if (query.trim().isNotEmpty) {
        final pattern = '%${query.trim()}%';
        condition = condition & (task.title.like(pattern) | task.description.like(pattern));
      }
      return condition;
    });

    return request.watch().map((rows) => rows.map(TaskModel.fromDatabase).toList());
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
  }) async {
    if (title.trim().isEmpty) throw ArgumentError('Название задачи обязательно');
    if (!['low', 'medium', 'high', 'critical'].contains(priority)) throw ArgumentError('Некорректный приоритет');
    if (!['todo', 'inProgress', 'done', 'cancelled'].contains(status)) throw ArgumentError('Некорректный статус задачи');
    final project = await (database.select(database.projects)..where((p) => p.id.equals(projectId))).getSingleOrNull();
    if (project == null) throw StateError('Проект не существует');
    if (assigneeId != null) {
      final member = await (database.select(database.projectMembers)..where((m) => m.projectId.equals(projectId) & m.userId.equals(assigneeId))).getSingleOrNull();
      if (member == null) throw StateError('Исполнитель не состоит в проекте');
    }
    return database.transaction(() async {
      final now = _now();
      final id = await database.into(database.tasks).insert(TasksCompanion.insert(
        title: title.trim(), description: Value(description.trim()), projectId: projectId,
        assigneeId: Value(assigneeId), priority: Value(priority), status: Value(status),
        deadline: Value(deadline), createdAt: now, updatedAt: now,
      ));
      await database.into(database.taskHistory).insert(TaskHistoryCompanion.insert(
        taskId: id, previousStatus: const Value.absent(), newStatus: status,
        changedBy: Value(changedBy), changedAt: now, details: const Value('Задача создана'),
      ));
      return id;
    });
  }

  @override
  Future<void> updateTask(int id, {required String title, required String description, required String priority, int? deadline}) async {
    if (title.trim().isEmpty) throw ArgumentError('Название задачи обязательно');
    if (!['low', 'medium', 'high', 'critical'].contains(priority)) throw ArgumentError('Некорректный приоритет');
    await (database.update(database.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(title: Value(title.trim()), description: Value(description.trim()), priority: Value(priority), deadline: Value(deadline), updatedAt: Value(_now())),
    );
  }

  @override
  Future<void> changeStatus(int taskId, String next, {int? changedBy}) async {
    if (!['todo', 'inProgress', 'done', 'cancelled'].contains(next)) throw ArgumentError('Некорректный статус задачи');
    await database.transaction(() async {
      final task = await (database.select(database.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      if (task.status == next) return;
      final now = _now();
      await (database.update(database.tasks)..where((t) => t.id.equals(taskId))).write(TasksCompanion(status: Value(next), updatedAt: Value(now)));
      await database.into(database.taskHistory).insert(TaskHistoryCompanion.insert(
        taskId: taskId, previousStatus: Value(task.status), newStatus: next, changedBy: Value(changedBy), changedAt: now,
      ));
    });
  }

  @override
  Future<void> softDeleteTask(int id) async {
    final now = _now();
    await (database.update(database.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }
}