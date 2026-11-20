import '../repositories/task_repository.dart';
class ReassignTaskUseCase {
  final TaskRepository repository;
  const ReassignTaskUseCase(this.repository);
  Future<void> call(int taskId, int? userId, {int? changedBy}) => repository.reassignTask(taskId, userId, changedBy: changedBy);
}