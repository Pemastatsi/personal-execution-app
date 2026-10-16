import 'package:flutter/material.dart';
import '../design.dart';
import '../model.dart';

enum VisualDirection { precision, atmospheric, editorial }

/// Presentation tokens only. All task state stays in the existing model.
class VisualPalette {
  final VisualDirection direction;
  final bool dark;
  const VisualPalette(this.direction, this.dark);
  bool get a => direction == VisualDirection.precision;
  bool get b => direction == VisualDirection.atmospheric;
  bool get c => direction == VisualDirection.editorial;
  Color get paper => Color(
    a
        ? (dark ? 0xFF10181C : 0xFFF3F5F4)
        : b
        ? (dark ? 0xFF101F2B : 0xFFF0F5F3)
        : (dark ? 0xFF211F1C : 0xFFF7F3EB),
  );
  Color get surface => Color(
    a
        ? (dark ? 0xFF1B272D : 0xFFFFFFFF)
        : b
        ? (dark ? 0xFF203541 : 0xFFFCFEFD)
        : (dark ? 0xFF2B2823 : 0xFFFFFCF6),
  );
  Color get ink => Color(
    dark
        ? 0xFFF3F5EE
        : a
        ? 0xFF142C35
        : b
        ? 0xFF143D46
        : 0xFF302D27,
  );
  Color get muted => Color(
    dark
        ? (c ? 0xFFC6BCAD : 0xFFB7C5C7)
        : a
        ? 0xFF52656B
        : b
        ? 0xFF50696D
        : 0xFF71675C,
  );
  Color get accent => Color(
    a
        ? (dark ? 0xFFBDE9AE : 0xFF286347)
        : b
        ? (dark ? 0xFFA8E3D2 : 0xFF256858)
        : (dark ? 0xFFE3B390 : 0xFF8C472E),
  );
  Color get line => Color(
    a
        ? (dark ? 0xFF415157 : 0xFFCCD6D6)
        : b
        ? (dark ? 0xFF415B64 : 0xFFCBDDD9)
        : (dark ? 0xFF575149 : 0xFFD9D0C2),
  );
  Color get tint => Color(
    a
        ? (dark ? 0xFF273D33 : 0xFFE3EBDD)
        : b
        ? (dark ? 0xFF274A4C : 0xFFDDEDE5)
        : (dark ? 0xFF3D3027 : 0xFFEDE3D4),
  );
  Color get button => a
      ? ink
      : b
      ? Color(dark ? 0xFFB4E2CF : 0xFF1E554B)
      : ink;
  Color get onButton => dark ? paper : const Color(0xFFFAFCF7);
  String get heading => a
      ? 'SpaceGrotesk'
      : b
      ? 'Manrope'
      : 'Newsreader';
  double get radius => a
      ? 12
      : b
      ? 30
      : 2;
}

ThemeData visualTheme(VisualDirection direction, bool dark) {
  final p = VisualPalette(direction, dark);
  final base = astraTheme(dark);
  return base.copyWith(
    scaffoldBackgroundColor: p.paper,
    colorScheme: base.colorScheme.copyWith(
      primary: p.accent,
      onPrimary: p.paper,
      surface: p.paper,
      onSurface: p.ink,
      outline: p.line,
    ),
    textTheme: base.textTheme.apply(bodyColor: p.ink, displayColor: p.ink),
    dividerTheme: DividerThemeData(color: p.line, space: 1),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: p.ink,
        minimumSize: const Size(48, 48),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: base.textButtonTheme.style!.copyWith(
        foregroundColor: WidgetStatePropertyAll(p.ink),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.paper,
      showDragHandle: true,
    ),
  );
}

