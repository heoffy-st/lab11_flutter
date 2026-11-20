import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/task_repository.dart';
import '../database/app_database.dart';
import 'taskflow_app.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TaskListController>();
    final repo = context.read<TaskRepository>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Поиск задач...',
              border: OutlineInputBorder(),
            ),
            onChanged: controller.updateSearch,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: controller.selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Статус',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Все')),
                    DropdownMenuItem(value: 'todo', child: Text('Ожидает')),
                    DropdownMenuItem(value: 'inProgress', child: Text('В работе')),
                    DropdownMenuItem(value: 'done', child: Text('Готово')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Отменено')),
                  ],
                  onChanged: controller.updateStatus,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: controller.selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Приоритет',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Все')),
                    DropdownMenuItem(value: 'low', child: Text('Низкий')),
                    DropdownMenuItem(value: 'medium', child: Text('Средний')),
                    DropdownMenuItem(value: 'high', child: Text('Высокий')),
                    DropdownMenuItem(value: 'critical', child: Text('Критический')),
                  ],
                  onChanged: controller.updatePriority,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: StreamBuilder<List<User>>(
                  stream: repo.watchUsers(),
                  builder: (ctx, users) => DropdownButtonFormField<int?>(
                    initialValue: controller.selectedAssignee,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Исполнитель',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Все исполнители'),
                      ),
                      ...(users.data ?? []).map(
                        (u) => DropdownMenuItem<int?>(
                          value: u.id,
                          child: Text(u.name),
                        ),
                      ),
                    ],
                    onChanged: controller.updateAssignee,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: controller.sortByDeadline
                    ? 'Сначала дедлайн'
                    : 'Сначала новые',
                onPressed: controller.toggleSort,
                icon: Icon(
                  controller.sortByDeadline ? Icons.event : Icons.schedule,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildTaskList(controller),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FloatingActionButton.extended(
              onPressed: () => createTaskDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Новая задача'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList(TaskListController controller) {
    switch (controller.status) {
      case TaskListStatus.initial:
      case TaskListStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case TaskListStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(controller.errorMessage ?? 'Произошла ошибка'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: controller.loadTasks,
                child: const Text('Повторить'),
              ),
            ],
          ),
        );
      case TaskListStatus.empty:
        return const Center(
          child: Text('Задач пока нет. Создайте первую задачу.'),
        );
      case TaskListStatus.success:
        final tasks = controller.tasks;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
          itemCount: tasks.length + (tasks.length == controller.limit ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == tasks.length) {
              return TextButton(
                onPressed: controller.loadMore,
                child: const Text('Загрузить ещё'),
              );
            }
            final item = tasks[index];
            return TaskCard(
              task: Task(
                id: item.id,
                title: item.title,
                description: item.description,
                projectId: item.projectId,
                assigneeId: item.assigneeId,
                priority: item.priority,
                status: item.status,
                deadline: item.deadline,
                createdAt: item.createdAt,
                updatedAt: item.updatedAt,
                deletedAt: item.deletedAt,
              ),
            );
          },
        );
    }
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  const TaskCard({super.key, required this.task});
  @override
  Widget build(BuildContext context) {
    final repo = context.read<TaskRepository>();
    final statusNames = {'todo':'Ожидает','inProgress':'В работе','done':'Готово','cancelled':'Отменено'};
    final priorityNames = {'low':'Низкий','medium':'Средний','high':'Высокий','critical':'Критический'};
    return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(task.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))), PopupMenuButton<String>(onSelected: (v) async { try { if (v == 'delete') { await repo.softDeleteTask(task.id); } else if (v == 'undo') { final users = await repo.watchUsers().first; await repo.undoStatus(task.id, changedBy: users.isEmpty ? null : users.first.id); } else if (v == 'comments') { if (context.mounted) showTaskDetails(context, task); } else if (v == 'edit') { if (context.mounted) editTaskDialog(context, task); } else if (v == 'assign') { if (context.mounted) reassignTaskDialog(context, task); } } catch (e) { if (context.mounted) showError(context, e); } }, itemBuilder: (_) => const [PopupMenuItem(value:'edit', child: Text('Редактировать')), PopupMenuItem(value:'assign', child: Text('Назначить исполнителя')), PopupMenuItem(value:'comments', child: Text('Комментарии и история')), PopupMenuItem(value:'undo', child: Text('Отменить статус')), PopupMenuItem(value:'delete', child: Text('В корзину'))])]),
      if (task.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 6, children: [
        Chip(label: Text(priorityNames[task.priority] ?? task.priority)),
        Chip(label: Text(statusNames[task.status] ?? task.status)),
        if (task.deadline != null) Chip(avatar: const Icon(Icons.event, size: 16), label: Text(DateTime.fromMillisecondsSinceEpoch(task.deadline!).toLocal().toString().substring(0, 10))),
      ]),
      Align(alignment: Alignment.centerRight, child: DropdownButton<String>(value: task.status, underline: const SizedBox(), hint: const Text('Статус'), items: statusNames.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: (v) async { if (v != null) { try { final users = await repo.watchUsers().first; await repo.changeStatus(task.id, v, changedBy: users.isEmpty ? null : users.first.id); } catch (e) { if (context.mounted) showError(context, e); } } })),
    ])));
  }
}

