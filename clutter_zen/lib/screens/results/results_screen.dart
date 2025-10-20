import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/vision_models.dart';
import '../../widgets/detection_overlay.dart';
import '../../widgets/organization_zones_overlay.dart';
import 'components/before_after_slider.dart';
import 'components/diy_tab.dart';
import 'components/shop_tab.dart';
import 'components/professional_tab.dart';
import '../../services/replicate_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/analysis_repository.dart';
import '../../env.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.image, required this.analysis, this.organizedUrl});

  final ImageProvider image;
  final VisionAnalysis analysis;
  final String? organizedUrl;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool _showDetections = true;
  bool _showZones = false;
  String? _replicateAfterUrl;
  String? _savedDocId;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _replicateAfterUrl = widget.organizedUrl;
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clutter = _computeClutterScore(widget.analysis.objects.length, widget.analysis.labels);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.share('Check out my decluttering results!'),
          ),
          IconButton(icon: const Icon(Icons.save_outlined), onPressed: () => _saveAnalysis()),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Image + overlay toggle
          Container(
            height: 280,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _showZones
                        ? OrganizationZonesOverlay(analysis: widget.analysis, child: Image(image: widget.image, fit: BoxFit.contain))
                        : (_showDetections ? DetectionOverlay(image: widget.image, objects: widget.analysis.objects) : Image(image: widget.image, fit: BoxFit.contain)),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Text('Detections'),
                        Switch(value: _showDetections, onChanged: (v) => setState(() => _showDetections = v)),
                      ]),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Text('Zones'),
                        Switch(value: _showZones, onChanged: (v) => setState(() => _showZones = v)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Analysis summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _StatTile(label: 'Clutter Score', value: '${clutter.toStringAsFixed(1)}/10', bar: clutter / 10)),
                      Expanded(child: _StatTile(label: 'Items Detected', value: '${widget.analysis.objects.length}')),
                      Expanded(child: _StatTile(label: 'Top Label', value: widget.analysis.labels.isNotEmpty ? widget.analysis.labels.first : '—')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: -8,
                    children: widget.analysis.labels.take(12).map((l) => Chip(label: Text(l))).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Before/After section
          if (widget.image is NetworkImage && _replicateAfterUrl != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text('Before and After'),
                const SizedBox(height: 8),
                BeforeAfterSlider(before: widget.image, after: NetworkImage(_replicateAfterUrl!)),
                const SizedBox(height: 8),
              ],
            ),
          // Tabs
          Container(
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tab,
              indicator: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(12)),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black54,
              tabs: const [Tab(text: 'DIY Solution'), Tab(text: 'Shop Smart'), Tab(text: 'Professional')],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 420,
            child: TabBarView(
              controller: _tab,
              children: [
                DIYTab(analysis: widget.analysis),
                ShopTab(analysis: widget.analysis),
                const ProfessionalTab(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Actions
          if (Env.replicateToken.isEmpty)
            const Text('Replicate token missing. Showing analysis without organized preview.'),
          if (Env.replicateToken.isNotEmpty)
            _ReplicateAction(
              image: widget.image,
              initialDocId: _savedDocId,
              onAfter: (url) => setState(() => _replicateAfterUrl = url),
            ),
          const SizedBox(height: 8),
          _SaveButton(
            image: widget.image,
            analysis: widget.analysis,
            organizedUrl: _replicateAfterUrl,
            onSaved: (id) => setState(() => _savedDocId = id),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
            child: const Text('Try Another Photo'),
          ),
        ],
      ),
    );
  }

  double _computeClutterScore(int objectCount, List<String> labels) {
    double score = 5.0;
    if (objectCount < 5) score = 2.0; else if (objectCount < 10) score = 3.5; else if (objectCount < 15) score = 5.0; else if (objectCount < 25) score = 6.5; else if (objectCount < 35) score = 8.0; else score = 9.5;
    for (final l in labels) {
      final lower = l.toLowerCase();
      if (lower.contains('messy') || lower.contains('clutter') || lower.contains('disorganized') || lower.contains('pile') || lower.contains('scattered')) score += 1.5;
      if (lower.contains('organized') || lower.contains('tidy') || lower.contains('clean') || lower.contains('minimal') || lower.contains('neat')) score -= 1.5;
    }
    if (score < 1.0) score = 1.0; if (score > 10.0) score = 10.0; return score;
  }

  Future<void> _saveAnalysis() async {
    if (widget.image is! NetworkImage) return;
    final url = (widget.image as NetworkImage).url;
    final repo = AnalysisRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
    final id = await repo.saveAnalysisAndReturnId(
      imageUrl: url,
      analysis: widget.analysis,
      organizedImageUrl: _replicateAfterUrl,
    );
    setState(() => _savedDocId = id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved analysis')));
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.bar});
  final String label;
  final String value;
  final double? bar;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
        if (bar != null) Padding(padding: const EdgeInsets.only(top: 6), child: LinearProgressIndicator(value: bar, minHeight: 6)),
      ],
    );
  }
}

class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.image, required this.analysis, this.organizedUrl, this.onSaved});

  final ImageProvider image;
  final VisionAnalysis analysis;
  final String? organizedUrl;
  final void Function(String docId)? onSaved;

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
      final id = await repo.saveAnalysisAndReturnId(imageUrl: url, analysis: widget.analysis, organizedImageUrl: widget.organizedUrl);
      if (widget.onSaved != null) widget.onSaved!(id);
      setState(() { _msg = 'Saved.'; });
    } catch (e) {
      setState(() { _msg = 'Failed: $e'; });
    } finally {
      setState(() { _saving = false; });
    }
  }
}

class _ReplicateAction extends StatefulWidget {
  const _ReplicateAction({required this.image, this.onAfter, this.initialDocId});

  final ImageProvider image;
  final void Function(String url)? onAfter;
  final String? initialDocId;

  @override
  State<_ReplicateAction> createState() => _ReplicateActionState();
}

class _ReplicateActionState extends State<_ReplicateAction> {
  bool _loading = false;
  String? _afterUrl;
  String? _error;
  String? _analysisDocId;

  @override
  void initState() {
    super.initState();
    _analysisDocId = widget.initialDocId;
  }

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
      if (after != null && widget.onAfter != null) widget.onAfter!(after);
      // Optionally save/update analysis with organized image URL if a prior save exists
      try {
        final repo = AnalysisRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
        if (_analysisDocId == null) {
          // Try to find the latest analysis for this image and user, then update
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            final q = await FirebaseFirestore.instance
                .collection('analyses')
                .where('uid', isEqualTo: uid)
                .where('imageUrl', isEqualTo: url)
                .orderBy('createdAt', descending: true)
                .limit(1)
                .get();
            if (q.docs.isNotEmpty) {
              _analysisDocId = q.docs.first.id;
            }
          }
          if (_analysisDocId == null) {
            // Create a minimal record to attach the organized image
            final analysis = const VisionAnalysis(objects: [], labels: []);
            _analysisDocId = await repo.saveAnalysisAndReturnId(imageUrl: url, analysis: analysis, organizedImageUrl: after);
          } else {
            await repo.updateOrganizedImage(_analysisDocId!, after);
          }
        } else {
          await repo.updateOrganizedImage(_analysisDocId!, after);
        }
      } catch (_) {
        // Non-fatal: do not block UI if Firestore write fails
      }
    } catch (e) {
      setState(() => _error = 'Failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }
}


