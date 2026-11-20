import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get email => text().unique()();
  IntColumn get registeredAt => integer()();
}

class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()();
  IntColumn get dueAt => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
}

@TableIndex(name: 'project_members_user_idx', columns: {#userId})
class ProjectMembers extends Table {
  IntColumn get projectId => integer().references(Projects, #id, onDelete: KeyAction.cascade)();
  IntColumn get userId => integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => text().withDefault(const Constant('Member'))();
  @override
  Set<Column> get primaryKey => {projectId, userId};
}

@TableIndex(name: 'tasks_project_idx', columns: {#projectId})
@TableIndex(name: 'tasks_assignee_idx', columns: {#assigneeId})
@TableIndex(name: 'tasks_deadline_idx', columns: {#deadline})
@TableIndex(name: 'tasks_status_priority_idx', columns: {#status, #priority})
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 160)();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get projectId => integer().references(Projects, #id, onDelete: KeyAction.cascade)();
  IntColumn get assigneeId => integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get status => text().withDefault(const Constant('todo'))();
  IntColumn get deadline => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
}

class Comments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  IntColumn get authorId => integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get body => text().withLength(min: 1, max: 4000)();
  IntColumn get createdAt => integer()();
}

class Attachments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileName => text()();
  TextColumn get localPath => text()();
  IntColumn get addedAt => integer()();
}

class TaskHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get previousStatus => text().nullable()();
  TextColumn get newStatus => text()();
  IntColumn get changedBy => integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
  IntColumn get changedAt => integer()();
  TextColumn get details => text().withDefault(const Constant(''))();
}

@DriftDatabase(tables: [Users, Projects, ProjectMembers, Tasks, Comments, Attachments, TaskHistory])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'taskflow'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(tasks, tasks.priority);
        await customStatement("UPDATE tasks SET priority = 'medium'");
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<List<Map<String, Object?>>> dashboardSummary() async {
    final rows = await customSelect('''
      SELECT
        (SELECT COUNT(*) FROM projects) AS project_count,
        (SELECT COUNT(*) FROM tasks WHERE deleted_at IS NULL) AS task_count,
        (SELECT COUNT(*) FROM tasks WHERE status = 'done' AND deleted_at IS NULL) AS done_count,
        (SELECT COUNT(*) FROM tasks WHERE status NOT IN ('done','cancelled') AND deleted_at IS NULL) AS open_count,
        (SELECT COUNT(*) FROM tasks WHERE deadline < ? AND status NOT IN ('done','cancelled') AND deleted_at IS NULL) AS overdue_count
    ''', variables: [Variable.withInt(DateTime.now().millisecondsSinceEpoch)]).get();
    return rows.map((r) => r.data).toList();
  }
}
