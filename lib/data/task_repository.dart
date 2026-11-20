import 'package:drift/drift.dart';
import '../database/app_database.dart';

class TaskRepository {
  final AppDatabase db;
  TaskRepository(this.db);
  int _now() => DateTime.now().millisecondsSinceEpoch;

  Stream<List<Project>> watchProjects() => db.select(db.projects).watch();
  Stream<List<User>> watchUsers() => db.select(db.users).watch();

  Stream<List<Task>> watchTasks({int? projectId, String? status, String? priority, int? assigneeId, String query = '', bool trash = false, bool sortByDeadline = false, int limit = 30, int offset = 0}) {
    final q = db.select(db.tasks)
      ..limit(limit, offset: offset)
      ..orderBy([ (t) => sortByDeadline ? OrderingTerm.asc(t.deadline) : OrderingTerm.desc(t.createdAt) ]);
    q.where((t) {
      Expression<bool> filter = trash ? t.deletedAt.isNotNull() : t.deletedAt.isNull();
      if (projectId != null) filter = filter & t.projectId.equals(projectId);
      if (status != null) filter = filter & t.status.equals(status);
      if (priority != null) filter = filter & t.priority.equals(priority);
      if (assigneeId != null) filter = filter & t.assigneeId.equals(assigneeId);
      if (query.trim().isNotEmpty) {
        final pattern = '%${query.trim()}%';
        filter = filter & (t.title.like(pattern) | t.description.like(pattern));
      }
      return filter;
    });
    return q.watch();
  }

  Future<int> addUser(String name, String email) {
    if (name.trim().isEmpty || !email.contains('@')) throw ArgumentError('Укажите имя и корректный email');
    return db.into(db.users).insert(UsersCompanion.insert(name: name.trim(), email: email.trim().toLowerCase(), registeredAt: _now()));
  }
  Future<void> updateUser(int id, String name, String email) async {
    if (name.trim().isEmpty || !email.contains('@')) throw ArgumentError('Укажите имя и корректный email');
    await (db.update(db.users)..where((t) => t.id.equals(id))).write(UsersCompanion(name: Value(name.trim()), email: Value(email.trim().toLowerCase())));
  }
  Future<void> deleteUser(int id) async {
    final active = await (db.select(db.tasks)..where((t) => t.assigneeId.equals(id) & t.status.isNotIn(['done','cancelled']) & t.deletedAt.isNull())).get();
    if (active.isNotEmpty) throw StateError('Нельзя удалить пользователя: у него есть незавершённые задачи');
    await (db.delete(db.users)..where((t) => t.id.equals(id))).go();
  }

  Future<int> addProject(String name, String description, int ownerId, {int? dueAt}) async {
    if (name.trim().isEmpty) throw ArgumentError('Название проекта обязательно');
    return db.transaction(() async {
      final id = await db.into(db.projects).insert(ProjectsCompanion.insert(name: name.trim(), description: Value(description.trim()), createdAt: _now(), dueAt: Value(dueAt)));
      await db.into(db.projectMembers).insert(ProjectMembersCompanion.insert(projectId: id, userId: ownerId, role: const Value('Owner')));
      return id;
    });
  }
  Future<void> updateProject(int id, String name, String description, String status, {int? dueAt}) async {
    if (name.trim().isEmpty) throw ArgumentError('Название проекта обязательно');
    if (!['active','completed','archived'].contains(status)) throw ArgumentError('Некорректный статус проекта');
    await (db.update(db.projects)..where((t) => t.id.equals(id))).write(ProjectsCompanion(name: Value(name.trim()), description: Value(description.trim()), status: Value(status), dueAt: Value(dueAt)));
  }
  Future<void> deleteProject(int id) => (db.delete(db.projects)..where((t) => t.id.equals(id))).go();
  Future<void> addMember(int projectId, int userId, String role) async {
    if (!['Owner','Admin','Member'].contains(role)) throw ArgumentError('Некорректная роль участника');
    final project = await (db.select(db.projects)..where((t) => t.id.equals(projectId))).getSingleOrNull();
    final user = await (db.select(db.users)..where((t) => t.id.equals(userId))).getSingleOrNull();
    if (project == null || user == null) throw StateError('Проект или пользователь не существует');
    await db.into(db.projectMembers).insert(ProjectMembersCompanion.insert(projectId: projectId, userId: userId, role: Value(role)));
  }
  Future<void> removeMember(int projectId, int userId) async {
    final assigned = await (db.select(db.tasks)..where((t) => t.projectId.equals(projectId) & t.assigneeId.equals(userId) & t.status.isNotIn(['done','cancelled']) & t.deletedAt.isNull())).get();
    if (assigned.isNotEmpty) throw StateError('Сначала переназначьте незавершённые задачи');
    await (db.delete(db.projectMembers)..where((t) => t.projectId.equals(projectId) & t.userId.equals(userId))).go();
  }
  Future<bool> isMember(int projectId, int userId) async =>
      await (db.select(db.projectMembers)..where((m) => m.projectId.equals(projectId) & m.userId.equals(userId))).getSingleOrNull() != null;

