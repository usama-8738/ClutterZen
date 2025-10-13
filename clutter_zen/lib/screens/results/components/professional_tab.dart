import 'package:flutter/material.dart';

class ProfessionalTab extends StatelessWidget {
  const ProfessionalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 6,
      itemBuilder: (_, i) => Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: const Text('Organizer Name'),
          subtitle: const Text('Home organization • 4.8★'),
          trailing: const Text('\$50/hr'),
        ),
      ),
    );
  }
}


