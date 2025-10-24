import 'package:flutter/material.dart';

import '../../app_firebase.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final TextEditingController _name = TextEditingController(
      text: AppFirebase.auth.currentUser?.displayName ?? '');
  bool _loading = false;
  String? _msg;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
              controller: _name,
              decoration: const InputDecoration(
                  hintText: 'Full Name',
                  filled: true,
                  fillColor: Color(0xFFF2F4F7),
                  border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(12))))),
          const SizedBox(height: 16),
          if (_msg != null)
            Padding(
                padding: const EdgeInsets.only(bottom: 8), child: Text(_msg!)),
          ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _msg = null;
    });
    try {
      await AppFirebase.auth.currentUser?.updateDisplayName(_name.text.trim());
      await AppFirebase.auth.currentUser?.reload();
      setState(() {
        _msg = 'Updated.';
      });
    } catch (e) {
      setState(() {
        _msg = 'Failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}
