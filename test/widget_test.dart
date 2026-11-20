import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskflow/data/task_repository.dart';
import 'package:taskflow/database/app_database.dart';
import 'package:taskflow/presentation/taskflow_app.dart';

void main() {
  testWidgets('TaskFlow opens with its five main navigation sections', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      Provider<TaskRepository>(
        create: (_) => TaskRepository(db),
        child: const TaskFlowApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Задачи'), findsWidgets);
    expect(find.text('Проекты'), findsOneWidget);
    expect(find.text('Люди'), findsOneWidget);
    expect(find.text('Обзор'), findsOneWidget);
    expect(find.text('Корзина'), findsOneWidget);

    // Dispose StreamBuilders and allow Drift to finish scheduled stream cleanup.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
