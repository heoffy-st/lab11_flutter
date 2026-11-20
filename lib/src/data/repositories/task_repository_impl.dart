import '../../../core/error/error_mapper.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;
  const TaskRepositoryImpl(this.localDataSource);

  @override
  Stream<List<TaskEntity>> watchTasks({
    int? projectId, String? status, String? priority, int? assigneeId,
    String query = '', bool trash = false, bool sortByDeadline = false,
    int limit = 30, int offset = 0,
  }) {
    return localDataSource.watchTasks(
      projectId: projectId, status: status, priority: priority,
      assigneeId: assigneeId, query: query, trash: trash,
      sortByDeadline: sortByDeadline, limit: limit, offset: offset,
    ).map((models) => models.map((model) => model.toEntity()).toList())
      .handleError((Object error) { throw ErrorMapper.toFailure(error); });
  }

  @override
  Future<int> createTask({required String title, required String description, required int projectId, int? assigneeId, String priority = 'medium', String status = 'todo', int? deadline, int? changedBy}) async {
    try {
      return await localDataSource.createTask(title: title, description: description, projectId: projectId, assigneeId: assigneeId, priority: priority, status: status, deadline: deadline, changedBy: changedBy);
    } catch (error) { throw ErrorMapper.toFailure(error); }
  }

  @override
  Future<void> updateTask(int id, {required String title, required String description, required String priority, int? deadline}) async {
    try { await localDataSource.updateTask(id, title: title, description: description, priority: priority, deadline: deadline); }
    catch (error) { throw ErrorMapper.toFailure(error); }
  }

  @override
  Future<void> changeStatus(int taskId, String next, {int? changedBy}) async {
    try { await localDataSource.changeStatus(taskId, next, changedBy: changedBy); }
    catch (error) { throw ErrorMapper.toFailure(error); }
  }

  @override
  Future<void> softDeleteTask(int id) async {
    try { await localDataSource.softDeleteTask(id); }
    catch (error) { throw ErrorMapper.toFailure(error); }
  }
}