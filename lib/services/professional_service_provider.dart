import '../models/professional_service.dart';
import '../models/vision_models.dart';

/// Service for matching professional organizers based on analysis
class ProfessionalServiceProvider {
  /// Database of professional organizers
  static final List<ProfessionalService> _professionals = [
    ProfessionalService(
      id: '1',
      name: 'Spark Tidy Co.',
      specialty: 'Whole-home organization',
      rating: 4.9,
      ratePerHour: 45,
      phone: '(555) 123-4567',
      email: 'hello@sparktidy.com',
      serviceAreas: ['Residential', 'Commercial', 'Moving'],
      description: 'Full-service organization for homes and offices. Specializing in decluttering, space planning, and sustainable organization systems.',
      experienceYears: 8,
      website: 'https://sparktidy.com',
      reviews: [
        ServiceReview(
          reviewerName: 'Sarah M.',
          rating: 5.0,
          comment: 'Transformed our entire home! Professional and efficient.',
          date: DateTime(2024, 1, 15),
        ),
      ],
    ),
    ProfessionalService(
      id: '2',
      name: 'Calm Closet Pros',
      specialty: 'Closet and wardrobe systems',
      rating: 4.8,
      ratePerHour: 55,
      phone: '(555) 234-5678',
      email: 'info@calmcloset.com',
      serviceAreas: ['Closets', 'Wardrobes', 'Fashion Organization'],
      description: 'Expert closet organization and wardrobe curation. Custom storage solutions and styling advice.',
      experienceYears: 6,
      website: 'https://calmcloset.com',
      reviews: [
        ServiceReview(
          reviewerName: 'Michael R.',
          rating: 4.8,
          comment: 'My closet has never looked better. Great attention to detail.',
          date: DateTime(2024, 2, 10),
        ),
      ],
    ),
    ProfessionalService(
      id: '3',
      name: 'Desk Refresh Crew',
      specialty: 'Home office and desk makeovers',
      rating: 4.7,
      ratePerHour: 40,
      phone: '(555) 345-6789',
      email: 'contact@deskrefresh.com',
      serviceAreas: ['Home Office', 'Workspaces', 'Desk Organization'],
      description: 'Specialized in creating productive and organized workspaces. Digital and physical organization solutions.',
      experienceYears: 5,
      reviews: [
        ServiceReview(
          reviewerName: 'Jennifer L.',
          rating: 4.7,
          comment: 'My productivity has increased significantly!',
          date: DateTime(2024, 1, 28),
        ),
      ],
    ),
    ProfessionalService(
      id: '4',
      name: 'Family Space Specialists',
      specialty: 'Playrooms and shared spaces',
      rating: 4.9,
      ratePerHour: 52,
      phone: '(555) 456-7890',
      email: 'hello@familyspace.com',
      serviceAreas: ['Playrooms', 'Kids Rooms', 'Family Areas'],
      description: 'Family-friendly organization solutions. Creating functional spaces for busy families with children.',
      experienceYears: 7,
      reviews: [
        ServiceReview(
          reviewerName: 'David K.',
          rating: 5.0,
          comment: 'Made our playroom both organized and fun for the kids!',
          date: DateTime(2024, 2, 5),
        ),
      ],
    ),
    ProfessionalService(
      id: '5',
      name: 'Kitchen Flow Studio',
      specialty: 'Kitchen and pantry optimization',
      rating: 4.8,
      ratePerHour: 58,
      phone: '(555) 567-8901',
      email: 'info@kitchenflow.com',
      serviceAreas: ['Kitchens', 'Pantries', 'Food Storage'],
      description: 'Kitchen organization experts. Maximizing storage and workflow efficiency in your kitchen space.',
      experienceYears: 9,
      reviews: [
        ServiceReview(
          reviewerName: 'Lisa T.',
          rating: 4.8,
          comment: 'My kitchen is now a joy to cook in!',
          date: DateTime(2024, 1, 20),
        ),
      ],
    ),
    ProfessionalService(
      id: '6',
      name: 'Garage Revival Team',
      specialty: 'Garage and storage upgrades',
      rating: 4.6,
      ratePerHour: 48,
      phone: '(555) 678-9012',
      email: 'contact@garagerevival.com',
      serviceAreas: ['Garages', 'Storage Units', 'Workshops'],
      description: 'Transforming cluttered garages into organized storage spaces. Heavy-duty organization solutions.',
      experienceYears: 6,
      reviews: [
        ServiceReview(
          reviewerName: 'Robert P.',
          rating: 4.6,
          comment: 'Finally can park my car in the garage again!',
          date: DateTime(2024, 2, 1),
        ),
      ],
    ),
  ];

