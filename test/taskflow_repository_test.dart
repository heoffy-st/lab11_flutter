import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/database/app_database.dart';
import 'package:taskflow/data/task_repository.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repo;
  late int userId;
  late int projectId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TaskRepository(db);
    userId = await repo.addUser('Test User', 'test@example.com');
    projectId = await repo.addProject('Test Project', 'Description', userId);
  });
  tearDown(() async => db.close());

  test('creates a user', () async {
    final id = await repo.addUser('Second User', 'second@example.com');
    expect(id, greaterThan(0));
  });
  test('rejects duplicate email', () async {
    expect(() => repo.addUser('Other', 'test@example.com'), throwsA(anything));
  });
  test('rejects invalid email', () async {
    expect(() => repo.addUser('Other', 'invalid'), throwsArgumentError);
  });
  test('deletes user without active tasks', () async {
    final id = await repo.addUser('Delete Me', 'delete@example.com');
    await repo.deleteUser(id);
    expect(await (db.select(db.users)..where((u) => u.id.equals(id))).get(), isEmpty);
  });
  test('creates a project and its owner membership', () async {
    expect(await repo.isMember(projectId, userId), isTrue);
  });
  test('prevents duplicate project membership', () async {
    expect(() => repo.addMember(projectId, userId, 'Member'), throwsA(anything));
  });
  test('adds a member to a project', () async {
    final id = await repo.addUser('Member', 'member@example.com');
    await repo.addMember(projectId, id, 'Admin');
    expect(await repo.isMember(projectId, id), isTrue);
  });
  test('creates task and initial history in one transaction', () async {
    final id = await repo.createTask(title: 'First task', description: '', projectId: projectId, changedBy: userId);
    final history = await (db.select(db.taskHistory)..where((h) => h.taskId.equals(id))).get();
    expect(history, hasLength(1));
    expect(history.single.newStatus, 'todo');
  });
  test('rejects task without a valid project', () async {
    expect(() => repo.createTask(title: 'No project', description: '', projectId: 99999), throwsA(anything));
  });
  test('rejects assignee outside project', () async {
    final outsider = await repo.addUser('Outsider', 'out@example.com');
    expect(() => repo.createTask(title: 'Invalid assignee', description: '', projectId: projectId, assigneeId: outsider), throwsA(anything));
  });
  test('changes task status and records history', () async {
    final id = await repo.createTask(title: 'Status task', description: '', projectId: projectId);
    await repo.changeStatus(id, 'inProgress', changedBy: userId);
    final task = await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingle();
    final history = await (db.select(db.taskHistory)..where((h) => h.taskId.equals(id))).get();
    expect(task.status, 'inProgress');
    expect(history, hasLength(2));
  });
  test('undo restores previous status', () async {
    final id = await repo.createTask(title: 'Undo task', description: '', projectId: projectId);
    await repo.changeStatus(id, 'done');
    await repo.undoStatus(id);
    final task = await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(task.status, 'todo');
  });
  test('soft delete keeps task in database', () async {
    final id = await repo.createTask(title: 'Trash me', description: '', projectId: projectId);
    await repo.softDeleteTask(id);
    final task = await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(task.deletedAt, isNotNull);
  });
  test('restores soft deleted task', () async {
    final id = await repo.createTask(title: 'Restore me', description: '', projectId: projectId);
    await repo.softDeleteTask(id);
    await repo.restoreTask(id);
    final task = await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(task.deletedAt, isNull);
  });
  test('adds and deletes comment by its author', () async {
    final id = await repo.createTask(title: 'Comment task', description: '', projectId: projectId);
    final commentId = await repo.addComment(id, userId, 'Hello');
    await repo.deleteComment(commentId, userId);
    expect(await (db.select(db.comments)..where((c) => c.id.equals(commentId))).get(), isEmpty);
  });
  test('prevents deleting another user comment', () async {
    final id = await repo.createTask(title: 'Protected comment', description: '', projectId: projectId);
    final commentId = await repo.addComment(id, userId, 'Hello');
    final other = await repo.addUser('Other', 'other@example.com');
    expect(() => repo.deleteComment(commentId, other), throwsA(anything));
  });
  test('prevents deleting user with unfinished assigned tasks', () async {
    await repo.createTask(title: 'Assigned', description: '', projectId: projectId, assigneeId: userId);
    expect(() => repo.deleteUser(userId), throwsA(anything));
  });
  test('reassigns task only to project member', () async {
    final id = await repo.createTask(title: 'Reassign', description: '', projectId: projectId);
    final member = await repo.addUser('New member', 'new@example.com');
    await repo.addMember(projectId, member, 'Member');
    await repo.reassignTask(id, member);
    final task = await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(task.assigneeId, member);
  });
  test('rejects fourth unfinished task with same deadline', () async {
    final deadline = DateTime(2030, 1, 1).millisecondsSinceEpoch;
    for (var i = 0; i < 3; i++) {
      await repo.createTask(title: 'Limit $i', description: '', projectId: projectId, assigneeId: userId, deadline: deadline);
    }
    expect(() => repo.createTask(title: 'Limit exceeded', description: '', projectId: projectId, assigneeId: userId, deadline: deadline), throwsA(anything));
  });
  test('stores attachment path only', () async {
    final id = await repo.createTask(title: 'File task', description: '', projectId: projectId);
    await repo.addAttachment(id, 'notes.txt', '/local/notes.txt');
    final files = await (db.select(db.attachments)..where((a) => a.taskId.equals(id))).get();
    expect(files.single.localPath, '/local/notes.txt');
  });
  test('dashboard SQL counts projects and tasks', () async {
    await repo.createTask(title: 'Dashboard task', description: '', projectId: projectId);
    final summary = await repo.dashboard();
    expect(summary.single['project_count'], 1);
    expect(summary.single['task_count'], 1);
  });

  test('migration v1 to v2 adds priority with medium default and preserves task', () async {
    final legacy = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('''CREATE TABLE tasks (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        project_id INTEGER NOT NULL,
        assignee_id INTEGER,
        status TEXT NOT NULL DEFAULT 'todo',
        deadline INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      )''');
      raw.execute("INSERT INTO tasks (id,title,description,project_id,status,created_at,updated_at) VALUES (1,'Legacy task','','1','todo',1,1)");
      raw.execute('PRAGMA user_version = 1');
    }));
    final rows = await legacy.customSelect('SELECT id, title, priority FROM tasks').get();
    expect(rows.single.data['id'], 1);
    expect(rows.single.data['title'], 'Legacy task');
    expect(rows.single.data['priority'], 'medium');
    await legacy.close();
  });
  test('schema version is configured for the priority migration', () {
    expect(db.schemaVersion, 2);
  });
  test('soft-deleted tasks are excluded from the normal stream', () async {
    final id = await repo.createTask(title: 'Hidden task', description: '', projectId: projectId);
    await repo.softDeleteTask(id);
    expect(await repo.watchTasks().first, isEmpty);
    expect((await repo.watchTasks(trash: true).first).single.id, id);
  });
  test('filters task list by title search', () async {
    await repo.createTask(title: 'Alpha report', description: '', projectId: projectId);
    await repo.createTask(title: 'Beta report', description: '', projectId: projectId);
    final rows = await repo.watchTasks(query: 'Alpha').first;
    expect(rows.map((t) => t.title), contains('Alpha report'));
    expect(rows.map((t) => t.title), isNot(contains('Beta report')));
  });
}
