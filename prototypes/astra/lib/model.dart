import 'package:flutter/foundation.dart';
import 'storage.dart';

enum AppPage { home, focus, coach, roadmap, recovery }
enum Detail { micro, normal, overview }

class ActionStep {
  final String title, detail, micro, overview;
  const ActionStep(this.title, this.detail, this.micro, this.overview);
}

class Milestone {
  final String title, evidence;
  const Milestone(this.title, this.evidence);
}

class ChatLine {
  final String text;
  final bool fromUser, screenshot;
  const ChatLine(this.text, {this.fromUser = false, this.screenshot = false});
  Map<String, dynamic> toJson() => {'text': text, 'user': fromUser, 'screenshot': screenshot};
  factory ChatLine.fromJson(Map<String, dynamic> j) => ChatLine(j['text'] as String,
    fromUser: j['user'] as bool, screenshot: j['screenshot'] as bool);
}

class WorkTask {
  final String id, title, category, context;
  final List<Milestone> milestones;
  int verified, actionIndex;
  bool awaitingVerification, visited;
  String blocker;
  Detail detail;
  DateTime lastTouched;
  final List<ChatLine> chat;
  final List<String> history;
  WorkTask({required this.id, required this.title, required this.category,
    required this.context, required this.milestones, this.verified = 0,
    this.actionIndex = 0, this.awaitingVerification = false, this.visited = false,
    this.blocker = '', this.detail = Detail.normal, DateTime? lastTouched,
    List<ChatLine>? chat, List<String>? history})
    : lastTouched = lastTouched ?? DateTime.now(), chat = chat ?? [], history = history ?? [];

  bool get finished => verified >= milestones.length;
  Milestone get milestone => milestones[finished ? milestones.length - 1 : verified];
  // Concrete plans are materialized only for the current milestone.
  List<ActionStep> get steps {
    if (id == 'indicator') {
      if (verified == 2) {
        return const [
          ActionStep('Open the editor and locate the error list.',
            'In MetaEditor, open Momentum.mq5. The Errors tab is in the Toolbox at the bottom.',
            'Open MetaEditor. Look at the bottom of the window for the Toolbox, then select the Errors tab. If it is hidden, choose View → Toolbox.',
            'Find the compiler errors in MetaEditor.'),
          ActionStep('Open the first error in the list.',
            'Double-click the first red error row. The editor will jump to the line that needs attention.',
            'Find the first row with a red icon in Errors. Double-click it once. Keep the highlighted code line visible.',
            'Inspect the first compiler error.'),
          ActionStep('Add the missing semicolon on line 42.',
            'In this sample, the statement on line 42 ends without a semicolon. Add ; at the end, then save.',
            'Click at the end of line 42. Type a semicolon (;). Save the file with Ctrl+S.',
            'Correct the syntax error and save.'),
          ActionStep('Compile and check for zero errors.',
            'Select Compile in the toolbar. Check that the Errors tab reports “0 errors”.',
            'Select the Compile button at the top. Wait for compilation to finish. Read the summary in the Errors tab at the bottom.',
            'Verify that the indicator compiles cleanly.'),
        ];
      }
      if (verified == 3) {
        return const [ActionStep('Attach the indicator to a demo chart.',
          'In the demo terminal, drag Momentum from Navigator → Indicators onto a chart. Check that the line appears.',
          'Open the demo terminal. Expand Indicators in Navigator. Drag Momentum onto an open chart.',
          'Check the indicator on a demo chart.')];
      }
      return const [ActionStep('Compare one signal with your written rule.',
        'Choose a completed candle on a demo chart. Check whether its signal matches the rule you saved.',
        'Open your saved rule. Choose one completed candle with a signal, then compare its values with that rule.',
        'Validate one example against the rule.')];
    }
    if (id == 'application') {
      return verified == 0 ? const [
        ActionStep('Find the required ID document.', 'Look in your documents folder for a clear copy of your ID. Keep it open next to the form.', 'Open your documents folder. Find the file named ID or passport. Open it and check that the text is readable.', 'Locate a readable copy of your ID.'),
      ] : const [
        ActionStep('Attach the ID and review the form.', 'Add the ID to the application, then read the required fields once before submitting.', 'Select Attach document on your form. Choose the ID file. Check each required field before you submit.', 'Review and submit the application.'),
      ];
    }
    if (id == 'bulb') {
      return const [ActionStep('Switch off the light and let the bulb cool.',
        'Leave the light off until the bulb is cool to touch. Use a stable step if the fitting is above reach.',
        'Turn off the wall switch. Wait for the bulb to cool before touching it.', 'Make the light safe to work on.'),
        ActionStep('Fit the matching replacement bulb.', 'With the light off, replace the cool bulb with a matching type and wattage. Then switch on to check it works.', 'Read the old bulb’s type and wattage. Fit a matching replacement with the switch off, then test the light.', 'Replace the bulb and check the light.')];
    }
    return [ActionStep('Choose the first physical step.',
      'For “$title”, name something you can open, find, or put in front of you. Use the coach to make it smaller.',
      'Put the thing you need for “$title” in front of you. Start there.', 'Make a small start on this task.')];
  }
  ActionStep get action => steps[actionIndex.clamp(0, steps.length - 1)];
  String get nextAction => finished ? 'This task is complete.' : awaitingVerification ? 'Verify: ${milestone.title.toLowerCase()}.' : action.title;
  String get resumeContext {
    final completed = history.where((entry) => entry.startsWith('Completed:'));
    if (finished) { return 'All ${milestones.length} outcomes are verified. ${milestone.evidence}'; }
    if (completed.isEmpty) { return context; }
    return '$verified of ${milestones.length} outcomes are verified. Last action: ${completed.last.substring(11)}';
  }
  String instruction() => switch (detail) { Detail.micro => action.micro, Detail.normal => action.detail, Detail.overview => action.overview };
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'category': category, 'context': context,
    'milestones': milestones.map((m) => {'title': m.title, 'evidence': m.evidence}).toList(),
    'verified': verified, 'action': actionIndex, 'awaiting': awaitingVerification,
    'visited': visited, 'blocker': blocker, 'detail': detail.index, 'touched': lastTouched.toIso8601String(),
    'chat': chat.map((m) => m.toJson()).toList(), 'history': history};
  factory WorkTask.fromJson(Map<String, dynamic> j) => WorkTask(
    id: j['id'] as String, title: j['title'] as String, category: j['category'] as String, context: j['context'] as String,
    milestones: (j['milestones'] as List).map((m) => Milestone(m['title'] as String, m['evidence'] as String)).toList(),
    verified: j['verified'] as int, actionIndex: j['action'] as int, awaitingVerification: j['awaiting'] as bool,
    visited: j['visited'] as bool, blocker: j['blocker'] as String, detail: Detail.values[j['detail'] as int],
    lastTouched: DateTime.parse(j['touched'] as String),
    chat: (j['chat'] as List).map((m) => ChatLine.fromJson(m as Map<String, dynamic>)).toList(),
    history: List<String>.from(j['history'] as List));
}

