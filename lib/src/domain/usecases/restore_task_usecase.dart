import '../repositories/task_repository.dart';
class RestoreTaskUseCase {
  final TaskRepository repository;
  const RestoreTaskUseCase(this.repository);
  Future<void> call(int taskId) => repository.restoreTask(taskId);
}