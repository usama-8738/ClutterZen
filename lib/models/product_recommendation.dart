import 'package:flutter/foundation.dart';

@immutable
class ProductRecommendation {
  const ProductRecommendation({
    required this.name,
    required this.price,
    required this.merchant,
    required this.category,
    required this.affiliateLink,
    required this.imageUrl,
    required this.rating,
    required this.description,
  });

  final String name;
  final double price;
  final String merchant;
  final String category;
  final String affiliateLink;
  final String imageUrl;
  final double rating;
  final String description;
}