Future<void> createTaskDialog(BuildContext context) async {
  final repo = context.read<TaskRepository>();
  final projects = await repo.watchProjects().first;
  final users = await repo.watchUsers().first;
  if (!context.mounted) return;
  if (projects.isEmpty) { showError(context, 'Сначала создайте проект'); return; }
  final title = TextEditingController(); final desc = TextEditingController();
  int projectId = projects.first.id; int? userId; String priority = 'medium'; DateTime? deadline;
  await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, set) => AlertDialog(
    title: const Text('Новая задача'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: title, decoration: const InputDecoration(labelText: 'Название')),
      TextField(controller: desc, decoration: const InputDecoration(labelText: 'Описание'), maxLines: 3),
      OutlinedButton.icon(
        onPressed: () async { final selected = await chooseProject(ctx, projects, selectedId: projectId); if (selected != null) set(() => projectId = selected); },
        icon: const Icon(Icons.folder_open), label: Text('Проект: ${projects.firstWhere((p) => p.id == projectId).name}'),
      ),
      OutlinedButton.icon(
        onPressed: () async { final selected = await chooseUser(ctx, users, title: 'Выберите исполнителя', selectedId: userId); set(() => userId = selected); },
        icon: const Icon(Icons.person_search), label: Text(userId == null ? 'Исполнитель: не назначен' : 'Исполнитель: ${users.firstWhere((u) => u.id == userId).name}'),
      ),
      DropdownButtonFormField<String>(initialValue: priority, decoration: const InputDecoration(labelText: 'Приоритет'), items: const [DropdownMenuItem(value:'low',child:Text('Низкий')),DropdownMenuItem(value:'medium',child:Text('Средний')),DropdownMenuItem(value:'high',child:Text('Высокий')),DropdownMenuItem(value:'critical',child:Text('Критический'))], onChanged: (v) => set(() => priority = v ?? 'medium')),
      TextButton.icon(onPressed: () async { final d = await showDatePicker(context: ctx, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: DateTime.now()); if (d != null) set(() => deadline = d); }, icon: const Icon(Icons.calendar_month), label: Text(deadline == null ? 'Выбрать дедлайн' : deadline!.toString().substring(0,10))),
    ])),
    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')), FilledButton(onPressed: () async { try { await repo.createTask(title: title.text, description: desc.text, projectId: projectId, assigneeId: userId, priority: priority, deadline: deadline?.millisecondsSinceEpoch, changedBy: users.isEmpty ? null : users.first.id); if (ctx.mounted) Navigator.pop(ctx); } catch (e) { if (ctx.mounted) showError(ctx, e); } }, child: const Text('Создать'))],
  )));
}
Future<void> editTaskDialog(BuildContext context, Task task) async {
  final repo = context.read<TaskRepository>(); final title = TextEditingController(text: task.title); final desc = TextEditingController(text: task.description); String priority = task.priority; DateTime? deadline = task.deadline == null ? null : DateTime.fromMillisecondsSinceEpoch(task.deadline!);
  await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx,set) => AlertDialog(title: const Text('Редактировать задачу'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller:title,decoration:const InputDecoration(labelText:'Название')),TextField(controller:desc,decoration:const InputDecoration(labelText:'Описание'),maxLines:3),DropdownButtonFormField<String>(initialValue:priority,items:const [DropdownMenuItem(value:'low',child:Text('Низкий')),DropdownMenuItem(value:'medium',child:Text('Средний')),DropdownMenuItem(value:'high',child:Text('Высокий')),DropdownMenuItem(value:'critical',child:Text('Критический'))],onChanged:(v)=>set(()=>priority=v??'medium')),TextButton(onPressed:() async { final d=await showDatePicker(context:ctx,firstDate:DateTime.now().subtract(const Duration(days:1)),lastDate:DateTime.now().add(const Duration(days:3650)),initialDate:deadline??DateTime.now()); if(d!=null)set(()=>deadline=d); },child:Text(deadline?.toString().substring(0,10)??'Дедлайн не задан'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Отмена')),FilledButton(onPressed:() async {try{await repo.updateTask(task.id,title:title.text,description:desc.text,priority:priority,deadline:deadline?.millisecondsSinceEpoch);if(ctx.mounted)Navigator.pop(ctx);}catch(e){if(ctx.mounted)showError(ctx,e);}},child:const Text('Сохранить'))])));
}

Future<void> showTaskDetails(BuildContext context, Task task) async {
  final repo = context.read<TaskRepository>(); final comment = TextEditingController();
  final users = await repo.watchUsers().first; if (!context.mounted) return;
  int authorId = users.isEmpty ? 0 : users.first.id;
  await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx,set) => AlertDialog(
    title: Text(task.title), content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Комментарии', style: TextStyle(fontWeight: FontWeight.bold)),
      StreamBuilder<List<Comment>>(stream: repo.watchComments(task.id), builder: (ctx,s) => Column(children: (s.data ?? []).map((c) => ListTile(title:Text(c.body),subtitle:Text('Автор ID: ${c.authorId}'),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:() async {try{await repo.deleteComment(c.id,authorId);}catch(e){if(ctx.mounted)showError(ctx,e);}}))).toList())),
      TextField(controller:comment,decoration:const InputDecoration(labelText:'Новый комментарий')),
      OutlinedButton.icon(onPressed:() async { final id=await chooseUser(ctx,users,title:'Автор комментария',selectedId:authorId==0?null:authorId); if(id!=null)set(()=>authorId=id); },icon:const Icon(Icons.person_search),label:Text(authorId==0?'Выбрать автора':'Автор: ${users.firstWhere((u)=>u.id==authorId).name}')),
      const Divider(), const Text('История изменений',style:TextStyle(fontWeight:FontWeight.bold)),
      StreamBuilder<List<TaskHistoryData>>(stream:repo.watchHistory(task.id),builder:(ctx,s)=>Column(children:(s.data??[]).map((h)=>ListTile(dense:true,title:Text('${h.previousStatus??"—"} → ${h.newStatus}'),subtitle:Text(h.details.isEmpty?DateTime.fromMillisecondsSinceEpoch(h.changedAt).toString():h.details))).toList())),
      const Divider(), const Text('Вложения',style:TextStyle(fontWeight:FontWeight.bold)),
      StreamBuilder<List<Attachment>>(stream:repo.watchAttachments(task.id),builder:(ctx,s)=>Column(children:(s.data??[]).map((a)=>ListTile(dense:true,leading:const Icon(Icons.attach_file),title:Text(a.fileName),subtitle:Text(a.localPath))).toList())),
      TextButton.icon(onPressed:() async { final f=await FilePicker.platform.pickFiles(); if(f!=null && f.files.single.path!=null){await repo.addAttachment(task.id,f.files.single.name,f.files.single.path!);}},icon:const Icon(Icons.attach_file),label:const Text('Прикрепить файл')),
    ]))),
    actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Закрыть')),FilledButton(onPressed:() async {try{await repo.addComment(task.id,authorId,comment.text);comment.clear();}catch(e){if(ctx.mounted)showError(ctx,e);}},child:const Text('Добавить комментарий'))],
  )));
}

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});
  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}
