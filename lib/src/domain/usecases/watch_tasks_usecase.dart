import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class WatchTasksUseCase {
  final TaskRepository repository;

  const WatchTasksUseCase(this.repository);

  Stream<List<TaskEntity>> call({
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
    return repository.watchTasks(
      projectId: projectId,
      status: status,
      priority: priority,
      assigneeId: assigneeId,
      query: query,
      trash: trash,
      sortByDeadline: sortByDeadline,
      limit: limit,
      offset: offset,
    );
  }
}
