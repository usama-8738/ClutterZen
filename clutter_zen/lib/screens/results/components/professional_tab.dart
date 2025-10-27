import 'package:flutter/material.dart';

class ProfessionalTab extends StatelessWidget {
  const ProfessionalTab({super.key});

  static const List<_Organizer> _organizers = [
    _Organizer(
      name: 'Spark Tidy Co.',
      specialty: 'Whole-home organization',
      rating: 4.9,
      ratePerHour: 45,
    ),
    _Organizer(
      name: 'Calm Closet Pros',
      specialty: 'Closet and wardrobe systems',
      rating: 4.8,
      ratePerHour: 55,
    ),
    _Organizer(
      name: 'Desk Refresh Crew',
      specialty: 'Home office and desk makeovers',
      rating: 4.7,
      ratePerHour: 40,
    ),
    _Organizer(
      name: 'Family Space Specialists',
      specialty: 'Playrooms and shared spaces',
      rating: 4.9,
      ratePerHour: 52,
    ),
    _Organizer(
      name: 'Kitchen Flow Studio',
      specialty: 'Kitchen and pantry optimization',
      rating: 4.8,
      ratePerHour: 58,
    ),
    _Organizer(
      name: 'Garage Revival Team',
      specialty: 'Garage and storage upgrades',
      rating: 4.6,
      ratePerHour: 48,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _organizers.length,
      itemBuilder: (_, index) {
        final organizer = _organizers[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Text(
                organizer.initials,
                style: const TextStyle(color: Colors.black),
              ),
            ),
            title: Text(organizer.name),
            subtitle:
                Text('${organizer.specialty} - Rating ${organizer.rating}'),
            trailing: Text('\$${organizer.ratePerHour}/hr'),
          ),
        );
      },
    );
  }
}

class _Organizer {
  const _Organizer({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.ratePerHour,
  });

  final String name;
  final String specialty;
  final double rating;
  final int ratePerHour;

  String get initials {
    final parts = name.split(' ');
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    final first = parts.first.substring(0, 1);
    final last = parts.last.substring(0, 1);
    return (first + last).toUpperCase();
  }
}