  Future<int> createTask({required String title, required String description, required int projectId, int? assigneeId, String priority = 'medium', String status = 'todo', int? deadline, int? changedBy}) async {
    if (title.trim().isEmpty) throw ArgumentError('Название задачи обязательно');
    if (!['low','medium','high','critical'].contains(priority)) throw ArgumentError('Некорректный приоритет');
    if (!['todo','inProgress','done','cancelled'].contains(status)) throw ArgumentError('Некорректный статус задачи');
    final project = await (db.select(db.projects)..where((p) => p.id.equals(projectId))).getSingleOrNull();
    if (project == null) throw StateError('Проект не существует');
    if (assigneeId != null && !await isMember(projectId, assigneeId)) throw StateError('Исполнитель не состоит в проекте');
    if (assigneeId != null && deadline != null) {
      final count = await (db.select(db.tasks)..where((t) => t.assigneeId.equals(assigneeId) & t.deadline.equals(deadline) & t.status.isNotIn(['done','cancelled']) & t.deletedAt.isNull())).get();
      if (count.length >= 3) throw StateError('У исполнителя уже есть 3 незавершённые задачи с этим дедлайном');
    }
    return db.transaction(() async {
      final now = _now();
      final id = await db.into(db.tasks).insert(TasksCompanion.insert(title: title.trim(), description: Value(description.trim()), projectId: projectId, assigneeId: Value(assigneeId), priority: Value(priority), status: Value(status), deadline: Value(deadline), createdAt: now, updatedAt: now));
      await db.into(db.taskHistory).insert(TaskHistoryCompanion.insert(taskId: id, previousStatus: const Value.absent(), newStatus: status, changedBy: Value(changedBy), changedAt: now, details: const Value('Задача создана')));
      return id;
    });
  }
  Future<void> updateTask(int id, {required String title, required String description, required String priority, int? deadline}) async {
    if (title.trim().isEmpty) throw ArgumentError('Название задачи обязательно');
    if (!['low','medium','high','critical'].contains(priority)) throw ArgumentError('Некорректный приоритет');
    await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(title: Value(title.trim()), description: Value(description.trim()), priority: Value(priority), deadline: Value(deadline), updatedAt: Value(_now())));
  }
  Future<void> changeStatus(int taskId, String next, {int? changedBy}) async {
    await db.transaction(() async {
      if (!['todo','inProgress','done','cancelled'].contains(next)) throw ArgumentError('Некорректный статус задачи');
      final task = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      if (task.status == next) return;
      final now = _now();
      await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(TasksCompanion(status: Value(next), updatedAt: Value(now)));
      await db.into(db.taskHistory).insert(TaskHistoryCompanion.insert(taskId: taskId, previousStatus: Value(task.status), newStatus: next, changedBy: Value(changedBy), changedAt: now));
    });
  }
  Future<void> reassignTask(int taskId, int? userId, {int? changedBy}) async {
    await db.transaction(() async {
      final task = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      if (userId != null && !await isMember(task.projectId, userId)) throw StateError('Исполнитель не состоит в проекте');
      if (userId != null && task.deadline != null) {
        final assigned = await (db.select(db.tasks)..where((t) => t.id.isNotIn([taskId]) & t.assigneeId.equals(userId) & t.deadline.equals(task.deadline!) & t.status.isNotIn(['done','cancelled']) & t.deletedAt.isNull())).get();
        if (assigned.length >= 3) throw StateError('У исполнителя уже есть 3 незавершённые задачи с этим дедлайном');
      }
      final now = _now();
      await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(TasksCompanion(assigneeId: Value(userId), updatedAt: Value(now)));
      await db.into(db.taskHistory).insert(TaskHistoryCompanion.insert(taskId: taskId, previousStatus: Value(task.status), newStatus: task.status, changedBy: Value(changedBy), changedAt: now, details: Value('Исполнитель изменён: ${userId ?? "не назначен"}')));
    });
  }
  Future<void> undoStatus(int taskId, {int? changedBy}) async {
    await db.transaction(() async {
      final history = await (db.select(db.taskHistory)..where((h) => h.taskId.equals(taskId) & h.previousStatus.isNotNull() & h.details.equals(''))..orderBy([(h) => OrderingTerm.desc(h.changedAt)])..limit(1)).getSingleOrNull();
      if (history == null || history.previousStatus == null) throw StateError('Нет изменений для отмены');
      final current = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      final now = _now();
      await (db.update(db.taskHistory)..where((h) => h.id.equals(history.id))).write(const TaskHistoryCompanion(details: Value('undone')));
      await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(TasksCompanion(status: Value(history.previousStatus!), updatedAt: Value(now)));
      await db.into(db.taskHistory).insert(TaskHistoryCompanion.insert(taskId: taskId, previousStatus: Value(current.status), newStatus: history.previousStatus!, changedBy: Value(changedBy), changedAt: now, details: const Value('Отмена последнего изменения')));
    });
  }
  Future<void> softDeleteTask(int id) async { final now=_now(); await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(deletedAt: Value(now), updatedAt: Value(now))); }
  Future<void> restoreTask(int id) async { final now=_now(); await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(deletedAt: const Value(null), updatedAt: Value(now))); }
  Future<void> permanentlyDeleteTask(int id) async => (db.delete(db.tasks)..where((t) => t.id.equals(id))).go();

  Stream<List<Comment>> watchComments(int taskId) => (db.select(db.comments)..where((c) => c.taskId.equals(taskId))..orderBy([(c) => OrderingTerm.asc(c.createdAt)])).watch();
  Future<int> addComment(int taskId, int authorId, String body) async {
    final task = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingleOrNull();
    if (task == null) throw StateError('Задача не существует');
    if (body.trim().isEmpty) throw ArgumentError('Комментарий не может быть пустым');
    return db.into(db.comments).insert(CommentsCompanion.insert(taskId: taskId, authorId: authorId, body: body.trim(), createdAt: _now()));
  }
  Future<void> deleteComment(int commentId, int authorId) async {
    final c = await (db.select(db.comments)..where((t) => t.id.equals(commentId))).getSingle();
    if (c.authorId != authorId) throw StateError('Удалить комментарий может только автор');
    await (db.delete(db.comments)..where((t) => t.id.equals(commentId))).go();
  }
  Stream<List<Attachment>> watchAttachments(int taskId) => (db.select(db.attachments)..where((a) => a.taskId.equals(taskId))).watch();
  Future<int> addAttachment(int taskId, String name, String path) => db.into(db.attachments).insert(AttachmentsCompanion.insert(taskId: taskId, fileName: name, localPath: path, addedAt: _now()));
  Future<void> deleteAttachment(int id) => (db.delete(db.attachments)..where((a) => a.id.equals(id))).go();
  Stream<List<TaskHistoryData>> watchHistory(int taskId) => (db.select(db.taskHistory)..where((h) => h.taskId.equals(taskId))..orderBy([(h) => OrderingTerm.desc(h.changedAt)])).watch();

  Future<List<Map<String, Object?>>> projectMembers(int projectId) async =>
      (await db.customSelect('SELECT u.id, u.name, u.email, pm.role FROM project_members pm JOIN users u ON u.id = pm.user_id WHERE pm.project_id = ?', variables: [Variable.withInt(projectId)]).get()).map((r) => r.data).toList();

  Future<void> seedPerformanceData() async {
    if ((await db.select(db.users).get()).isNotEmpty) throw StateError('Для тестового наполнения нужна пустая база');
    await db.batch((b) => b.insertAll(db.users, List.generate(1000, (i) => UsersCompanion.insert(name: 'User $i', email: 'user$i@taskflow.local', registeredAt: _now()))));
    final userRows = await db.select(db.users).get();
    await db.batch((b) => b.insertAll(db.projects, List.generate(100, (i) => ProjectsCompanion.insert(name: 'Project $i', description: Value('Performance project'), createdAt: _now()))));
    final projectRows = await db.select(db.projects).get();
    await db.batch((b) => b.insertAll(db.projectMembers, List.generate(100, (i) => ProjectMembersCompanion.insert(projectId: projectRows[i].id, userId: userRows[i].id, role: const Value('Owner')))));
    final now = _now();
    await db.batch((b) => b.insertAll(db.tasks, List.generate(10000, (i) => TasksCompanion.insert(title: 'Performance task $i', description: Value('Generated task for search benchmark'), projectId: projectRows[i % 100].id, assigneeId: Value(userRows[i % 1000].id), priority: Value(['low','medium','high','critical'][i % 4]), status: Value(['todo','inProgress','done'][i % 3]), deadline: Value(now + (i % 30) * 86400000), createdAt: now, updatedAt: now))));
  }

  Stream<List<Map<String, Object?>>> watchDashboard() => db.customSelect('''
    SELECT (SELECT COUNT(*) FROM projects) AS project_count,
      (SELECT COUNT(*) FROM tasks WHERE deleted_at IS NULL) AS task_count,
      (SELECT COUNT(*) FROM tasks WHERE status = 'done' AND deleted_at IS NULL) AS done_count,
      (SELECT COUNT(*) FROM tasks WHERE status NOT IN ('done','cancelled') AND deleted_at IS NULL) AS open_count,
      (SELECT COUNT(*) FROM tasks WHERE deadline < ? AND status NOT IN ('done','cancelled') AND deleted_at IS NULL) AS overdue_count
  ''', variables: [Variable.withInt(_now())], readsFrom: {db.projects, db.tasks})
      .watch().map((rows) => rows.map((r) => r.data).toList());

  Stream<List<Map<String, Object?>>> watchStatsByPriority() => db.customSelect("SELECT priority, COUNT(*) AS amount FROM tasks WHERE deleted_at IS NULL GROUP BY priority", readsFrom: {db.tasks}).watch().map((rows) => rows.map((r) => r.data).toList());
  Stream<List<Map<String, Object?>>> watchStatsByAssignee() => db.customSelect("SELECT u.name, COUNT(t.id) AS amount FROM users u LEFT JOIN tasks t ON t.assignee_id = u.id AND t.deleted_at IS NULL GROUP BY u.id ORDER BY amount DESC", readsFrom: {db.users, db.tasks}).watch().map((rows) => rows.map((r) => r.data).toList());
  Stream<List<Map<String, Object?>>> watchProjectProgress() => db.customSelect("SELECT p.id, p.name, COUNT(t.id) AS total, SUM(CASE WHEN t.status = 'done' THEN 1 ELSE 0 END) AS done FROM projects p LEFT JOIN tasks t ON t.project_id = p.id AND t.deleted_at IS NULL GROUP BY p.id", readsFrom: {db.projects, db.tasks}).watch().map((rows) => rows.map((r) => r.data).toList());

  Future<Map<String, int>> compareIndexPerformance({int repetitions = 20}) async {
    final projects = await db.select(db.projects).get();
    if (projects.isEmpty) throw StateError('Сначала добавьте проект и задачи');
    final projectId = projects.first.id;
    final indexed = Stopwatch()..start();
    for (var i = 0; i < repetitions; i++) {
      await db.customSelect('SELECT COUNT(*) AS amount FROM tasks INDEXED BY tasks_project_idx WHERE project_id = ?', variables: [Variable.withInt(projectId)]).get();
    }
    indexed.stop();
    final scan = Stopwatch()..start();
    for (var i = 0; i < repetitions; i++) {
      await db.customSelect('SELECT COUNT(*) AS amount FROM tasks NOT INDEXED WHERE project_id = ?', variables: [Variable.withInt(projectId)]).get();
    }
    scan.stop();
    return {'withIndexMicros': indexed.elapsedMicroseconds, 'withoutIndexMicros': scan.elapsedMicroseconds};
  }

  Future<List<Map<String, Object?>>> statsByPriority() async => (await db.customSelect("SELECT priority, COUNT(*) AS amount FROM tasks WHERE deleted_at IS NULL GROUP BY priority").get()).map((r) => r.data).toList();
  Future<List<Map<String, Object?>>> statsByAssignee() async => (await db.customSelect("SELECT u.name, COUNT(t.id) AS amount FROM users u LEFT JOIN tasks t ON t.assignee_id = u.id AND t.deleted_at IS NULL GROUP BY u.id ORDER BY amount DESC").get()).map((r) => r.data).toList();
  Future<List<Map<String, Object?>>> projectProgress() async => (await db.customSelect("SELECT p.id, p.name, COUNT(t.id) AS total, SUM(CASE WHEN t.status = 'done' THEN 1 ELSE 0 END) AS done FROM projects p LEFT JOIN tasks t ON t.project_id = p.id AND t.deleted_at IS NULL GROUP BY p.id").get()).map((r) => r.data).toList();
  Future<List<Map<String, Object?>>> dashboard() => db.dashboardSummary();
}
