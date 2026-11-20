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
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final AppDatabase database;

  const TaskLocalDataSourceImpl(this.database);

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

      if (projectId != null) {
        condition = condition & task.projectId.equals(projectId);
      }
      if (status != null) {
        condition = condition & task.status.equals(status);
      }
      if (priority != null) {
        condition = condition & task.priority.equals(priority);
      }
      if (assigneeId != null) {
        condition = condition & task.assigneeId.equals(assigneeId);
      }
      if (query.trim().isNotEmpty) {
        final pattern = '%${query.trim()}%';
        condition = condition &
            (task.title.like(pattern) | task.description.like(pattern));
      }
      return condition;
    });

    return request.watch().map(
          (rows) => rows.map(TaskModel.fromDatabase).toList(),
        );
  }
}
