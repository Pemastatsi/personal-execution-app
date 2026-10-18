import 'package:flutter/material.dart';

import 'demo_task.dart';
import 'focusflow_palette.dart';

enum AppView { today, focus, projects }

class FocusFlowShell extends StatefulWidget {
  const FocusFlowShell({
    super.key,
    required this.onToggleTheme,
    required this.darkMode,
  });

  final VoidCallback onToggleTheme;
  final bool darkMode;

  @override
  State<FocusFlowShell> createState() => _FocusFlowShellState();
}

class _FocusFlowShellState extends State<FocusFlowShell> {
  AppView _view = AppView.today;
  int _activeIndex = 0;
  final Set<String> _completed = {};
  final Map<String, String> _notes = {};
  final TextEditingController _noteController = TextEditingController();
  bool _showBlockerHelp = false;

  DemoTask get _task => demoTasks[_activeIndex];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _selectTask(int index, {bool focus = false}) {
    setState(() {
      _notes[_task.id] = _noteController.text;
      _activeIndex = index;
      _noteController.text = _notes[_task.id] ?? '';
      _showBlockerHelp = false;
      _view = focus ? AppView.focus : AppView.today;
    });
  }

  void _navigate(AppView target) {
    setState(() {
      _notes[_task.id] = _noteController.text;
      _view = target;
      _showBlockerHelp = false;
    });
  }

