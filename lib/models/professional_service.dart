import 'package:flutter/foundation.dart';

@immutable
class ProfessionalService {
  const ProfessionalService({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.ratePerHour,
    required this.phone,
    required this.email,
    required this.serviceAreas,
    required this.description,
    required this.experienceYears,
    this.website,
    this.imageUrl,
    this.reviews = const [],
    this.stripeAccountId,
  });

  final String id;
  final String name;
  final String specialty;
  final double rating;
  final int ratePerHour;
  final String phone;
  final String email;
  final List<String> serviceAreas;
  final String description;
  final int experienceYears;
  final String? website;
  final String? imageUrl;
  final List<ServiceReview> reviews;
  final String? stripeAccountId; // Stripe Connect account ID

  String get initials {
    final parts = name.split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String get formattedRate => '\$$ratePerHour/hr';
  
  String get ratingDisplay => rating.toStringAsFixed(1);
}

@immutable
class ServiceReview {
  const ServiceReview({
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  final String reviewerName;
  final double rating;
  final String comment;
  final DateTime date;
}

