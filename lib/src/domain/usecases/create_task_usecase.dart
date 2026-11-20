import '../repositories/task_repository.dart';

class CreateTaskUseCase {
  final TaskRepository repository;
  const CreateTaskUseCase(this.repository);

  Future<int> call({required String title, required String description, required int projectId, int? assigneeId, String priority = 'medium', String status = 'todo', int? deadline, int? changedBy}) =>
      repository.createTask(title: title, description: description, projectId: projectId, assigneeId: assigneeId, priority: priority, status: status, deadline: deadline, changedBy: changedBy);
}