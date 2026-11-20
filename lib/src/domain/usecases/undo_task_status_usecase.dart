import '../repositories/task_repository.dart';
class UndoTaskStatusUseCase {
  final TaskRepository repository;
  const UndoTaskStatusUseCase(this.repository);
  Future<void> call(int taskId, {int? changedBy}) => repository.undoStatus(taskId, changedBy: changedBy);
}