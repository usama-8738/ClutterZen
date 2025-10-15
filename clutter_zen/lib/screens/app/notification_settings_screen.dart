import 'package:flutter/material.dart';
import '../../backend/registry.dart';
import '../../backend/interfaces/local_store.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late final ILocalStore _store;

  bool _push = true;
  bool _email = false;
  bool _tips = true;
  bool _loading = true;

  static const _kPush = 'notif_push_enabled';
  static const _kEmail = 'notif_email_enabled';
  static const _kTips = 'notif_tips_enabled';

  @override
  void initState() {
    super.initState();
    _store = BackendRegistry.localStore();
    _load();
  }

  Future<void> _load() async {
    final push = await _store.getBool(_kPush);
    final email = await _store.getBool(_kEmail);
    final tips = await _store.getBool(_kTips);
    if (!mounted) return;
    setState(() {
      _push = push ?? _push;
      _email = email ?? _email;
      _tips = tips ?? _tips;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [const Icon(Icons.notifications_active_outlined), const SizedBox(width: 8), Expanded(child: Text('Stay updated with decluttering tips and scan results', style: Theme.of(context).textTheme.bodyMedium))]),
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive updates on your device'),
                    value: _push,
                    onChanged: (v) async {
                      setState(() => _push = v);
                      await _store.setBool(_kPush, v);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: SwitchListTile(
                    title: const Text('Email Updates'),
                    subtitle: const Text('Get summaries via email'),
                    value: _email,
                    onChanged: (v) async {
                      setState(() => _email = v);
                      await _store.setBool(_kEmail, v);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: SwitchListTile(
                    title: const Text('Tips & Tricks'),
                    subtitle: const Text('Weekly organization tips'),
                    value: _tips,
                    onChanged: (v) async {
                      setState(() => _tips = v);
                      await _store.setBool(_kTips, v);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}


