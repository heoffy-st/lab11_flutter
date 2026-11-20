import '../entities/task_entity.dart';

abstract class TaskRepository {
  Stream<List<TaskEntity>> watchTasks({
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