  void _markDone() {
    setState(() {
      if (_completed.contains(_task.id)) {
        _completed.remove(_task.id);
      } else {
        _completed.add(_task.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 850;
    final c = FocusPalette.of(context);

    final content = switch (_view) {
      AppView.today => _today(c, desktop),
      AppView.focus => _focus(c, desktop),
      AppView.projects => _projects(c),
    };

    return Scaffold(
      body: SafeArea(
        child: desktop
            ? Row(
                children: [
                  SizedBox(width: 214, child: _desktopNavigation(c)),
                  Expanded(child: content),
                ],
              )
            : Column(
                children: [
                  _mobileHeader(c),
                  Expanded(child: content),
                ],
              ),
      ),
      bottomNavigationBar: desktop
          ? null
          : NavigationBar(
              selectedIndex: switch (_view) {
                AppView.today => 0,
                AppView.focus => 1,
                AppView.projects => 2,
              },
              onDestinationSelected: (index) => _navigate(AppView.values[index]),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Today',
                ),
                NavigationDestination(
                  icon: Icon(Icons.center_focus_strong_outlined),
                  label: 'Focus',
                ),
                NavigationDestination(
                  icon: Icon(Icons.folder_outlined),
                  label: 'Projects',
                ),
              ],
            ),
    );
  }

  Widget _desktopNavigation(FocusPalette c) {
    return ColoredBox(
      color: c.panel,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _brand(c),
            const SizedBox(height: 54),
            _eyebrow('WORKSPACE', c),
            const SizedBox(height: 16),
            _navItem(Icons.home_outlined, 'Today', AppView.today, c),
            _navItem(Icons.center_focus_strong_outlined, 'Focus', AppView.focus, c),
            _navItem(Icons.folder_outlined, 'Projects', AppView.projects, c),
            const SizedBox(height: 36),
            _eyebrow('PINNED', c),
            const SizedBox(height: 12),
            ...List.generate(
              demoTasks.length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: TextButton(
                  onPressed: () => _selectTask(i),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(demoTasks[i].project),
                  ),
                ),
              ),
            ),
            const Spacer(),
            _themeButton(c),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String name, AppView view, FocusPalette c) {
    final active = view == _view;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: active ? c.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigate(view),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: active ? c.accentText : c.muted),
                const SizedBox(width: 12),
                Text(
                  name,
                  style: TextStyle(
                    color: active ? c.accentText : c.ink,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _brand(FocusPalette c) {
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.accentSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(Icons.auto_awesome_rounded, color: c.accentText),
          ),
        ),
        const SizedBox(width: 12),
        Text('focusflow', style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700, color: c.ink,
        )),
      ],
    );
  }

  Widget _themeButton(FocusPalette c) {
    return TextButton.icon(
      onPressed: widget.onToggleTheme,
      icon: Icon(widget.darkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      label: Text(widget.darkMode ? 'Light mode' : 'Dark mode'),
    );
  }

  Widget _mobileHeader(FocusPalette c) {
    return Container(
      height: 70,
      color: c.panel,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _brand(c),
          const Spacer(),
          IconButton(
            tooltip: 'Toggle color theme',
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.darkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          ),
        ],
      ),
    );
  }

  Widget _eyebrow(String label, FocusPalette c) => Text(
    label,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.1,
      color: c.muted,
    ),
  );

  Widget _panel({
    required FocusPalette c,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(22),
    bool outlined = false,
  }) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: c.panel,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: outlined ? c.accent : c.border),
    ),
    child: child,
  );

  Widget _tag(String label, FocusPalette c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(50),
      color: c.accentSoft,
    ),
    child: Text(label, style: TextStyle(
      fontSize: 10, fontWeight: FontWeight.w700, color: c.accentText,
    )),
  );

  Widget _primary(String label, VoidCallback onPressed, FocusPalette c) =>
      FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.primaryText,
          minimumSize: const Size(150, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
        child: Text(label),
      );

  Widget _secondary(String label, VoidCallback onPressed, FocusPalette c) =>
      TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: c.ink,
          backgroundColor: c.panelAlt,
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
        child: Text(label),
      );

  Widget _contentScroll(Widget child) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: child,
      ),
    ),
  );

  Widget _today(FocusPalette c, bool desktop) {
    final center = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow('WORKSPACE / TODAY', c),
        const SizedBox(height: 20),
        Text('One thing at a time.', style: TextStyle(
          fontSize: desktop ? 36 : 29,
          fontWeight: FontWeight.w700, color: c.ink,
        )),
        const SizedBox(height: 8),
        Text('Your next step is ready. Everything else can wait.',
          style: TextStyle(fontSize: 14, color: c.muted)),
        const SizedBox(height: 24),
        _panel(
          c: c,
          outlined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tag('01 · IN FOCUS', c),
              const SizedBox(height: 19),
              Text(_task.title, style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700, color: c.ink,
              )),
              const SizedBox(height: 11),
              Text(_task.description, style: TextStyle(color: c.muted)),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: c.panelAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _eyebrow('NEXT ACTION', c),
                    const SizedBox(height: 5),
                    Text(
                      _completed.contains(_task.id) ? _task.followUpAction : _task.action,
                      style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _primary('Start focus  ↗', () => _navigate(AppView.focus), c),
                  _secondary('Switch task', () => _navigate(AppView.projects), c),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text('In motion', style: TextStyle(
          fontSize: 19, fontWeight: FontWeight.w700, color: c.ink,
        )),
        const SizedBox(height: 13),
        for (var i = 0; i < demoTasks.length; i++)
          if (i != _activeIndex) ...[
            _projectTile(i, c),
            const SizedBox(height: 9),
          ],
      ],
    );
    if (!desktop) return _contentScroll(center);
    return _contentScroll(Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: center),
        const SizedBox(width: 34),
        Expanded(flex: 3, child: _rightRail(c)),
      ],
    ));
  }

  Widget _projectTile(int i, FocusPalette c) => Material(
    color: c.panel,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: c.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      title: Text(demoTasks[i].title, style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600,
      )),
      subtitle: Text(demoTasks[i].action,
        maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.north_east_rounded, size: 18),
      onTap: () => _selectTask(i, focus: true),
    ),
  );

  Widget _rightRail(FocusPalette c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _eyebrow('YOUR DAY', c),
      const SizedBox(height: 12),
      _panel(c: c, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${demoTasks.length}', style: TextStyle(
            fontSize: 32, fontWeight: FontWeight.w700, color: c.ink,
          )),
          Text('sample projects', style: TextStyle(color: c.muted)),
          const SizedBox(height: 10),
          Text('One clear task is ready.', style: TextStyle(color: c.muted)),
        ],
      )),
      const SizedBox(height: 23),
      _eyebrow('FOCUSFLOW GUIDE', c),
      const SizedBox(height: 12),
      _panel(c: c, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Action before planning',
            style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text('Complete the current concrete step before opening the full roadmap.',
            style: TextStyle(color: c.muted)),
        ],
      )),
      const SizedBox(height: 25),
      _eyebrow('DEMO MODE · NO LIVE TASK DATA', c),
    ],
  );

  Widget _focus(FocusPalette c, bool desktop) {
    final stepDone = _completed.contains(_task.id);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => _navigate(AppView.today),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back to Today'),
        ),
        const SizedBox(height: 24),
        _tag('FOCUS SESSION', c),
        const SizedBox(height: 18),
        Text(stepDone ? _task.followUpAction : _task.action,
          style: TextStyle(
            fontSize: desktop ? 32 : 27,
            height: 1.2,
            fontWeight: FontWeight.w700, color: c.ink,
          )),
        const SizedBox(height: 11),
        Text(_task.project, style: TextStyle(color: c.muted)),
        const SizedBox(height: 25),
        Row(children: [
          Expanded(child: Container(height: 5, decoration: BoxDecoration(
            color: c.accent, borderRadius: BorderRadius.circular(3),
          ))),
          const SizedBox(width: 6),
          for (var i = 0; i < 2; i++) ...[
            Expanded(child: Container(height: 5, decoration: BoxDecoration(
              color: c.border, borderRadius: BorderRadius.circular(3),
            ))),
            if (i == 0) const SizedBox(width: 6),
          ],
        ]),
        const SizedBox(height: 23),
        _panel(c: c, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow('DO THIS NOW', c),
            const SizedBox(height: 16),
            Text(stepDone ? 'Step recorded' : 'Follow the next action',
              style: TextStyle(fontSize: 21,
                fontWeight: FontWeight.w700, color: c.ink)),
            const SizedBox(height: 12),
            Text('Work through these small checks. Completion is always yours to confirm.',
              style: TextStyle(color: c.muted)),
            const SizedBox(height: 17),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.panelAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(children: [
                for (var i = 0; i < _task.microSteps.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(children: [
                      SizedBox(width: 34, child: Text(
                        '${i + 1}'.padLeft(2, '0'),
                        style: TextStyle(color: c.accentText,
                          fontWeight: FontWeight.w700),
                      )),
                      Expanded(child: Text(_task.microSteps[i])),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _primary(stepDone ? 'Undo completion' : 'Mark step done ✓', _markDone, c),
              _secondary("I'm stuck", () => setState(() {
                _showBlockerHelp = !_showBlockerHelp;
              }), c),
            ]),
            if (_showBlockerHelp) ...[
              const SizedBox(height: 17),
              Text('What is blocking you?', style: TextStyle(
                fontWeight: FontWeight.w700, color: c.ink)),
              const SizedBox(height: 8),
              Text('Capture the error in the note below. AI troubleshooting is not connected in this preview.',
                style: TextStyle(color: c.muted)),
            ],
          ],
        )),
        const SizedBox(height: 17),
        _panel(c: c, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Save what you found', style: TextStyle(
              fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Write the error message or outcome here…',
              ),
              onChanged: (v) => _notes[_task.id] = v,
            ),
          ],
        )),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _navigate(AppView.projects),
          icon: const Icon(Icons.north_east_outlined, size: 16),
          label: const Text('Switch tasks without losing your place'),
        ),
      ],
    );
    if (!desktop) return _contentScroll(body);
    return _contentScroll(Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: body),
        const SizedBox(width: 34),
        Expanded(flex: 3, child: _completionRail(c)),
      ],
    ));
  }

  Widget _completionRail(FocusPalette c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _eyebrow('FOCUS COACH', c),
      const SizedBox(height: 16),
      Text('Only what matters.', style: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w700, color: c.ink)),
      const SizedBox(height: 17),
      _panel(c: c, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow('DONE WHEN', c),
          const SizedBox(height: 18),
          for (final criterion in _task.completionCriteria)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(children: [
                Icon(Icons.check, size: 17, color: c.success),
                const SizedBox(width: 9),
                Expanded(child: Text(criterion, style: const TextStyle(fontSize: 12))),
              ]),
            ),
        ],
      )),
      const SizedBox(height: 19),
      Text('Mock progress', style: TextStyle(color: c.muted)),
      const SizedBox(height: 6),
      Text(_task.milestoneProgress, style: TextStyle(color: c.ink)),
    ],
  );

  Widget _projects(FocusPalette c) => _contentScroll(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _eyebrow('YOUR PROJECTS', c),
      const SizedBox(height: 15),
      Text('Switch without losing context.', style: TextStyle(
        fontSize: 28, fontWeight: FontWeight.w700, color: c.ink,
      )),
      const SizedBox(height: 12),
      Text('Choose a sample project to resume its next step.',
        style: TextStyle(color: c.muted)),
      const SizedBox(height: 24),
      for (var i = 0; i < demoTasks.length; i++) ...[
        _projectTile(i, c),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 12),
      Text('Demo selections and notes are session-only and reset on restart.',
        style: TextStyle(color: c.muted, fontSize: 12)),
    ],
  ));
}