List<WorkTask> sampleTasks() => [
  WorkTask(id: 'indicator', title: 'Build a trading indicator', category: 'Technical project',
    context: 'Your signal rules are written and the indicator file is created. You paused when the first compile showed an error.',
    verified: 2, visited: true, lastTouched: DateTime.now().subtract(const Duration(days: 14)),
    blocker: 'The compiler reports an error. The cause is not identified yet.',
    history: ['Defined the signal rules.', 'Created Momentum.mq5.', 'Paused at the compiler error list.'],
    milestones: const [
      Milestone('Define the signal rules', 'Entry and exit rules saved in the project notes.'),
      Milestone('Create the indicator file', 'Momentum.mq5 exists in the Indicators folder.'),
      Milestone('Compile the indicator without errors', 'The compiler reports 0 errors.'),
      Milestone('See the indicator on a chart', 'The indicator is visible on a demo chart.'),
      Milestone('Verify a signal against the rules', 'A completed candle matches the written signal rule.'),
    ]),
  WorkTask(id: 'application', title: 'Send an application form', category: 'Personal admin',
    context: 'The form is ready to finish. A readable ID copy is the remaining attachment.',
    milestones: const [Milestone('Find the required ID document', 'A readable ID document is ready.'), Milestone('Submit the application', 'A submission confirmation is visible.')]),
  WorkTask(id: 'bulb', title: 'Replace a household light bulb', category: 'Quick task',
    context: 'The hallway light needs a matching replacement bulb.',
    milestones: const [Milestone('Restore the hallway light', 'The new bulb lights up when switched on.')]),
];

