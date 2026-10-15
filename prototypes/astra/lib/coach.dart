import 'package:flutter/material.dart';
import 'design.dart';
import 'model.dart';
import 'screens.dart' show ScreenHeader;

class CoachScreen extends StatefulWidget {
  final ExecutionModel model;
  const CoachScreen({super.key, required this.model});
  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();
  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  void send(String message, {bool screenshot = false}) {
    if (message.trim().isEmpty) {
      return;
    }
    widget.model.send(message, screenshot: screenshot);
    input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> attach() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Show me where you’re stuck.',
                  style: Theme.of(ctx).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Try this sample screenshot. Nothing is uploaded or sent anywhere.',
                ),
                const SizedBox(height: 20),
                const EditorScreenshot(),
                const SizedBox(height: 20),
                PrimaryButton(
                  'Use sample screenshot',
                  key: const Key('use-screenshot'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    send('Here’s the error I’m seeing.', screenshot: true);
                  },
                  icon: Icons.image_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model,
        t = model.selected,
        c = AstraColors.of(context),
        text = Theme.of(context).textTheme;
    return Column(
      children: [
        ScreenHeader(
          title: 'Execution coach',
          onBack: () => model.go(AppPage.focus),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Eyebrow('Demo'),
          ),
        ),
        if (MediaQuery.viewInsetsOf(context).bottom == 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const StarMark(size: 20),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'A way through, one step at a time.',
                        style: text.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Surface(
                  color: c.wash,
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.my_location_outlined,
                        size: 19,
                        color: c.accent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Eyebrow('Working on', color: c.accent),
                            const SizedBox(height: 4),
                            Text(
                              t.milestone.title,
                              style: text.titleMedium?.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            children: [
              for (final message in t.chat)
                Padding(
                  padding: const EdgeInsets.only(bottom: 21),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.fromUser)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(left: 25),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: c.surface,
                              border: Border.all(color: c.line),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (message.screenshot) ...[
                                  const EditorScreenshot(compact: true),
                                  const SizedBox(height: 12),
                                ],
                                Text(
                                  message.text,
                                  style: text.bodyLarge?.copyWith(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        Row(
                          children: [
                            const StarMark(size: 16),
                            const SizedBox(width: 8),
                            Eyebrow('Astra · next step', color: c.accent),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          message.text,
                          style: text.bodyLarge?.copyWith(
                            fontSize: 17,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (t.chat.length < 2)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () => send('I can’t find the Toolbox.'),
                    child: Text(
                      t.id == 'indicator'
                          ? 'I can’t find the Toolbox'
                          : 'Make this step smaller',
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 12),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('attach-screenshot'),
                  onPressed: attach,
                  icon: const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 20,
                  ),
                  label: const Text('Attach a screenshot'),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('coach-input'),
                      controller: input,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: send,
                      decoration: const InputDecoration(
                        hintText: 'What’s getting in the way?',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: c.accent, foregroundColor: c.onAccent),
                    tooltip: 'Send message',
                    onPressed: () => send(input.text),
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              TextButton.icon(
                onPressed: () => model.go(AppPage.focus),
                icon: const Icon(Icons.arrow_back_rounded, size: 17),
                label: const Text('Back to focus'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A deliberately fictional screenshot; no picker permission or external data.
class EditorScreenshot extends StatelessWidget {
  final bool compact;
  const EditorScreenshot({super.key, this.compact = false});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Sample MetaEditor screenshot. Error: semicolon expected, line 42.',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        color: const Color(0xFF24252F),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: const Color(0xFF343440),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              child: const Row(
                children: [
                  Icon(Icons.code_rounded, color: Color(0xFFC5B7F5), size: 15),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Momentum.mq5',
                      style: TextStyle(fontSize: 11, color: Color(0xFFE9E4F5)),
                    ),
                  ),
                  Text(
                    'SAMPLE',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.2,
                      color: Color(0xFFCDC7DD),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 12 : 16),
              child: Text(
                compact
                    ? '42   signal = close[i]'
                    : '40   if (momentum > threshold)\n41   {\n42     signal = close[i]\n43   }',
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  height: 1.7,
                  color: Color(0xFFCDC3EF),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: const Color(0xFF49343C),
              padding: const EdgeInsets.all(12),
              child: const Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 14,
                    color: Color(0xFFFFB2AE),
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '“;” expected  ·  line 42',
                      style: TextStyle(fontSize: 11, color: Color(0xFFFFC6BF)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
