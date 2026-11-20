import '../repositories/task_repository.dart';

class ChangeTaskStatusUseCase {
  final TaskRepository repository;
  const ChangeTaskStatusUseCase(this.repository);

  Future<void> call(int taskId, String status, {int? changedBy}) =>
      repository.changeStatus(taskId, status, changedBy: changedBy);
}