class _ProjectsScreenState extends State<ProjectsScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final repo = context.read<TaskRepository>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final users = await repo.watchUsers().first;
          if (!context.mounted) return;
          if (users.isEmpty) { showError(context, 'Сначала добавьте пользователя'); return; }
          final name = TextEditingController();
          final description = TextEditingController();
          int? ownerId = await chooseUser(context, users, title: 'Выберите владельца проекта');
          if (!context.mounted || ownerId == null) return;
          await showDialog(context: context, builder: (ctx) => AlertDialog(
            title: const Text('Новый проект'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Название')),
              TextField(controller: description, decoration: const InputDecoration(labelText: 'Описание')),
              OutlinedButton.icon(onPressed: () async {
                final selected = await chooseUser(ctx, users, title: 'Выберите владельца проекта', selectedId: ownerId);
                if (selected != null) ownerId = selected;
              }, icon: const Icon(Icons.person_search), label: const Text('Выбрать владельца')),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
              FilledButton(onPressed: () async { try { await repo.addProject(name.text, description.text, ownerId!); if (ctx.mounted) Navigator.pop(ctx); } catch (e) { if (ctx.mounted) showError(ctx, e); } }, child: const Text('Создать')),
            ],
          ));
        },
        icon: const Icon(Icons.add), label: const Text('Проект'),
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 8), child: TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск проектов по названию или описанию', border: OutlineInputBorder()),
          onChanged: (v) => setState(() => query = v),
        )),
        Expanded(child: StreamBuilder<List<Project>>(stream: repo.watchProjects(), builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final projects = snap.data!.where((p) => p.name.toLowerCase().contains(query.toLowerCase()) || p.description.toLowerCase().contains(query.toLowerCase())).toList();
          if (projects.isEmpty) return Center(child: Text(query.isEmpty ? 'Проектов пока нет' : 'Ничего не найдено'));
          return ListView(padding: const EdgeInsets.all(12), children: projects.map((p) => Card(child: ListTile(
            leading: const Icon(Icons.folder_outlined), title: Text(p.name), subtitle: Text(p.description),
            onTap: () => showProjectTasks(ctx, p),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async { try {
                if (v == 'delete') {
                  await repo.deleteProject(p.id);
                } else if (v == 'members') {
                  if (!ctx.mounted) return;
                  await manageMembersDialog(ctx, p);
                } else if (v == 'edit') {
                  if (!ctx.mounted) return;
                  await editProjectDialog(ctx, p);
                } else if (v == 'complete') {
                  await repo.updateProject(p.id, p.name, p.description, 'completed');
                } else if (v == 'archive') {
                  await repo.updateProject(p.id, p.name, p.description, 'archived');
                }
              } catch (e) { if (ctx.mounted) showError(ctx, e); } },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                PopupMenuItem(value: 'members', child: Text('Участники проекта')),
                PopupMenuItem(value: 'complete', child: Text('Завершить')),
                PopupMenuItem(value: 'archive', child: Text('Архивировать')),
                PopupMenuItem(value: 'delete', child: Text('Удалить')),
              ],
            ),
          ))).toList());
        })),
      ]),
    );
  }
}

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}
class _UsersScreenState extends State<UsersScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final repo = context.read<TaskRepository>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final name = TextEditingController();
          final email = TextEditingController();
          await showDialog(context: context, builder: (ctx) => AlertDialog(
            title: const Text('Новый участник'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Имя')),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
              FilledButton(onPressed: () async { try { await repo.addUser(name.text, email.text); if (ctx.mounted) Navigator.pop(ctx); } catch (e) { if (ctx.mounted) showError(ctx, e); } }, child: const Text('Добавить')),
            ],
          ));
        },
        icon: const Icon(Icons.person_add), label: const Text('Участник'),
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 8), child: TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск по имени или email', border: OutlineInputBorder()),
          onChanged: (v) => setState(() => query = v),
        )),
        Expanded(child: StreamBuilder<List<User>>(stream: repo.watchUsers(), builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final users = snap.data!.where((u) => u.name.toLowerCase().contains(query.toLowerCase()) || u.email.toLowerCase().contains(query.toLowerCase())).toList();
          if (users.isEmpty) return Center(child: Text(query.isEmpty ? 'Пользователей пока нет' : 'Ничего не найдено'));
          return ListView.builder(padding: const EdgeInsets.all(12), itemCount: users.length, itemBuilder: (ctx, i) {
            final u = users[i];
            return Card(child: ListTile(
              leading: CircleAvatar(child: Text(u.name.isEmpty ? '?' : u.name[0].toUpperCase())),
              title: Text(u.name), subtitle: Text(u.email),
              trailing: PopupMenuButton<String>(onSelected: (v) async {
                if (v == 'delete') { try { await repo.deleteUser(u.id); } catch (e) { if (ctx.mounted) showError(ctx, e); } }
                if (v == 'edit' && ctx.mounted) await editUserDialog(ctx, u);
                if (v == 'tasks' && ctx.mounted) await showUserTasks(ctx, u);
              }, itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                PopupMenuItem(value: 'tasks', child: Text('Задачи пользователя')),
                PopupMenuItem(value: 'delete', child: Text('Удалить')),
              ]),
            ));
          });
        })),
      ]),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final repo=context.read<TaskRepository>();
    return StreamBuilder<List<Map<String,Object?>>>(stream:repo.watchDashboard(),builder:(ctx,s){
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final d=s.data!.first;
      return ListView(padding:const EdgeInsets.all(16),children:[
        GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:1.6,children:[
          StatTile('Проекты',d['project_count']),StatTile('Всего задач',d['task_count']),StatTile('Завершено',d['done_count']),StatTile('В работе',d['open_count']),StatTile('Просрочено',d['overdue_count']),
        ]),
        const SizedBox(height:12),const Text('Задачи по приоритетам',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        StreamBuilder<List<Map<String,Object?>>>(stream:repo.watchStatsByPriority(),builder:(c,v)=>Column(children:(v.data??[]).map((r)=>ListTile(title:Text(r['priority'].toString()),trailing:Text(r['amount'].toString()))).toList())),
        const Text('Задачи по исполнителям',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        StreamBuilder<List<Map<String,Object?>>>(stream:repo.watchStatsByAssignee(),builder:(c,v)=>Column(children:(v.data??[]).map((r)=>ListTile(title:Text(r['name'].toString()),trailing:Text(r['amount'].toString()))).toList())),
        const Text('Прогресс проектов',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        StreamBuilder<List<Map<String,Object?>>>(stream:repo.watchProjectProgress(),builder:(c,v)=>Column(children:(v.data??[]).map((r){final total=(r['total'] as int?)??0;final done=(r['done'] as int?)??0;final p=total==0?0.0:done/total;return ListTile(title:Text(r['name'].toString()),subtitle:LinearProgressIndicator(value:p),trailing:Text('${(p*100).round()}%'));}).toList())),
        const SizedBox(height:12),
        OutlinedButton.icon(onPressed:()async{try{await repo.seedPerformanceData();if(ctx.mounted)showError(ctx,'Тестовый набор: 1 000 пользователей, 100 проектов, 10 000 задач создан');}catch(e){if(ctx.mounted)showError(ctx,e);}},icon:const Icon(Icons.dataset),label:const Text('Создать тестовую базу 1k / 100 / 10k')),
        OutlinedButton.icon(onPressed:()async{try{final result=await repo.compareIndexPerformance();if(ctx.mounted)showDialog(context:ctx,builder:(dctx)=>AlertDialog(title:const Text('Сравнение индексов'),content:Text('С индексом: ${result['withIndexMicros']} мкс\\nБез индекса: ${result['withoutIndexMicros']} мкс\\nПовторений: 20'),actions:[TextButton(onPressed:()=>Navigator.pop(dctx),child:const Text('Закрыть'))]));}catch(e){if(ctx.mounted)showError(ctx,e);}},icon:const Icon(Icons.speed),label:const Text('Сравнить запрос с индексом и без')),
      ]);
    });
  }
}
class StatTile extends StatelessWidget {
  final String label; final Object? value;
  const StatTile(this.label,this.value,{super.key});
  @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(value?.toString()??'0',style:Theme.of(context).textTheme.headlineMedium),Text(label)])));
}

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final repo=context.read<TaskRepository>();
    return StreamBuilder<List<Task>>(stream:repo.watchTasks(trash:true),builder:(ctx,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());if(s.data!.isEmpty)return const Center(child:Text('Корзина пуста'));return ListView(children:s.data!.map((t)=>Card(child:ListTile(title:Text(t.title),subtitle:Text(t.description),trailing:Wrap(children:[IconButton(tooltip:'Восстановить',icon:const Icon(Icons.restore),onPressed:()=>repo.restoreTask(t.id)),IconButton(tooltip:'Удалить навсегда',icon:const Icon(Icons.delete_forever),onPressed:()=>repo.permanentlyDeleteTask(t.id))])))).toList());});
  }
}


