import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/data/task_repository.dart' as legacy;
import 'package:taskflow/database/app_database.dart';
import 'package:taskflow/src/data/datasources/task_local_data_source.dart';
import 'package:taskflow/src/data/repositories/task_repository_impl.dart';
import 'package:taskflow/src/domain/entities/task_entity.dart';
import 'package:taskflow/src/domain/usecases/create_task_usecase.dart';
import 'package:taskflow/src/domain/usecases/watch_tasks_usecase.dart';

void main() {
  late AppDatabase database;
  late legacy.TaskRepository legacyRepository;
  late TaskRepositoryImpl repository;
  late int projectId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    legacyRepository = legacy.TaskRepository(database);
    final ownerId = await legacyRepository.addUser(
      'Project Owner',
      'owner@example.com',
    );
    projectId = await legacyRepository.addProject(
      'Clean Architecture',
      'Repository implementation test',
      ownerId,
    );
    repository = TaskRepositoryImpl(TaskLocalDataSourceImpl(database));
  });

  tearDown(() => database.close());

  test('UseCase creates a task and repository returns a domain entity', () async {
    final createTask = CreateTaskUseCase(repository);
    final watchTasks = WatchTasksUseCase(repository);

    final id = await createTask(
      title: 'Verify layers',
      description: 'Check Model to Entity mapping',
      projectId: projectId,
    );

    final tasks = await watchTasks().first;

    expect(tasks, hasLength(1));
    expect(tasks.single, isA<TaskEntity>());
    expect(tasks.single.id, id);
    expect(tasks.single.title, 'Verify layers');
    expect(tasks.single.description, 'Check Model to Entity mapping');
  });

  test('soft-deleted tasks are available only in the trash stream', () async {
    final id = await repository.createTask(
      title: 'Move to trash',
      description: '',
      projectId: projectId,
    );

    await repository.softDeleteTask(id);

    expect(await repository.watchTasks().first, isEmpty);
    final trash = await repository.watchTasks(trash: true).first;
    expect(trash, hasLength(1));
    expect(trash.single.id, id);
  });

  test('task filters are applied by the data source', () async {
    await repository.createTask(
      title: 'Urgent report',
      description: '',
      projectId: projectId,
      priority: 'critical',
    );
    await repository.createTask(
      title: 'Regular report',
      description: '',
      projectId: projectId,
      priority: 'low',
    );

    final filtered = await repository.watchTasks(
      priority: 'critical',
      query: 'Urgent',
    ).first;

    expect(filtered, hasLength(1));
    expect(filtered.single.title, 'Urgent report');
  });
}
