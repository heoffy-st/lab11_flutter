import '../repositories/task_repository.dart';

class UpdateTaskUseCase {
  final TaskRepository repository;
  const UpdateTaskUseCase(this.repository);

  Future<void> call(int id, {required String title, required String description, required String priority, int? deadline}) =>
      repository.updateTask(id, title: title, description: description, priority: priority, deadline: deadline);
}