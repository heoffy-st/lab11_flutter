import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../database/app_database.dart';
import '../../data/task_repository.dart';
import '../../src/data/datasources/task_local_data_source.dart';
import '../../src/data/repositories/task_repository_impl.dart';
import '../../src/domain/repositories/task_repository.dart' as domain;
import '../../src/domain/usecases/watch_tasks_usecase.dart';
import '../../src/presentation/providers/task_list_controller.dart';

List<SingleChildWidget> createAppProviders(AppDatabase database) {
  final localDataSource = TaskLocalDataSourceImpl(database);
  final taskRepository = TaskRepositoryImpl(localDataSource);
  final watchTasksUseCase = WatchTasksUseCase(taskRepository);

  return [
    Provider<AppDatabase>.value(value: database),
    Provider<domain.TaskRepository>.value(value: taskRepository),
    Provider<WatchTasksUseCase>.value(value: watchTasksUseCase),
    ChangeNotifierProvider<TaskListController>(
      create: (_) => TaskListController(watchTasksUseCase)..start(),
    ),
    Provider<TaskRepository>(
      create: (_) => TaskRepository(database),
    ),
  ];
}
