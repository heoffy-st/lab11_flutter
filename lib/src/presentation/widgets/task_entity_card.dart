// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../../domain/entities/task_entity.dart';

class TaskEntityCard extends StatelessWidget {
  final TaskEntity task;

  const TaskEntityCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    const statusNames = {
      'todo': 'Ожидает',
      'inProgress': 'В работе',
      'done': 'Готово',
      'cancelled': 'Отменено',
    };
    const priorityNames = {
      'low': 'Низкий',
      'medium': 'Средний',
      'high': 'Высокий',
      'critical': 'Критический',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(task.description),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(priorityNames[task.priority] ?? task.priority)),
                Chip(label: Text(statusNames[task.status] ?? task.status)),
                if (task.deadline != null)
                  Chip(
                    avatar: const Icon(Icons.event, size: 16),
                    label: Text(
                      DateTime.fromMillisecondsSinceEpoch(task.deadline!)
                          .toLocal()
                          .toString()
                          .substring(0, 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
