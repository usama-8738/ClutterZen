import 'package:flutter/material.dart';

import '../../../backend/registry.dart';
import '../../../models/gemini_models.dart';
import '../../../models/vision_models.dart';

class DIYTab extends StatefulWidget {
  const DIYTab({super.key, required this.analysis});

  final VisionAnalysis analysis;

  @override
  State<DIYTab> createState() => _DIYTabState();
}

class _DIYTabState extends State<DIYTab> {
  late final List<String> _fallbackInstructions;
  GeminiRecommendation? _recommendation;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fallbackInstructions = _generateSmartInstructions(widget.analysis.objects);
    _fetchGeminiRecommendations();
  }

  Future<void> _fetchGeminiRecommendations() async {
    try {
      final rec = await Registry.gemini.getRecommendations(
        detectedObjects: widget.analysis.objects.map((o) => o.name).toList(),
      );
      if (mounted) {
        setState(() {
          _recommendation = rec;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Gemini failed: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating AI Organization Plan...'),
          ],
        ),
      );
    }

    final hasGemini =
        _recommendation != null && _recommendation!.diyPlan.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.psychology, size: 32),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasGemini
                        ? 'AI-Powered Organization Plan'
                        : 'Your Custom Organization Plan',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    hasGemini
                        ? (_recommendation!.summary ??
                            'Optimized steps for your space.')
                        : 'Follow these steps to declutter your space.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            )
          ]),
        ),
        if (hasGemini)
          ..._recommendation!.diyPlan.map((step) => Card(
                child: ExpansionTile(
                  leading: CircleAvatar(
                    radius: 14,
                    child: Text('${step.stepNumber}',
                        style: const TextStyle(fontSize: 12)),
                  ),
                  title: Text(step.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step.description),
                          if (step.tips.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text('Pro Tips:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                            ...step.tips.map((tip) => Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4, left: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Expanded(
                                          child: Text(tip,
                                              style: const TextStyle(
                                                  fontSize: 12))),
                                    ],
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ))
        else
          for (final instruction in _fallbackInstructions)
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_box_outline_blank),
                title: Text(instruction),
              ),
            ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.save),
              label: const Text('Save Plan'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share),
              label: const Text('Share'),
            ),
          )
        ]),
        if (_errorMessage != null && !hasGemini)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Note: AI service unavailable, showing basic plan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ),
      ],
    );
  }

  String _categorizeObject(String objectName) {
    // This is a simplified version for instruction generation.
    final name = objectName.toLowerCase();
    if ([
      'shirt',
      'pants',
      'dress',
      'jacket',
      'coat',
      'shoe',
      'clothing',
      'jeans',
      'sweater',
      'sock',
      'tie',
      'belt',
      'hat',
      'scarf'
    ].any((item) => name.contains(item))) {
      return 'clothing';
    }
    if ([
      'book',
      'magazine',
      'newspaper',
      'paper',
      'document',
      'notebook',
      'folder',
      'binder',
      'journal'
    ].any((item) => name.contains(item))) {
      return 'books_paper';
    }
    if ([
      'computer',
      'laptop',
      'phone',
      'tablet',
      'cable',
      'charger',
      'headphones',
      'keyboard',
      'mouse',
      'monitor',
      'television',
      'remote'
    ].any((item) => name.contains(item))) {
      return 'electronics';
    }
    if ([
      'plate',
      'bowl',
      'cup',
      'mug',
      'glass',
      'fork',
      'spoon',
      'knife',
      'pot',
      'pan',
      'bottle',
      'food'
    ].any((item) => name.contains(item))) {
      return 'kitchen';
    }
    return 'miscellaneous';
  }

  List<String> _generateSmartInstructions(List<DetectedObject> objects) {
    final instructions = <String>[];
    final double clutterScore = (objects.length / 5).clamp(1.0, 10.0);

    if (clutterScore > 7) {
      instructions
          .add('High clutter detected. Let\'s tackle this step by step!');
    } else if (clutterScore > 4) {
      instructions
          .add('Moderate clutter. A quick organization session will help!');
    } else {
      instructions.add('Minimal clutter. Just a few tweaks needed!');
    }

    final categoryCounts = <String, int>{};
    for (var obj in objects) {
      final category = _categorizeObject(obj.name);
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int stepNumber = 1;
    for (var entry in sortedCategories) {
      String category = entry.key;
      int count = entry.value;

      switch (category) {
        case 'clothing':
          instructions.add(
              '${stepNumber++}. CLOTHING ($count items): Sort by type, fold or hang, and consider donating items not worn recently.');
          break;
        case 'books_paper':
          instructions.add(
              '${stepNumber++}. BOOKS & PAPERS ($count items): Stack books neatly, file loose papers, and digitize important documents.');
          break;
        case 'electronics':
          instructions.add(
              '${stepNumber++}. ELECTRONICS ($count items): Create a charging station, bundle cables with ties, and label chargers.');
          break;
        case 'kitchen':
          instructions.add(
              '${stepNumber++}. KITCHEN ITEMS ($count items): Group similar items, stack plates and bowls, and use drawer dividers for utensils.');
          break;
        default:
          if (count > 2) {
            instructions.add(
                '${stepNumber++}. MISCELLANEOUS ($count items): Find a designated home for each item and group similar things together.');
          }
      }
    }
    return instructions;
  }
}