Future<int?> chooseProject(BuildContext context, List<Project> projects, {int? selectedId}) {
  return showDialog<int>(context: context, builder: (dialogContext) {
    String query = '';
    return StatefulBuilder(builder: (ctx, setDialogState) {
      final filtered = projects.where((p) => p.name.toLowerCase().contains(query.toLowerCase()) || p.description.toLowerCase().contains(query.toLowerCase()) || p.id.toString() == query).toList();
      return AlertDialog(
        title: const Text('Выберите проект'),
        content: SizedBox(width: 420, height: 420, child: Column(children: [
          TextField(autofocus: true, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Название проекта или ID', border: OutlineInputBorder()), onChanged: (v) => setDialogState(() => query = v)),
          const SizedBox(height: 8),
          Expanded(child: filtered.isEmpty ? const Center(child: Text('Ничего не найдено')) : ListView.builder(itemCount: filtered.length, itemBuilder: (ctx, i) { final p=filtered[i]; return ListTile(selected:p.id==selectedId,title:Text(p.name),subtitle:Text('ID ${p.id} • ${p.description}'),onTap:()=>Navigator.pop(dialogContext,p.id)); })),
        ])),
        actions: [TextButton(onPressed:()=>Navigator.pop(dialogContext),child:const Text('Отмена'))],
      );
    });
  });
}

Future<int?> chooseUser(BuildContext context, List<User> users, {required String title, int? selectedId}) {
  return showDialog<int>(context: context, builder: (dialogContext) {
    String query = '';
    return StatefulBuilder(builder: (ctx, setDialogState) {
      final filtered = users.where((u) => u.name.toLowerCase().contains(query.toLowerCase()) || u.email.toLowerCase().contains(query.toLowerCase()) || u.id.toString() == query).toList();
      return AlertDialog(
        title: Text(title),
        content: SizedBox(width: 420, height: 420, child: Column(children: [
          TextField(autofocus: true, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Имя, email или ID', border: OutlineInputBorder()), onChanged: (v) => setDialogState(() => query = v)),
          const SizedBox(height: 8),
          Expanded(child: filtered.isEmpty ? const Center(child: Text('Ничего не найдено')) : ListView.builder(itemCount: filtered.length, itemBuilder: (ctx, i) {
            final u = filtered[i];
            return ListTile(selected: u.id == selectedId, leading: CircleAvatar(child: Text(u.name.isEmpty ? '?' : u.name[0].toUpperCase())), title: Text(u.name), subtitle: Text('${u.email} • ID ${u.id}'), onTap: () => Navigator.pop(dialogContext, u.id));
          })),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена'))],
      );
    });
  });
}

Future<void> manageMembersDialog(BuildContext context, Project project) async {
  final repo = context.read<TaskRepository>();
  final users = await repo.watchUsers().first;
  if (!context.mounted) return;
  int? selected = users.isEmpty ? null : users.first.id;
  String role = 'Member';
  await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, set) => AlertDialog(
    title: Text('Участники: ${project.name}'),
    content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
      FutureBuilder<List<Map<String,Object?>>>(future: repo.projectMembers(project.id), builder: (ctx,s) => Column(children: (s.data ?? []).map((m) => ListTile(dense:true,title:Text(m['name'].toString()),subtitle:Text('${m['email']} • ${m['role']}'),trailing:IconButton(icon:const Icon(Icons.person_remove_outlined),onPressed:() async {try{await repo.removeMember(project.id,m['id'] as int);set((){});}catch(e){if(ctx.mounted)showError(ctx,e);}}))).toList())),
      const Divider(),
      if(users.isNotEmpty) OutlinedButton.icon(onPressed:() async { final id=await chooseUser(ctx,users,title:'Добавить участника',selectedId:selected); if(id!=null)set(()=>selected=id); },icon:const Icon(Icons.person_search),label:Text(selected==null?'Выбрать участника':'Участник: ${users.firstWhere((u)=>u.id==selected).name}')),
      DropdownButton<String>(value:role,isExpanded:true,items:const [DropdownMenuItem(value:'Owner',child:Text('Owner')),DropdownMenuItem(value:'Admin',child:Text('Admin')),DropdownMenuItem(value:'Member',child:Text('Member'))],onChanged:(v)=>set(()=>role=v??'Member')),
    ])),
    actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Закрыть')),FilledButton(onPressed:selected==null?null:()async{try{await repo.addMember(project.id,selected!,role);set((){});}catch(e){if(ctx.mounted)showError(ctx,e);}},child:const Text('Добавить участника'))],
  )));
}

