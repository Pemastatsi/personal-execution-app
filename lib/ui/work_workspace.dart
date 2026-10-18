import 'package:flutter/material.dart';

import '../storage/execution_state.dart';
import '../storage/task_store.dart';
import '../storage/work_models.dart';
import 'focusflow_palette.dart';

/// Real, local-first workspace. The earlier three-task demo is no longer the app entry.
class WorkWorkspace extends StatefulWidget {
  const WorkWorkspace({
    super.key,
    required this.store,
    required this.checkpoint,
    required this.onCheckpointChanged,
    required this.onToggleTheme,
    required this.darkMode,
  });

  final TaskStore store;
  final ExecutionCheckpoint checkpoint;
  final VoidCallback onCheckpointChanged;
  final VoidCallback onToggleTheme;
  final bool darkMode;

  @override
  State<WorkWorkspace> createState() => _WorkWorkspaceState();
}

class _WorkWorkspaceState extends State<WorkWorkspace> {
  List<WorkItem> items = [];
  List<WorkProject> projects = [];
  List<WorkMilestone> milestones = [];
  WorkItem? selected;
  bool loading = true;
  bool focus = false;
  bool showCompleted = false;
  final note = TextEditingController();
  final blocker = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    note.dispose();
    blocker.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final newItems = await widget.store.listWorkItems(includeCompleted: showCompleted);
    final newProjects = await widget.store.listProjects();
    final oldId = selected?.id ?? widget.checkpoint.selectedTaskId;
    final matching = newItems.where((t) => t.id == oldId);
    final next = matching.isNotEmpty ? matching.first : (newItems.isEmpty ? null : newItems.first);
    final stages = next == null ? <WorkMilestone>[] : await widget.store.listMilestones(next.id);
    if (!mounted) return;
    setState(() {
      items = newItems;
      projects = newProjects;
      selected = next;
      milestones = stages;
      loading = false;
      if (next == null) focus = false;
    });
    _loadFields(next);
  }

  void _loadFields(WorkItem? task) {
    if (task == null) {
      note.clear();
      blocker.clear();
      return;
    }
    widget.checkpoint.selectedTaskId = task.id;
    final saved = widget.checkpoint.forTask(task.id);
    note.text = saved.note;
    blocker.text = saved.blocker;
    widget.onCheckpointChanged();
  }

  Future<void> _select(WorkItem item) async {
    if (selected?.id == item.id) {
      setState(() => focus = true);
      return;
    }
    await _saveContext();
    final stages = await widget.store.listMilestones(item.id);
    if (!mounted) return;
    setState(() {
      selected = item;
      milestones = stages;
      focus = true;
    });
    _loadFields(item);
  }

  Future<void> _saveContext() async {
    final task = selected;
    if (task == null) return;
    final state = widget.checkpoint.forTask(task.id);
    state.note = note.text;
    state.blocker = blocker.text;
    state.lastTouched = DateTime.now().toUtc();
    widget.onCheckpointChanged();
  }

  String _projectName(String? id) {
    if (id == null) return 'Unfiled';
    for (final p in projects) {
      if (p.id == id) return p.name;
    }
    return 'Unfiled';
  }

  Future<void> _createProject() async {
    final name = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('New project'),
          content: TextField(controller: name, autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Project name')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
          ],
        ),
      );
      if (ok == true && name.text.trim().isNotEmpty) {
        await widget.store.createProject(name.text);
        await _reload();
      }
    } finally {
      name.dispose();
    }
  }

  Future<void> _editTask({WorkItem? item}) async {
    final title = TextEditingController(text: item?.title ?? '');
    final action = TextEditingController(text: item?.nextAction ?? '');
    final description = TextEditingController(text: item?.description ?? '');
    String? projectId = item?.projectId;
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => AlertDialog(
          title: Text(item == null ? 'Capture a task' : 'Edit task'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: title, autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Task title *')),
            const SizedBox(height: 12),
            TextField(controller: action, textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'One next action', hintText: 'What can you do now?')),
            const SizedBox(height: 12),
            TextField(controller: description, maxLines: 2,
              decoration: const InputDecoration(labelText: 'Context (optional)')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: projectId ?? '',
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Project'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Unfiled')),
                ...projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
              ],
              onChanged: (id) => refresh(() => projectId = id == '' ? null : id),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text(item == null ? 'Save task' : 'Save changes')),
          ],
        )),
      );
      if (ok != true || title.text.trim().isEmpty) return;
      if (item == null) {
        final created = await widget.store.createWorkItem(
          title: title.text, nextAction: action.text,
          description: description.text, projectId: projectId,
        );
        widget.checkpoint.selectedTaskId = created.id;
      } else {
        await widget.store.updateWorkItem(item, title: title.text,
          nextAction: action.text, description: description.text, projectId: projectId);
      }
      await _reload();
    } finally {
      title.dispose();
      action.dispose();
      description.dispose();
    }
  }

  Future<void> _addMilestone() async {
    final task = selected;
    if (task == null) return;
    final title = TextEditingController();
    final criteria = TextEditingController();
    try {
      final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('New milestone'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, autofocus: true,
            decoration: const InputDecoration(labelText: 'Outcome *')),
          const SizedBox(height: 12),
          TextField(controller: criteria, maxLines: 2,
            decoration: const InputDecoration(labelText: 'What would prove it is done?')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ));
      if (ok == true && title.text.trim().isNotEmpty) {
        await widget.store.addMilestone(task.id, title.text, criteria.text);
        await _reload();
      }
    } finally {
      title.dispose();
      criteria.dispose();
    }
  }

  Future<void> _verify(WorkMilestone milestone) async {
    final evidence = TextEditingController();
    try {
      final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Verify outcome'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(milestone.title),
          if (milestone.criteria.isNotEmpty) Text(milestone.criteria),
          const SizedBox(height: 12),
          TextField(controller: evidence, maxLines: 3,
            decoration: const InputDecoration(labelText: 'What evidence did you check? *')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not yet')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm verification')),
        ],
      ));
      if (ok == true && evidence.text.trim().isNotEmpty) {
        await widget.store.verifyMilestone(milestone.id, evidence.text);
        await _reload();
      }
    } finally {
      evidence.dispose();
    }
  }

  Future<void> _completeTask() async {
    final task = selected;
    if (task == null) return;
    final verified = milestones.where((m) => m.verified).length;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Complete task?'),
      content: Text('Mark this task complete? $verified of ${milestones.length} milestones verified. Unverified milestones will remain unverified.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Complete')),
      ],
    ));
    if (ok == true) {
      await _saveContext();
      await widget.store.setWorkItemCompleted(task.id, true);
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = FocusPalette.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 850;
    return Scaffold(
      appBar: AppBar(
        title: const Text('focusflow'),
        actions: [
          IconButton(tooltip: 'Create project', icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: _createProject),
          IconButton(tooltip: 'Toggle color theme',
            icon: Icon(widget.darkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: widget.onToggleTheme),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editTask(), icon: const Icon(Icons.add), label: const Text('Capture task')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000),
              child: wide
                  ? Row(children: [
                      SizedBox(width: 325, child: _list(colors)),
                      const VerticalDivider(width: 1),
                      Expanded(child: _detail(colors)),
                    ])
                  : focus ? _detail(colors) : _list(colors))),
      bottomNavigationBar: wide ? null : NavigationBar(
        selectedIndex: focus ? 1 : 0,
        onDestinationSelected: (i) => setState(() => focus = i == 1),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.center_focus_strong_outlined), label: 'Focus'),
        ],
      ),
    );
  }

  Widget _list(FocusPalette c) => ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), children: [
    Text('One thing at a time.', style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, color: c.ink)),
    const SizedBox(height: 8),
    Text('Your work stays here when you leave.', style: TextStyle(color: c.muted)),
    const SizedBox(height: 20),
    if (items.isEmpty)
      const Padding(padding: EdgeInsets.symmetric(vertical: 32),
        child: Text('No tasks yet. Capture one thing you want to do.')),
    if (selected != null) ...[
      Text('RESUME', style: TextStyle(color: c.accentText, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Card(child: ListTile(
        title: Text(selected!.title), subtitle: Text(selected!.nextAction.isEmpty
          ? 'Define your next action' : selected!.nextAction),
        trailing: const Icon(Icons.arrow_forward_ios, size: 17),
        onTap: () => setState(() => focus = true),
      )),
    ],
    const SizedBox(height: 20),
    Text('OTHER TASKS', style: TextStyle(color: c.muted)),
    for (final item in items.where((e) => e.id != selected?.id).take(2))
      Card(child: ListTile(
        title: Text(item.title),
        subtitle: Text(_projectName(item.projectId)),
        onTap: () => _select(item),
      )),
    const SizedBox(height: 14),
    SwitchListTile(
      title: const Text('Show completed tasks'),
      value: showCompleted,
      onChanged: (value) async { setState(() => showCompleted = value); await _reload(); },
    ),
    if (showCompleted)
      for (final item in items.where((e) => e.completed))
        ListTile(title: Text(item.title), trailing: TextButton(
          onPressed: () async {
            await widget.store.setWorkItemCompleted(item.id, false);
            await _reload();
          }, child: const Text('Reopen')),
        ),
    const Divider(height: 30),
    Text('PROJECTS', style: TextStyle(color: c.muted)),
    if (projects.isEmpty) const Text('Create a project to organize related tasks.'),
    for (final project in projects) ListTile(
      title: Text(project.name),
      subtitle: Text('${items.where((t) => t.projectId == project.id).length} visible tasks'),
    ),
  ]);

  Widget _detail(FocusPalette c) {
    final task = selected;
    if (task == null) return const Center(child: Text('Capture a task to begin.'));
    final verified = milestones.where((m) => m.verified).length;
    final next = milestones.where((m) => !m.verified);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 110), children: [
      Text(_projectName(task.projectId), style: TextStyle(color: c.muted)),
      const SizedBox(height: 8),
      Text(task.title, style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, color: c.ink)),
      if (task.description.isNotEmpty) ...[
        const SizedBox(height: 7), Text(task.description),
      ],
      const SizedBox(height: 16),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DO THIS NOW', style: TextStyle(color: c.accentText, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(task.nextAction.isEmpty
              ? 'Define a concrete next action to get started.'
              : task.nextAction,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () => _editTask(item: task),
            icon: const Icon(Icons.edit_outlined), label: const Text('Edit task / next action')),
        ],
      ))),
      const SizedBox(height: 18),
      Text('Milestones: $verified of ${milestones.length} verified',
        style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      if (next.isNotEmpty) ...[
        Text('Current outcome: ${next.first.title}'),
        if (next.first.criteria.isNotEmpty) Text('Done when: ${next.first.criteria}'),
      ],
      for (final milestone in milestones) Card(child: ListTile(
        title: Text(milestone.title),
        subtitle: Text(milestone.verified
            ? 'Verified: ${milestone.evidence}'
            : milestone.criteria.isEmpty ? 'Awaiting verification' : milestone.criteria),
        leading: Icon(milestone.verified ? Icons.verified_outlined : Icons.circle_outlined,
          color: milestone.verified ? c.success : c.muted),
        trailing: milestone.verified ? null
          : TextButton(onPressed: () => _verify(milestone), child: const Text('Verify')),
      )),
      OutlinedButton.icon(onPressed: _addMilestone,
        icon: const Icon(Icons.add), label: const Text('Add milestone')),
      const SizedBox(height: 18),
      TextField(controller: note, maxLines: 3, onChanged: (_) => _saveContext(),
        decoration: const InputDecoration(labelText: 'Session notes / exact position')),
      const SizedBox(height: 12),
      TextField(controller: blocker, maxLines: 2, onChanged: (_) => _saveContext(),
        decoration: const InputDecoration(labelText: 'Current blocker')),
      const SizedBox(height: 14),
      if (!task.completed)
        FilledButton(onPressed: _completeTask, child: const Text('Complete task')),
      if (task.completed)
        OutlinedButton(onPressed: () async {
          await widget.store.setWorkItemCompleted(task.id, false);
          await _reload();
        }, child: const Text('Reopen task')),
    ]);
  }
}
