import '../repositories/task_repository.dart';

class DeleteTaskUseCase {
  final TaskRepository repository;
  const DeleteTaskUseCase(this.repository);

  Future<void> call(int taskId) => repository.softDeleteTask(taskId);
}