class ConceptScreen extends StatelessWidget {
  final ExecutionModel model;
  final VisualDirection direction;
  const ConceptScreen({
    super.key,
    required this.model,
    required this.direction,
  });
  VisualPalette get p => VisualPalette(direction, model.dark);
  WorkTask get t => model.selected;
  bool get focus => model.page == AppPage.focus;
  Widget gap(double h) => SizedBox(height: h);
  Widget label(String text, {Color? color}) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontFamily: p.a ? 'SpaceGrotesk' : 'Manrope',
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: p.c ? 2 : 1.2,
      height: 1.5,
      color: color ?? p.muted,
    ),
  );
  Widget body(
    String text, {
    double size = 15,
    Color? color,
    FontWeight weight = FontWeight.w400,
  }) => Text(
    text,
    style: TextStyle(
      fontSize: size,
      height: 1.5,
      fontWeight: weight,
      color: color ?? p.muted,
    ),
  );
  Widget heading(String text, {double size = 32, Color? color}) => Text(
    text,
    style: TextStyle(
      fontFamily: p.heading,
      fontSize: size,
      height: p.c ? 1.08 : 1.13,
      letterSpacing: p.c ? -.6 : -1.1,
      fontWeight: p.c ? FontWeight.w400 : FontWeight.w600,
      color: color ?? p.ink,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.paper,
        gradient: p.b
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0, .42, 1],
                colors: model.dark
                    ? const [
                        Color(0xFF284951),
                        Color(0xFF162E3A),
                        Color(0xFF101C29),
                      ]
                    : const [
                        Color(0xFFD9EBE6),
                        Color(0xFFF3F7F3),
                        Color(0xFFE6E7F0),
                      ],
              )
            : null,
      ),
      child: Column(
        children: [
          _header(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(24, 6, 24, p.c ? 12 : 20),
              children: [
                if (p.c) ...[
                  label(t.category),
                  gap(6),
                  heading(t.title, size: 27),
                  gap(15),
                  _tabs(),
                  gap(26),
                ] else ...[
                  body(
                    t.title,
                    size: 16,
                    color: p.ink,
                    weight: FontWeight.w600,
                  ),
                  gap(p.b ? 18 : 12),
                  _tabs(),
                  gap(p.b ? 22 : 20),
                ],
                if (focus)
                  ..._focusContent(context)
                else if (model.milestoneView)
                  ..._milestoneContent()
                else
                  ..._roadmapContent(context),
              ],
            ),
          ),
          _footer(context),
        ],
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Back to today',
          onPressed: () => model.go(AppPage.home),
          icon: const Icon(Icons.arrow_back_rounded, size: 21),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: p.c
                  ? heading('astra', size: 28)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StarMark(size: 18, color: p.accent),
                        const SizedBox(width: 8),
                        Text(
                          'astra',
                          style: TextStyle(
                            fontFamily: p.heading,
                            fontSize: 23,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1,
                            color: p.ink,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        TextButton(
          key: const Key('switch-task'),
          onPressed: () => model.go(AppPage.recovery),
          child: const Text('Switch task', style: TextStyle(fontSize: 13)),
        ),
        IconButton(
          key: const Key('concept-theme'),
          tooltip: model.dark ? 'Use light theme' : 'Use dark theme',
          onPressed: model.toggleTheme,
          icon: Icon(
            model.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 19,
          ),
        ),
      ],
    ),
  );

  Widget _tabs() {
    final selected = focus
        ? 0
        : model.milestoneView
        ? 1
        : 2;
    return Container(
      padding: EdgeInsets.all(p.b ? 5 : 0),
      decoration: BoxDecoration(
        color: p.b ? p.paper.withValues(alpha: .65) : null,
        borderRadius: BorderRadius.circular(30),
        border: p.b ? Border.all(color: p.line) : null,
      ),
      child: Row(
        children: List.generate(3, (i) {
          final active = selected == i;
          return Expanded(
            child: Semantics(
              selected: active,
              child: Container(
                decoration: BoxDecoration(
                  border: !p.b
                      ? Border(
                          bottom: BorderSide(
                            color: active ? p.ink : p.line,
                            width: active ? 2 : 1,
                          ),
                        )
                      : null,
                ),
                child: TextButton(
                  key: Key('concept-tab-$i'),
                  onPressed: () => i == 0
                      ? model.resume(t)
                      : model.openRoadmap(milestone: i == 1),
                  style: TextButton.styleFrom(
                    backgroundColor: active && p.b ? p.surface : null,
                    foregroundColor: active ? p.ink : p.muted,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    ['Focus', 'Milestone', 'Roadmap'][i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _segments({double height = 5}) => Semantics(
    label: '${t.verified} of ${t.milestones.length} outcomes verified',
    child: Row(
      children: List.generate(
        t.milestones.length,
        (i) => Expanded(
          child: Container(
            height: height,
            margin: EdgeInsets.only(
              right: i == t.milestones.length - 1
                  ? 0
                  : p.c
                  ? 7
                  : 4,
            ),
            decoration: BoxDecoration(
              color: i < t.verified ? p.accent : p.line,
              borderRadius: BorderRadius.circular(p.b ? 20 : 0),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _milestoneContext() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 35,
        height: 35,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.tint,
          borderRadius: BorderRadius.circular(p.b ? 18 : 6),
        ),
        child: Text(
          '${(t.verified + 1).clamp(1, t.milestones.length)}'.padLeft(2, '0'),
          style: TextStyle(
            fontFamily: p.a ? 'SpaceGrotesk' : 'Manrope',
            color: p.accent,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label(t.finished ? 'Verified outcome' : 'Current milestone'),
            gap(4),
            body(
              t.milestone.title,
              size: 15,
              color: p.ink,
              weight: FontWeight.w600,
            ),
          ],
        ),
      ),
    ],
  );

  List<Widget> _focusContent(BuildContext context) {
    final title = t.finished
        ? 'This is a real step forward.'
        : t.awaitingVerification
        ? 'Does the result match?'
        : t.nextAction;
    final instruction = t.finished || t.awaitingVerification
        ? t.milestone.evidence
        : t.instruction();
    final kicker = t.finished
        ? 'Outcome achieved'
        : t.awaitingVerification
        ? 'One final check'
        : 'Just this next action';
    final stateNote = t.awaitingVerification
        ? body(
            'Only you can confirm this outcome. Finishing instructions alone doesn’t verify it.',
          )
        : null;
    if (p.a) {
      return [
        Row(
          children: [
            Expanded(child: label('Verified outcomes')),
            const SizedBox(width: 8),
            Text(
              '${t.verified.toString().padLeft(2, '0')} / ${t.milestones.length.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: p.accent,
              ),
            ),
          ],
        ),
        gap(10),
        _segments(height: 4),
        gap(22),
        Container(
          padding: const EdgeInsets.all(23),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: model.dark ? .1 : .025),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 6, height: 6, color: p.accent),
                  const SizedBox(width: 8),
                  Expanded(child: label(kicker, color: p.accent)),
                ],
              ),
              gap(17),
              heading(title, size: 34),
              gap(18),
              body(instruction, size: 16),
              if (stateNote != null) ...[gap(16), stateNote],
              if (!t.finished && !t.awaitingVerification) ...[
                gap(18),
                _detailControl(context),
              ],
            ],
          ),
        ),
        gap(22),
        _milestoneContext(),
      ];
    }
    if (p.b) {
      return [
        gap(7),
        Center(child: label(kicker, color: p.accent)),
        gap(18),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: .9,
              colors: [
                p.accent.withValues(alpha: model.dark ? .07 : .025),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 34,
              height: 1.15,
              letterSpacing: -1.2,
              fontWeight: FontWeight.w600,
              color: p.ink,
            ),
          ),
        ),
        gap(25),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: model.dark
                  ? const [Color(0xFF304D58), Color(0xFF223540)]
                  : const [Color(0xFFFFFFFF), Color(0xFFF1F7F2)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: model.dark ? const Color(0xFF5B747B) : Colors.white,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF0C2E3B,
                ).withValues(alpha: model.dark ? .2 : .08),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              body(instruction, size: 16),
              if (stateNote != null) ...[gap(16), stateNote],
              if (!t.finished && !t.awaitingVerification) ...[
                gap(18),
                _detailControl(context),
              ],
            ],
          ),
        ),
        gap(28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SizedBox(
                width: 43,
                height: 43,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: t.verified / t.milestones.length,
                        strokeWidth: 3,
                        color: p.accent,
                        backgroundColor: p.line,
                        strokeCap: StrokeCap.round,
                        semanticsLabel:
                            '${t.verified} of ${t.milestones.length} outcomes verified',
                      ),
                    ),
                    Text(
                      '${t.verified}/${t.milestones.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: p.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  label(t.finished ? 'Verified outcome' : 'Current milestone'),
                  gap(5),
                  body(
                    t.milestone.title,
                    size: 15,
                    color: p.ink,
                    weight: FontWeight.w600,
                  ),
                  gap(8),
                  body(
                    '${t.verified} of ${t.milestones.length} outcomes verified',
                    size: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ];
    }
    return [
      Row(
        children: [
          Expanded(child: label(kicker, color: p.accent)),
          const SizedBox(width: 8),
          Text(
            '—  ${(t.actionIndex + 1).toString().padLeft(2, '0')}',
            style: TextStyle(
              fontFamily: 'Newsreader',
              fontSize: 22,
              color: p.accent,
            ),
          ),
        ],
      ),
      gap(17),
      heading(title, size: 42),
      gap(23),
      Container(
        padding: const EdgeInsets.only(left: 17),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: p.line, width: 2)),
        ),
        child: body(instruction, size: 16),
      ),
      if (stateNote != null) ...[gap(16), stateNote],
      if (!t.finished && !t.awaitingVerification) ...[
        gap(16),
        _detailControl(context),
      ],
      gap(24),
      const Divider(),
      gap(18),
      label(t.finished ? 'Verified outcome' : 'Current milestone'),
      gap(6),
      body(t.milestone.title, size: 16, color: p.ink, weight: FontWeight.w500),
      gap(18),
      _segments(height: 2),
      gap(8),
      body(
        '${t.verified} of ${t.milestones.length} outcomes verified',
        size: 12,
      ),
    ];
  }

  Widget _detailControl(BuildContext context) => Semantics(
    label: 'Instruction detail',
    child: Row(
      children: [
        Icon(Icons.tune_rounded, size: 16, color: p.muted),
        const SizedBox(width: 8),
        Expanded(child: body('Detail', size: 12)),
        PopupMenuButton<Detail>(
          key: const Key('instruction-detail'),
          tooltip: 'Change instruction detail',
          initialValue: t.detail,
          onSelected: model.setDetail,
          itemBuilder: (_) => List.generate(
            3,
            (i) => PopupMenuItem(
              value: Detail.values[i],
              child: Text(['Micro', 'Normal', 'High-level'][i]),
            ),
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 112),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: p.line),
              borderRadius: BorderRadius.circular(
                p.b
                    ? 24
                    : p.a
                    ? 7
                    : 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                body(
                  ['Micro', 'Normal', 'High-level'][t.detail.index],
                  size: 13,
                  color: p.ink,
                ),
                const SizedBox(width: 10),
                Icon(Icons.expand_more_rounded, color: p.ink, size: 18),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  List<Widget> _roadmapContent(BuildContext context) {
    if (p.a) {
      return [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            heading('${t.verified}'.padLeft(2, '0'), size: 64),
            Padding(
              padding: const EdgeInsets.only(bottom: 9, left: 8),
              child: body(
                '/ ${t.milestones.length.toString().padLeft(2, '0')}',
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    label('Outcomes verified', color: p.accent),
                    body(
                      '${t.milestones.length - t.verified} still ahead',
                      size: 13,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        gap(12),
        _segments(height: 7),
        gap(25),
        label('Your path to done'),
        gap(12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: p.line),
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: List.generate(
              t.milestones.length,
              (i) => _precisionRow(context, i),
            ),
          ),
        ),
        gap(14),
        body(
          'Future milestones stay high-level. We’ll work out the actions when you get there.',
          size: 12,
        ),
      ];
    }
    if (p.b) {
      return [
        heading('A little closer.', size: 30),
        gap(8),
        body(
          '${t.verified} of ${t.milestones.length} outcomes verified',
          size: 14,
        ),
        gap(20),
        _journey(),
        gap(24),
        ...List.generate(
          t.milestones.length,
          (i) => _atmosphericRow(context, i),
        ),
        gap(10),
        body(
          'Future milestones stay high-level. We’ll work out the actions when you get there.',
          size: 12,
        ),
      ];
    }
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          heading('${t.verified}/${t.milestones.length}', size: 67),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label('Outcomes verified', color: p.accent),
                gap(4),
                body(
                  '${t.milestones.length - t.verified} still ahead',
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
      gap(16),
      const Divider(),
      ...List.generate(t.milestones.length, (i) => _editorialRow(context, i)),
      gap(16),
      body(
        'Future milestones stay high-level. We’ll work out the actions when you get there.',
        size: 12,
      ),
    ];
  }

  Widget _precisionRow(BuildContext context, int i) {
    final current = i == t.verified, done = i < t.verified;
    final fg = current ? p.onButton : p.ink;
    return Material(
      color: current ? p.button : p.surface,
      child: InkWell(
        onTap: () => _inspect(context, i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
          decoration: BoxDecoration(
            border: i == t.milestones.length - 1
                ? null
                : Border(
                    bottom: BorderSide(color: current ? p.button : p.line),
                  ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 32,
                child: done
                    ? Icon(
                        Icons.check_circle_outline_rounded,
                        color: p.accent,
                        size: 21,
                      )
                    : Text(
                        '${i + 1}'.padLeft(2, '0'),
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 18,
                          color: fg,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    body(
                      t.milestones[i].title,
                      size: 15,
                      color: fg,
                      weight: FontWeight.w600,
                    ),
                    gap(3),
                    Text(
                      done
                          ? 'Verified by you · View evidence'
                          : current
                          ? 'CURRENT MILESTONE'
                          : 'Ahead',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        letterSpacing: current ? .8 : 0,
                        color: current ? fg : p.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                current
                    ? Icons.arrow_forward_rounded
                    : Icons.chevron_right_rounded,
                size: 19,
                color: current ? fg : p.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _journey() => Semantics(
    label:
        '${t.verified} verified outcomes, ${t.milestones.length - t.verified} remaining',
    child: Row(
      children: List.generate(t.milestones.length * 2 - 1, (j) {
        if (j.isOdd) {
          return Expanded(
            child: Container(
              height: 1,
              color: j ~/ 2 < t.verified ? p.accent : p.line,
            ),
          );
        }
        final i = j ~/ 2, done = j ~/ 2 < t.verified;
        return Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: done
                ? p.accent
                : i == t.verified
                ? p.surface
                : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: i <= t.verified ? p.accent : p.line),
          ),
          child: Center(
            child: done
                ? Icon(Icons.check_rounded, size: 18, color: p.paper)
                : Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: p.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      }),
    ),
  );

  Widget _atmosphericRow(BuildContext context, int i) {
    final current = i == t.verified, done = i < t.verified;
    if (current) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Material(
          color: p.surface,
          borderRadius: BorderRadius.circular(25),
          elevation: model.dark ? 0 : 3,
          shadowColor: const Color(0x18133340),
          child: InkWell(
            onTap: () => model.openRoadmap(milestone: true),
            borderRadius: BorderRadius.circular(25),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      label('Current milestone', color: p.accent),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: p.accent,
                        size: 19,
                      ),
                    ],
                  ),
                  gap(10),
                  heading(t.milestones[i].title, size: 25),
                  gap(12),
                  body('View the actions for this outcome', size: 12),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return InkWell(
      onTap: () => _inspect(context, i),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 11),
        child: Row(
          children: [
            Icon(
              done
                  ? Icons.check_circle_outline_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: done ? p.accent : p.muted,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  body(
                    t.milestones[i].title,
                    size: 15,
                    color: p.ink,
                    weight: FontWeight.w500,
                  ),
                  gap(2),
                  body(
                    done ? 'Verified by you · View evidence' : 'Ahead',
                    size: 11,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: p.muted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _editorialRow(BuildContext context, int i) {
    final current = i == t.verified, done = i < t.verified;
    return InkWell(
      onTap: () => _inspect(context, i),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: p.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 43,
              child: Text(
                '${i + 1}'.padLeft(2, '0'),
                style: TextStyle(
                  fontFamily: 'Newsreader',
                  fontSize: 29,
                  height: 1,
                  color: current ? p.accent : p.muted,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (current) ...[
                    label('Current milestone', color: p.accent),
                    gap(5),
                  ],
                  Text(
                    t.milestones[i].title,
                    style: TextStyle(
                      fontFamily: current ? 'Newsreader' : 'Manrope',
                      fontSize: current ? 25 : 15,
                      height: 1.25,
                      color: p.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  gap(6),
                  body(
                    done
                        ? 'Verified by you · View evidence'
                        : current
                        ? 'View the actions for this outcome'
                        : 'Ahead',
                    size: 11,
                    color: done ? p.accent : p.muted,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 9),
            Icon(
              done
                  ? Icons.check_rounded
                  : current
                  ? Icons.arrow_forward_rounded
                  : Icons.add_rounded,
              size: 18,
              color: current || done ? p.accent : p.muted,
            ),
          ],
        ),
      ),
    );
  }

  void _inspect(BuildContext context, int i) {
    if (i == t.verified && !t.finished) {
      model.openRoadmap(milestone: true);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label(
                i < t.verified ? 'Verified outcome' : 'What done looks like',
                color: p.accent,
              ),
              gap(14),
              heading(t.milestones[i].title, size: 28),
              gap(16),
              body(t.milestones[i].evidence, size: 16, color: p.ink),
              gap(16),
              body(
                i < t.verified
                    ? 'Verified by you. This outcome is part of your saved progress.'
                    : 'Future milestones stay high-level. Actions are planned when you get here.',
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _milestoneContent() => [
    label(
      t.finished ? 'Verified outcome' : 'Current milestone',
      color: p.accent,
    ),
    gap(12),
    heading(t.milestone.title, size: p.c ? 38 : 31),
    gap(22),
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.tint,
        borderRadius: BorderRadius.circular(p.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label('What done looks like', color: p.accent),
          gap(8),
          body(t.milestone.evidence, size: 16, color: p.ink),
        ],
      ),
    ),
    gap(25),
    label('Actions toward this outcome'),
    gap(10),
    ...List.generate(
      t.steps.length,
      (i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              i < t.actionIndex || t.awaitingVerification || t.finished
                  ? Icons.check_circle_outline
                  : i == t.actionIndex
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 21,
              color: p.accent,
            ),
            const SizedBox(width: 13),
            Expanded(child: body(t.steps[i].title, size: 15, color: p.ink)),
          ],
        ),
      ),
    ),
    gap(15),
    body(
      'Actions help you get there. Only a confirmed outcome changes project progress.',
      size: 13,
    ),
  ];

  Widget _footer(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(24, p.b ? 12 : 10, 24, 14),
    decoration: BoxDecoration(
      color: p.b ? p.paper.withValues(alpha: .65) : p.paper,
      border: Border(
        top: BorderSide(color: p.b ? p.line.withValues(alpha: .5) : p.line),
      ),
      borderRadius: p.b
          ? const BorderRadius.vertical(top: Radius.circular(28))
          : null,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: Key(
              !focus
                  ? 'back-to-action'
                  : t.awaitingVerification
                  ? 'verify-outcome'
                  : 'complete-action',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: p.button,
              foregroundColor: p.onButton,
              minimumSize: const Size(48, 57),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  p.b
                      ? 29
                      : p.a
                      ? 10
                      : 3,
                ),
              ),
            ),
            onPressed: () {
              if (!focus) {
                t.finished ? model.go(AppPage.home) : model.resume(t);
              } else if (t.finished) {
                model.go(AppPage.home);
              } else if (t.awaitingVerification) {
                model.verifyOutcome();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Outcome verified. Your roadmap has moved forward.',
                    ),
                  ),
                );
              } else {
                final id = t.id,
                    milestone = t.verified,
                    index = t.actionIndex,
                    blocker = t.blocker;
                model.completeAction();
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Action saved.'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () =>
                          model.undoAction(id, milestone, index, blocker),
                    ),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      !focus
                          ? t.finished
                                ? 'Back to today'
                                : 'Back to the next action'
                          : t.finished
                          ? 'Choose what’s next'
                          : t.awaitingVerification
                          ? 'Yes, verify outcome'
                          : 'Action completed',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    focus && !t.finished
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    size: 21,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (focus && !t.finished) ...[
          gap(5),
          if (t.awaitingVerification)
            TextButton(
              onPressed: model.retryOutcome,
              child: const Text('Not yet · return to the action'),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    key: const Key('stuck'),
                    onPressed: () => model.openCoach(stuck: true),
                    icon: const Icon(Icons.help_outline_rounded, size: 18),
                    label: const Text(
                      'I’m stuck',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                Container(height: 16, width: 1, color: p.line),
                Expanded(
                  child: TextButton.icon(
                    key: const Key('ask-ai'),
                    onPressed: () => model.openCoach(),
                    icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                    label: const Text('Ask AI', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
        ],
      ],
    ),
  );
}
