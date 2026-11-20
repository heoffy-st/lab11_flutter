import '../../../core/error/error_mapper.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;

  const TaskRepositoryImpl(this.localDataSource);

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
    return localDataSource
        .watchTasks(
          projectId: projectId,
          status: status,
          priority: priority,
          assigneeId: assigneeId,
          query: query,
          trash: trash,
          sortByDeadline: sortByDeadline,
          limit: limit,
          offset: offset,
        )
        .map((models) => models.map((model) => model.toEntity()).toList())
        .handleError((Object error) {
          throw ErrorMapper.toFailure(error);
        });
  }
}
