import '../../../database/app_database.dart';
import '../../domain/entities/task_entity.dart';

class TaskModel {
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

  const TaskModel({
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

  factory TaskModel.fromDatabase(Task row) => TaskModel(
        id: row.id,
        title: row.title,
        description: row.description,
        projectId: row.projectId,
        assigneeId: row.assigneeId,
        priority: row.priority,
        status: row.status,
        deadline: row.deadline,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
      );

  TaskEntity toEntity() => TaskEntity(
        id: id,
        title: title,
        description: description,
        projectId: projectId,
        assigneeId: assigneeId,
        priority: priority,
        status: status,
        deadline: deadline,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );
}
