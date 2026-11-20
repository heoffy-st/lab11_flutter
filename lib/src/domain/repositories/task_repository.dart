import '../entities/task_entity.dart';

abstract class TaskRepository {
  Stream<List<TaskEntity>> watchTasks({int? projectId, String? status, String? priority, int? assigneeId, String query = '', bool trash = false, bool sortByDeadline = false, int limit = 30, int offset = 0});
  Future<int> createTask({required String title, required String description, required int projectId, int? assigneeId, String priority = 'medium', String status = 'todo', int? deadline, int? changedBy});
  Future<void> updateTask(int id, {required String title, required String description, required String priority, int? deadline});
  Future<void> changeStatus(int taskId, String next, {int? changedBy});
  Future<void> softDeleteTask(int id);
  Future<void> reassignTask(int taskId, int? userId, {int? changedBy});
  Future<void> undoStatus(int taskId, {int? changedBy});
  Future<void> restoreTask(int id);
  Future<void> permanentlyDeleteTask(int id);
}