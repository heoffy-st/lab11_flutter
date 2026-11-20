import 'package:flutter/material.dart';
import 'screens.dart';

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TaskFlow',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5267D8)), useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF6F7FB)),
    home: const TaskFlowHome(),
  );
}

class TaskFlowHome extends StatefulWidget {
  const TaskFlowHome({super.key});
  @override
  State<TaskFlowHome> createState() => _TaskFlowHomeState();
}
class _TaskFlowHomeState extends State<TaskFlowHome> {
  int index = 0;
  final pages = const [TasksScreen(), ProjectsScreen(), UsersScreen(), DashboardScreen(), TrashScreen()];
  final titles = const ['Задачи', 'Проекты', 'Участники', 'Статистика', 'Корзина'];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(titles[index]), centerTitle: false),
    body: pages[index],
    bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [
      NavigationDestination(icon: Icon(Icons.check_circle_outline), label: 'Задачи'),
      NavigationDestination(icon: Icon(Icons.folder_outlined), label: 'Проекты'),
      NavigationDestination(icon: Icon(Icons.people_outline), label: 'Люди'),
      NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Обзор'),
      NavigationDestination(icon: Icon(Icons.delete_outline), label: 'Корзина'),
    ]),
  );
}

Future<String?> askText(BuildContext context, String title, {String initial = '', int maxLines = 1}) async {
  final c = TextEditingController(text: initial);
  return showDialog<String>(context: context, builder: (ctx) => AlertDialog(
    title: Text(title), content: TextField(controller: c, autofocus: true, maxLines: maxLines, decoration: const InputDecoration(border: OutlineInputBorder())),
    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Сохранить'))],
  ));
}
void showError(BuildContext context, Object e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