Future<void> editUserDialog(BuildContext context, User user) async {
  final repo=context.read<TaskRepository>(); final name=TextEditingController(text:user.name); final email=TextEditingController(text:user.email);
  await showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('Редактировать участника'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'Имя')),TextField(controller:email,decoration:const InputDecoration(labelText:'Email'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Отмена')),FilledButton(onPressed:()async{try{await repo.updateUser(user.id,name.text,email.text);if(ctx.mounted)Navigator.pop(ctx);}catch(e){if(ctx.mounted)showError(ctx,e);}},child:const Text('Сохранить'))]));
}
Future<void> showUserTasks(BuildContext context, User user) async {
  final repo=context.read<TaskRepository>();
  await showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text('Задачи: ${user.name}'),content:SizedBox(width:420,height:400,child:StreamBuilder<List<Task>>(stream:repo.watchTasks(assigneeId:user.id),builder:(ctx,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());if(s.data!.isEmpty)return const Center(child:Text('Назначенных задач нет'));return ListView(children:s.data!.map((t)=>ListTile(title:Text(t.title),subtitle:Text(t.status))).toList());})),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Закрыть'))]));
}

Future<void> reassignTaskDialog(BuildContext context, Task task) async {
  final repo=context.read<TaskRepository>();
  final members=await repo.projectMembers(task.projectId);
  final allUsers=await repo.watchUsers().first;
  final memberIds=members.map((m)=>m['id'] as int).toSet();
  final available=allUsers.where((u)=>memberIds.contains(u.id)).toList();
  if(!context.mounted)return;
  int? selected=task.assigneeId;
  await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,set)=>AlertDialog(title:const Text('Назначить исполнителя'),content:Column(mainAxisSize:MainAxisSize.min,children:[
    OutlinedButton.icon(onPressed:() async {final id=await chooseUser(ctx,available,title:'Выберите исполнителя',selectedId:selected);if(id!=null)set(()=>selected=id);},icon:const Icon(Icons.person_search),label:Text(selected==null?'Не назначен':available.firstWhere((u)=>u.id==selected).name)),
    TextButton(onPressed:()=>set(()=>selected=null),child:const Text('Снять назначение')),
  ]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Отмена')),FilledButton(onPressed:()async{try{await repo.reassignTask(task.id,selected,changedBy:allUsers.isEmpty?null:allUsers.first.id);if(ctx.mounted)Navigator.pop(ctx);}catch(e){if(ctx.mounted)showError(ctx,e);}},child:const Text('Сохранить'))])));
}

Future<void> editProjectDialog(BuildContext context, Project project) async {
  final repo=context.read<TaskRepository>();final name=TextEditingController(text:project.name);final description=TextEditingController(text:project.description);String status=project.status;
  await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,set)=>AlertDialog(title:const Text('Редактировать проект'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'Название')),TextField(controller:description,decoration:const InputDecoration(labelText:'Описание')),DropdownButton<String>(value:status,items:const [DropdownMenuItem(value:'active',child:Text('Активный')),DropdownMenuItem(value:'completed',child:Text('Завершённый')),DropdownMenuItem(value:'archived',child:Text('Архивный'))],onChanged:(v)=>set(()=>status=v??'active'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Отмена')),FilledButton(onPressed:()async{try{await repo.updateProject(project.id,name.text,description.text,status,dueAt:project.dueAt);if(ctx.mounted)Navigator.pop(ctx);}catch(e){if(ctx.mounted)showError(ctx,e);}},child:const Text('Сохранить'))])));
}
Future<void> showProjectTasks(BuildContext context, Project project) async {
  final repo=context.read<TaskRepository>();
  await showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text('Задачи проекта: ${project.name}'),content:SizedBox(width:440,height:420,child:StreamBuilder<List<Task>>(stream:repo.watchTasks(projectId:project.id),builder:(ctx,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());if(s.data!.isEmpty)return const Center(child:Text('В проекте пока нет задач'));return ListView(children:s.data!.map((t)=>ListTile(title:Text(t.title),subtitle:Text('${t.status} • ${t.priority}'))).toList());})),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Закрыть'))]));
}
