// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/injection.dart';
import 'database/app_database.dart';
import 'presentation/taskflow_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();

  runApp(
    MultiProvider(
      providers: createAppProviders(database),
      child: const TaskFlowApp(),
    ),
  );
}
