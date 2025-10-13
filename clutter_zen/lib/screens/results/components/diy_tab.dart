import 'package:flutter/material.dart';

class DIYTab extends StatelessWidget {
  const DIYTab({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = <String>[
      'Group similar items together',
      'Clear surfaces first',
      'Use bins and labels',
      'Create zones by category',
    ];
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [const Icon(Icons.handyman, size: 32), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Free Organization Plan'), Text('Time: ~30 minutes  •  Difficulty: Easy')])]),
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < steps.length; i++)
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(steps[i]),
              trailing: const Icon(Icons.check_box_outline_blank),
            ),
          ),
        const SizedBox(height: 8),
        Row(children: [OutlinedButton(onPressed: () {}, child: const Text('Save Plan')), const SizedBox(width: 8), ElevatedButton(onPressed: () {}, child: const Text('Share'))]),
      ],
    );
  }
}


