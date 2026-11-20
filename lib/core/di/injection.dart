import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../database/app_database.dart';
import '../../data/task_repository.dart';
import '../../src/data/datasources/task_local_data_source.dart';
import '../../src/data/repositories/task_repository_impl.dart';
import '../../src/domain/repositories/task_repository.dart' as domain;
import '../../src/domain/usecases/watch_tasks_usecase.dart';
import '../../src/domain/usecases/create_task_usecase.dart';
import '../../src/domain/usecases/update_task_usecase.dart';
import '../../src/domain/usecases/change_task_status_usecase.dart';
import '../../src/domain/usecases/delete_task_usecase.dart';
import '../../src/presentation/providers/task_list_controller.dart';

List<SingleChildWidget> createAppProviders(AppDatabase database) {
  final localDataSource = TaskLocalDataSourceImpl(database);
  final taskRepository = TaskRepositoryImpl(localDataSource);
  final watchTasks = WatchTasksUseCase(taskRepository);
  final createTask = CreateTaskUseCase(taskRepository);
  final updateTask = UpdateTaskUseCase(taskRepository);
  final changeStatus = ChangeTaskStatusUseCase(taskRepository);
  final deleteTask = DeleteTaskUseCase(taskRepository);

  return [
    Provider<AppDatabase>(create: (_) => database, dispose: (_, db) => db.close()),
    Provider<domain.TaskRepository>.value(value: taskRepository),
    Provider<WatchTasksUseCase>.value(value: watchTasks),
    Provider<CreateTaskUseCase>.value(value: createTask),
    Provider<UpdateTaskUseCase>.value(value: updateTask),
    Provider<ChangeTaskStatusUseCase>.value(value: changeStatus),
    Provider<DeleteTaskUseCase>.value(value: deleteTask),
    ChangeNotifierProvider<TaskListController>(
      create: (_) => TaskListController(
        watchTasksUseCase: watchTasks,
        createTaskUseCase: createTask,
        updateTaskUseCase: updateTask,
        changeTaskStatusUseCase: changeStatus,
        deleteTaskUseCase: deleteTask,
      )..start(),
    ),
    Provider<TaskRepository>(create: (_) => TaskRepository(database)),
  ];
}