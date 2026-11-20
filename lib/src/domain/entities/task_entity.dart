class TaskEntity {
  final int id;
  final String title;
  final String description;
  final int projectId;
  final int? assigneeId;
  final String priority;
  final String status;
  final int? deadline;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;

  const TaskEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.projectId,
    this.assigneeId,
    required this.priority,
    required this.status,
    this.deadline,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
}
