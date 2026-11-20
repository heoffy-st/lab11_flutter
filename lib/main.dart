import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/app_database.dart';
import 'data/task_repository.dart';
import 'presentation/taskflow_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  runApp(Provider<TaskRepository>(
    create: (_) => TaskRepository(db),
    dispose: (_, _) => db.close(),
    child: const TaskFlowApp(),
  ));
}