class ExecutionModel extends ChangeNotifier {
  final CheckpointStore store;
  List<WorkTask> tasks = sampleTasks();
  String? activeId = 'indicator';
  String selectedId = 'indicator';
  bool dark = false;
  bool saveFailed = false;
  AppPage page = AppPage.home;
  bool milestoneView = false;
  Future<void> _pending = Future.value();
  ExecutionModel(this.store);
  WorkTask get selected => tasks.firstWhere((t) => t.id == selectedId);
  WorkTask? get active => activeId == null ? null : tasks.firstWhere((t) => t.id == activeId);
  List<WorkTask> get available => tasks.where((t) => !t.finished).toList();
  Future<void> restore() async {
    final j = await store.read();
    if (j != null) {
      tasks = (j['tasks'] as List).map((t) => WorkTask.fromJson(t as Map<String, dynamic>)).toList();
      activeId = j['active'] as String?;
      selectedId = j['selected'] as String;
      dark = j['dark'] as bool;
    }
    notifyListeners();
  }
  Map<String, dynamic> snapshot() => {'tasks': tasks.map((t) => t.toJson()).toList(), 'active': activeId, 'selected': selectedId, 'dark': dark};
  void changed() {
    final value = snapshot();
    _pending = _pending.then((_) => store.write(value)).then((_) {
      if (saveFailed) { saveFailed = false; notifyListeners(); }
    }).catchError((Object _) { saveFailed = true; notifyListeners(); });
    notifyListeners();
  }
  Future<void> flush() => _pending;
  void go(AppPage value) { page = value; notifyListeners(); }
  void toggleTheme() { dark = !dark; changed(); }
  void setDetail(Detail value) { selected.detail = value; changed(); }
  void openRoadmap({bool milestone = false}) { milestoneView = milestone; go(AppPage.roadmap); }
  void preview(WorkTask task) { selectedId = task.id; go(AppPage.recovery); }
  void resume(WorkTask task) {
    if (active != null && activeId != task.id) { active!.lastTouched = DateTime.now(); }
    activeId = selectedId = task.id;
    task.visited = true;
    task.lastTouched = DateTime.now();
    page = AppPage.focus;
    changed();
  }
  void completeAction() {
    final t = selected;
    if (t.finished || t.awaitingVerification) { return; }
    t.history.add('Completed: ${t.action.title}');
    t.blocker = '';
    t.lastTouched = DateTime.now();
    if (t.actionIndex + 1 == t.steps.length) { t.awaitingVerification = true; }
    else { t.actionIndex++; }
    changed();
  }
  void verifyOutcome() {
    final t = selected;
    if (!t.awaitingVerification || t.finished) { return; }
    t.history.add('Verified: ${t.milestone.evidence}');
    t.verified++;
    t.actionIndex = 0;
    t.awaitingVerification = false;
    t.blocker = '';
    if (t.finished) { activeId = null; }
    changed();
  }
  void retryOutcome() { selected.awaitingVerification = false; changed(); }
  void openCoach({bool stuck = false}) {
    if (stuck) { selected.blocker = 'Stuck at: ${selected.nextAction}'; }
    if (selected.chat.isEmpty) {
      selected.chat.add(ChatLine(selected.id == 'indicator'
        ? 'Let’s find the compiler’s first clue. Open the Errors tab at the bottom of MetaEditor.'
        : 'Start here: ${selected.nextAction}'));
    }
    page = AppPage.coach;
    changed();
  }
  void send(String message, {bool screenshot = false}) {
    final clean = message.trim();
    if (clean.isEmpty) { return; }
    selected.chat.add(ChatLine(clean, fromUser: true, screenshot: screenshot));
    final t = selected;
    final answer = screenshot && t.id == 'indicator'
      ? 'The sample shows a missing semicolon near line 42. Double-click the first red error row to jump to that line.'
      : t.id == 'indicator' && (clean.toLowerCase().contains('find') || clean.toLowerCase().contains('toolbox'))
      ? 'The Toolbox may be hidden. Select View → Toolbox, then choose the Errors tab at the bottom.'
      : 'Make this one step smaller: ${t.action.micro}';
    t.chat.add(ChatLine(answer));
    t.history.add(screenshot ? 'Reviewed a sample screenshot with the mock coach.' : 'Asked the mock coach for help.');
    changed();
  }
  void addTask(String title) {
    if (title.trim().isEmpty) { return; }
    tasks.add(WorkTask(id: 'captured-${DateTime.now().microsecondsSinceEpoch}', title: title.trim(),
      category: 'Captured task', context: 'Captured by you. No plan has been made yet.',
      milestones: [Milestone('Finish ${title.trim()}', 'The task’s intended result is complete.')]));
    changed();
  }
}