  /// Matches professionals based on vision analysis
  static List<ProfessionalService> matchProfessionals(VisionAnalysis analysis) {
    final matches = <ProfessionalService>[];
    final objectNames = analysis.objects.map((o) => o.name.toLowerCase()).toList();
    final labels = analysis.labels.map((l) => l.toLowerCase()).toList();
    final allTerms = [...objectNames, ...labels];

    // Score each professional based on relevance
    final scores = <ProfessionalService, int>{};
    
    for (final professional in _professionals) {
      int score = 0;
      final specialtyLower = professional.specialty.toLowerCase();
      final descriptionLower = professional.description.toLowerCase();
      
      // Check for matches in specialty and description
      for (final term in allTerms) {
        if (specialtyLower.contains(term) || descriptionLower.contains(term)) {
          score += 2;
        }
        
        // Category-specific matching
        if (_matchesCategory(term, professional.specialty)) {
          score += 3;
        }
      }
      
      if (score > 0) {
        scores[professional] = score;
      }
    }

    // Sort by score and rating
    final sorted = scores.entries.toList()
      ..sort((a, b) {
        final scoreCompare = b.value.compareTo(a.value);
        if (scoreCompare != 0) return scoreCompare;
        return b.key.rating.compareTo(a.key.rating);
      });

    // Return top 3 matches, or all if less than 3
    for (final entry in sorted.take(3)) {
      matches.add(entry.key);
    }

    // If no matches, return top rated professionals
    if (matches.isEmpty) {
      final topRated = List<ProfessionalService>.from(_professionals)
        ..sort((a, b) => b.rating.compareTo(a.rating));
      return topRated.take(3).toList();
    }

    return matches;
  }

  /// Checks if a term matches a professional's specialty category
  static bool _matchesCategory(String term, String specialty) {
    final specialtyLower = specialty.toLowerCase();
    
    // Clothing/Wardrobe
    if (['shirt', 'pants', 'dress', 'clothing', 'wardrobe', 'closet']
        .any((t) => term.contains(t))) {
      return specialtyLower.contains('closet') || 
             specialtyLower.contains('wardrobe') ||
             specialtyLower.contains('clothing');
    }
    
    // Office/Desk
    if (['computer', 'laptop', 'desk', 'office', 'paper', 'document']
        .any((t) => term.contains(t))) {
      return specialtyLower.contains('office') || 
             specialtyLower.contains('desk') ||
             specialtyLower.contains('workspace');
    }
    
    // Kitchen
    if (['kitchen', 'food', 'pantry', 'plate', 'bowl', 'cup']
        .any((t) => term.contains(t))) {
      return specialtyLower.contains('kitchen') || 
             specialtyLower.contains('pantry');
    }
    
    // Toys/Playroom
    if (['toy', 'game', 'playroom', 'kids']
        .any((t) => term.contains(t))) {
      return specialtyLower.contains('playroom') || 
             specialtyLower.contains('family') ||
             specialtyLower.contains('kids');
    }
    
    // Garage
    if (['garage', 'tool', 'storage']
        .any((t) => term.contains(t))) {
      return specialtyLower.contains('garage') || 
             specialtyLower.contains('storage');
    }
    
    return false;
  }

  /// Gets all professionals
  static List<ProfessionalService> getAllProfessionals() {
    return List.unmodifiable(_professionals);
  }

  /// Gets professional by ID
  static ProfessionalService? getProfessionalById(String id) {
    try {
      return _professionals.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}

