import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../auth/chatgpt_session.dart';
import '../auth/platform_actions.dart';
import '../auth/protocol.dart';
import '../storage/chatgpt_credential_store.dart';

class Stage2Page extends StatefulWidget {
  const Stage2Page({super.key, this.session});
  final ChatGptSession? session;
  @override
  State<Stage2Page> createState() => _Stage2PageState();
}

class _Stage2PageState extends State<Stage2Page> {
  late final ChatGptSession _session = widget.session ?? ChatGptSession();
  final _draft = TextEditingController();
  final _history = <Map<String, dynamic>>[];
  final _turns = <String>[];
  ScreenshotAttachment? _image;
  String? _model;
  String _status = 'Sign in to check ChatGPT plan permission.';
  String _partial = '';
  bool _busy = false;
  bool _signingIn = false;
  bool _sending = false;
  bool _ready = false;
  int _sendGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }
  Future<void> _load() async {
    await _run(() async {
      await _session.load();
      _ready = true;
    });
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() => _busy = true);
    try { await operation(); }
    catch (error) {
      if (mounted) {
        _status = switch (error) {
          ConnectionFailure e => '${e.message}'
              '${e.status == null ? '' : ' HTTP ${e.status}.'}'
              '${e.code == null ? '' : ' Code: ${e.code}.'}'
              '${e.requestId == null ? '' : ' Request: ${e.requestId}.'}',
          CredentialStorageException e => e.toString(),
          _ => 'The operation could not finish. Check your connection and try again.',
        };
      }
    } finally { if (mounted) setState(() { _busy = false; _signingIn = false; _sending = false; }); }
  }

  void _clearConversation() {
    _sendGeneration++;
    _session.transport.cancelInference();
    _history.clear(); _turns.clear(); _partial = ''; _image = null; _draft.clear();
  }

  Future<void> _signIn() => _run(() async {
    _signingIn = true;
    setState(() => _status = 'Finish sign-in in your browser, then return here.');
    await _session.signIn(openSystemBrowser);
    _clearConversation(); _model = null;
    if (!_session.planEnabled) {
      _status = 'Signed in. ChatGPT plan permission was not granted. Inference is disabled.';
      return;
    }
    _status = 'ChatGPT plan permission verified. Check allowance-only settings before sending.';
    if (_session.active?['welcomed'] != true && mounted) {
      await showDialog<void>(context: context, builder: (context) => AlertDialog(
        title: const Text('You’re using your ChatGPT plan'),
        content: const Text('Eligible requests use your ChatGPT plan. Manage usage in ChatGPT settings. '
            'Keep app credit use off and set this app’s usage limit below 100% for allowance-only use.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
      ));
      await _session.acknowledgeWelcome();
    }
    await _session.discoverModels();
    _model = _session.models.first['slug'] as String;
  });

  Future<void> _send() => _run(() async {
    if (_draft.text.trim().isEmpty) return;
    if (!_session.allowanceOnlyConfirmed || _model == null) {
      throw const ConnectionFailure('Confirm allowance-only settings and select a model before sending.');
    }
    if (_image != null) {
      final accepted = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: const Text('Send this screenshot to OpenAI?'),
        content: const Text('The selected image and this conversation will be sent for analysis. '
            'Remove private information first. Image support depends on the selected model.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send screenshot'))],
      ));
      if (accepted != true || !mounted) return;
    }
    _sending = true;
    final generation = ++_sendGeneration;
    final prompt = _draft.text.trim();
    final message = <String, dynamic>{'role': 'user', 'content': [
      {'type': 'input_text', 'text': prompt},
      if (_image != null) {'type': 'input_image',
        'image_url': 'data:${_image!.mime};base64,${base64Encode(_image!.bytes)}'},
    ]};
    var output = '';
    setState(() { _status = 'Receiving response…'; _partial = ''; });
    try {
      await for (final delta in _session.infer(_model!, [..._history, message])) {
        if (!mounted || generation != _sendGeneration) return;
        output += delta;
        setState(() => _partial = output);
      }
      if (!mounted || generation != _sendGeneration) return;
      // infer() returns normally only after a verified response.completed event.
      _history.addAll([message, {'role': 'assistant', 'content': output}]);
      _turns.addAll(['You: $prompt${_image == null ? '' : ' [screenshot]'}', 'ChatGPT: $output']);
      _draft.clear(); _image = null; _partial = '';
      _status = 'Response completed using ChatGPT plan permission. Check usage attribution in ChatGPT.';
    } catch (_) {
      if (generation == _sendGeneration) _partial = '';
      rethrow;
    }
  });

  @override
  void dispose() {
    _sendGeneration++;
    _session.dispose(); _draft.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ChatGPT authentication proof of concept')),
    body: SafeArea(child: Align(alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: ListView(
        padding: const EdgeInsets.all(20), children: [
          const Text('Stage 2 · isolated connection test', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('ChatGPT subscription allowance only. No API keys or paid fallback. '
              'Conversations stay in memory. Only Send transfers your conversation to OpenAI.'),
          const SizedBox(height: 16),
          Text(_status, key: const Key('connection-status')),
          if (_busy) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(_session.active?['client_id']),
            initialValue: _session.active?['client_id'] as String?,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'ChatGPT account / registration'),
            items: [const DropdownMenuItem(value: '', child: Text('Add another account or workspace')),
              for (final a in _session.accounts) DropdownMenuItem(value: a['client_id'] as String,
                child: Text('${a['email'] ?? 'ChatGPT account'} · ${a['client_id']}', overflow: TextOverflow.ellipsis))],
            onChanged: _busy || !_ready ? null : (value) => setState(() {
              _clearConversation(); _model = null;
              _session.select(value == '' ? null : value);
              _status = 'Selected registration. Reconnect or load its models.';
            }),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _busy || !_ready ? null : _signIn,
            child: const Text('Continue with ChatGPT')),
          if (_signingIn) TextButton(onPressed: _session.cancelSignIn, child: const Text('Cancel sign-in')),
          if (_session.active != null) TextButton(onPressed: _busy ? null : () => _run(() async {
            _clearConversation(); _model = null;
            final revoked = await _session.signOut();
            _status = revoked ? 'Signed out. Registration retained for next sign-in.'
                : 'Signed out locally. Remote revocation was not confirmed. Disconnect this app in ChatGPT Settings.';
          }), child: const Text('Sign out')),
          const Divider(height: 32),
          const Text('Before sending: in ChatGPT Settings → Usage, keep apps’ credit use OFF '
              'and save this app’s usage limit below 100%. A lower limit prevents credit use. '
              'This app cannot inspect or change those settings.'),
          TextButton(onPressed: _busy ? null : () => _run(() => openSystemBrowser(Uri.parse('https://chatgpt.com/settings/usage'))),
            child: const Text('Manage usage')),
          CheckboxListTile(contentPadding: EdgeInsets.zero,
            title: const Text('I checked credit use is off and this app’s saved limit is below 100%.'),
            value: _session.allowanceOnlyConfirmed,
            onChanged: _busy || !_session.planEnabled ? null : (value) => setState(() => _session.allowanceOnlyConfirmed = value ?? false)),
          TextButton(onPressed: _busy || !_session.planEnabled ? null : () => _run(() async {
            _model = null;
            await _session.discoverModels();
            _model = _session.models.first['slug'] as String;
            _status = 'Account models loaded. Using ChatGPT plan permission.';
          }), child: const Text('Refresh models')),
          if (_session.models.isNotEmpty) DropdownButtonFormField<String>(
            key: ValueKey('model-$_model'), initialValue: _model, isExpanded: true,
            decoration: const InputDecoration(labelText: 'Model · using ChatGPT plan'),
            items: [for (final m in _session.models) DropdownMenuItem(value: m['slug'] as String,
              child: Text(m['display_name'] as String, overflow: TextOverflow.ellipsis))],
            onChanged: _busy ? null : (value) => setState(() => _model = value)),
          const SizedBox(height: 20),
          for (final turn in _turns) Padding(padding: const EdgeInsets.only(bottom: 16), child: SelectableText(turn)),
          if (_partial.isNotEmpty) SelectableText('Receiving (not completed): $_partial'),
          TextField(key: const Key('local-draft'), controller: _draft, minLines: 3, maxLines: 8,
            enabled: !_sending, decoration: const InputDecoration(labelText: 'Local draft',
              helperText: 'Sent only when you choose Send. Kept in memory.', helperMaxLines: 2, border: OutlineInputBorder())),
          const SizedBox(height: 12),
          if (_image != null) ...[
            const Text('Selected screenshot · review before sending'),
            Image.memory(_image!.bytes, height: 160, errorBuilder: (_, _, _) => const Text('Image preview unavailable. Remove this image.')),
            TextButton(onPressed: _busy ? null : () => setState(() => _image = null), child: const Text('Remove screenshot')),
          ],
          Wrap(spacing: 12, runSpacing: 8, children: [
            OutlinedButton(onPressed: _busy || !Platform.isAndroid ? null : () => _run(() async {
              final attachment = await selectScreenshot();
              if (mounted) _image = attachment;
            }), child: const Text('Attach screenshot')),
            FilledButton(onPressed: _busy || !_session.planEnabled || !_session.allowanceOnlyConfirmed || _model == null
              ? null : _send, child: const Text('Send')),
            TextButton(onPressed: _signingIn ? null : () => setState(() {
              _clearConversation(); _status = 'Conversation and local draft cleared.';
            }), child: const Text('Clear conversation')),
          ]),
          if (_sending) TextButton(onPressed: () => setState(() {
            _clearConversation(); _status = 'Request stopped. Unfinished output was discarded.';
          }), child: const Text('Stop request')),
          const SizedBox(height: 12),
          const Text('Image analysis requires a model that accepts images. This test screen does not read task data. '
              'Close or clear the conversation to remove it from memory.'),
        ],
      )),
    )),
  );
}
