import '../repositories/task_repository.dart';
class PermanentlyDeleteTaskUseCase {
  final TaskRepository repository;
  const PermanentlyDeleteTaskUseCase(this.repository);
  Future<void> call(int taskId) => repository.permanentlyDeleteTask(taskId);
}