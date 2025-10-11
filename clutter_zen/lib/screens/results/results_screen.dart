import 'package:flutter/material.dart';

import '../../models/vision_models.dart';
import '../../widgets/detection_overlay.dart';
import '../../services/replicate_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/analysis_repository.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.image, required this.analysis});

  final ImageProvider image;
  final VisionAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 280,
            child: DetectionOverlay(image: image, objects: analysis.objects),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Items detected: ${analysis.objects.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: -8,
                    children: analysis.labels.take(12).map((l) => Chip(label: Text(l))).toList(),
                  ),
                  const SizedBox(height: 12),
                  _ReplicateAction(image: image),
                  const SizedBox(height: 8),
                  _SaveButton(image: image, analysis: analysis),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.image, required this.analysis});

  final ImageProvider image;
  final VisionAnalysis analysis;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _saving = false;
  String? _msg;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_msg != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(_msg!),
          ),
        OutlinedButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: _saving ? const Text('Saving...') : const Text('Save analysis to Firestore'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() { _saving = true; _msg = null; });
    try {
      if (widget.image is! NetworkImage) {
        setState(() { _msg = 'Upload the image to storage and analyze via URL to save.'; });
        return;
      }
      final url = (widget.image as NetworkImage).url;
      final repo = AnalysisRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
      await repo.saveAnalysis(imageUrl: url, analysis: widget.analysis);
      setState(() { _msg = 'Saved.'; });
    } catch (e) {
      setState(() { _msg = 'Failed: $e'; });
    } finally {
      setState(() { _saving = false; });
    }
  }
}

class _ReplicateAction extends StatefulWidget {
  const _ReplicateAction({required this.image});

  final ImageProvider image;

  @override
  State<_ReplicateAction> createState() => _ReplicateActionState();
}

class _ReplicateActionState extends State<_ReplicateAction> {
  bool _loading = false;
  String? _afterUrl;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_afterUrl != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Organized preview:'),
              const SizedBox(height: 8),
              SizedBox(height: 200, child: Image.network(_afterUrl!, fit: BoxFit.cover)),
            ],
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        ElevatedButton.icon(
          onPressed: _loading ? null : _generate,
          icon: const Icon(Icons.auto_fix_high_outlined),
          label: _loading ? const Text('Generating...') : const Text('Generate Organized Image (Replicate)'),
        ),
      ],
    );
  }

  Future<void> _generate() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Requires an accessible URL; if using local image, upload to storage first and pass URL.
      // For this demo, we only support NetworkImage here.
      if (widget.image is! NetworkImage) {
        setState(() => _error = 'Replicate demo needs a public image URL.');
        return;
      }
      final url = (widget.image as NetworkImage).url;
      const token = String.fromEnvironment('REPLICATE_API_TOKEN', defaultValue: '');
      if (token.isEmpty) {
        setState(() => _error = 'Missing REPLICATE_API_TOKEN.');
        return;
      }
      final service = ReplicateService(apiToken: token);
      final after = await service.generateOrganizedImage(imageUrl: url);
      setState(() => _afterUrl = after);
    } catch (e) {
      setState(() => _error = 'Failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }
}


