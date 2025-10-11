import 'package:flutter/material.dart';
import '../../routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Clutter Zen', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: () => _showAllScreens(context),
              tooltip: 'All Screens',
              icon: const Icon(Icons.developer_board_outlined),
            )
          ],
        ),
        const SizedBox(height: 12),
        _HeroCard(
          title: 'Declutter in minutes',
          subtitle: 'Scan your space and get an AI plan',
          action: ElevatedButton(onPressed: () {}, child: const Text('Get Started')),
        ),
        const SizedBox(height: 16),
        Text('Rooms', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const _RoomsRow(),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.title, required this.subtitle, required this.action});

  final String title;
  final String subtitle;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(subtitle),
                const SizedBox(height: 10),
                action,
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.auto_awesome, size: 48),
        ],
      ),
    );
  }
}

class _RoomsRow extends StatelessWidget {
  const _RoomsRow();

  @override
  Widget build(BuildContext context) {
    final items = const [
      {'title': 'Bedroom', 'icon': Icons.bed_outlined},
      {'title': 'Kitchen', 'icon': Icons.kitchen_outlined},
      {'title': 'Office', 'icon': Icons.desktop_windows_outlined},
    ];
    return Row(
      children: [
        for (final i in items)
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Icon(i['icon'] as IconData, size: 28),
                  const SizedBox(height: 6),
                  Text(i['title'] as String),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

void _showAllScreens(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) {
      return ListView(
        children: [
          const ListTile(title: Text('All Screens (Debug)')),
          for (final s in AppRoutes.allScreens)
            ListTile(
              title: Text(s['name']!),
              subtitle: Text(s['route']!),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(s['route']!);
              },
            ),
        ],
      );
    },
  );
}


