import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Stage 2 stops at eligibility: there is deliberately no OAuth or HTTP client.
/// Enabling inference requires an approved, documented Plus-only integration.
class Stage2Page extends StatefulWidget {
  const Stage2Page({super.key});

  @override
  State<Stage2Page> createState() => _Stage2PageState();
}

class _Stage2PageState extends State<Stage2Page> {
  final _draft = TextEditingController();

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _copyChatGptAddress() async {
    try {
      // Copy only the address, never the draft, screenshots, or account data.
      await Clipboard.setData(const ClipboardData(text: 'https://chatgpt.com/'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ChatGPT address copied.')),
      );
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open https://chatgpt.com/ in your browser.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI connection prototype')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Connect at your pace',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('ChatGPT Plus allowance only. No paid fallback.'),
                const SizedBox(height: 24),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outline),
                        SizedBox(height: 12),
                        Text(
                          'Connection awaiting eligibility confirmation',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'This app is private. OpenAI currently offers '
                          'ChatGPT plan usage to open-source partners and '
                          'selected private clients. Approval for this app '
                          'has not been confirmed.',
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Next step: obtain OpenAI confirmation that this '
                          'private app may use your existing Plus allowance.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const FilledButton(
                  onPressed: null,
                  child: Text('Continue with ChatGPT'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Available models',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Models will be discovered after a supported sign-in. '
                  'No models have been requested.',
                ),
                const SizedBox(height: 24),
                TextField(
                  key: const Key('local-draft'),
                  controller: _draft,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Local draft',
                    hintText: 'What would you like help with?',
                    helperText: 'Stays in memory until you clear or close the app.',
                    helperMaxLines: 2,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: Icon(Icons.image_outlined),
                      label: Text('Attach screenshot'),
                    ),
                    FilledButton(onPressed: null, child: Text('Send')),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sending and image analysis are unavailable until a '
                  'supported connection is ready.',
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _draft.clear,
                    child: const Text('Clear draft'),
                  ),
                ),
                const Divider(height: 32),
                const Text(
                  'You can use official ChatGPT separately and return here '
                  'manually. Nothing is transferred automatically.',
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _copyChatGptAddress,
                  child: const Text('Copy official ChatGPT address'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
