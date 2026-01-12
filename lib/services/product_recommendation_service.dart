import 'dart:math';
import '../models/product_recommendation.dart';
import '../models/vision_models.dart';

/// Service for generating product recommendations based on vision analysis
class ProductRecommendationService {
  /// Comprehensive product database organized by category
  static final Map<String, List<ProductRecommendation>> _productDatabase = {
    'clothing': [
      const ProductRecommendation(
        name: 'Slim Velvet Hangers 50-Pack',
        price: 29.99,
        merchant: 'Amazon',
        category: 'Hangers',
        affiliateLink: 'https://www.amazon.com/s?k=velvet+hangers+50+pack',
        imageUrl: 'https://images.unsplash.com/photo-1624222247344-550fb60583fd?w=400',
        rating: 4.5,
        description: 'Space-saving velvet hangers for all clothing types',
      ),
      const ProductRecommendation(
        name: 'Drawer Divider Organizers Set',
        price: 15.99,
        merchant: 'Amazon',
        category: 'Organizers',
        affiliateLink: 'https://www.amazon.com/s?k=drawer+dividers',
        imageUrl: 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400',
        rating: 4.3,
        description: 'Adjustable dividers for drawers and shelves',
      ),
      const ProductRecommendation(
        name: 'Closet Storage Baskets Set',
        price: 24.99,
        merchant: 'Target',
        category: 'Storage',
        affiliateLink: 'https://www.target.com/s?searchTerm=closet+baskets',
        imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400',
        rating: 4.6,
        description: '6-piece fabric storage basket set',
      ),
    ],
    'electronics': [
      const ProductRecommendation(
        name: 'Cable Management Box',
        price: 19.99,
        merchant: 'Amazon',
        category: 'Cable Management',
        affiliateLink: 'https://www.amazon.com/s?k=cable+management+box',
        imageUrl: 'https://images.unsplash.com/photo-1586953208448-b95a79798f07?w=400',
        rating: 4.6,
        description: 'Hide and organize all cables neatly',
      ),
      const ProductRecommendation(
        name: 'Desk Cable Organizer Clips',
        price: 12.99,
        merchant: 'Amazon',
        category: 'Cable Management',
        affiliateLink: 'https://www.amazon.com/s?k=cable+clips',
        imageUrl: 'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=400',
        rating: 4.4,
        description: 'Adhesive cable clips for desk organization',
      ),
      const ProductRecommendation(
        name: 'Tech Organizer Pouch',
        price: 16.99,
        merchant: 'Amazon',
        category: 'Organizers',
        affiliateLink: 'https://www.amazon.com/s?k=tech+organizer+pouch',
        imageUrl: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=400',
        rating: 4.5,
        description: 'Portable organizer for cables and accessories',
      ),
    ],
    'books_paper': [
      const ProductRecommendation(
        name: 'Desktop File Organizer',
        price: 22.99,
        merchant: 'Walmart',
        category: 'Filing',
        affiliateLink: 'https://www.walmart.com/search?q=file+organizer',
        imageUrl: 'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=400',
        rating: 4.2,
        description: 'Multi-tier paper organizer for desk',
      ),
      const ProductRecommendation(
        name: 'Document Filing System',
        price: 34.99,
        merchant: 'Amazon',
        category: 'Filing',
        affiliateLink: 'https://www.amazon.com/s?k=document+filing+system',
        imageUrl: 'https://images.unsplash.com/photo-1452860606245-08befc0ff44b?w=400',
        rating: 4.4,
        description: 'Expandable filing system with labels',
      ),
      const ProductRecommendation(
        name: 'Magazine Storage Boxes',
        price: 18.99,
        merchant: 'Target',
        category: 'Storage',
        affiliateLink: 'https://www.target.com/s?searchTerm=magazine+storage',
        imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
        rating: 4.3,
        description: 'Set of 4 decorative storage boxes',
      ),
    ],
    'kitchen': [
      const ProductRecommendation(
        name: 'Airtight Food Storage Set',
        price: 32.99,
        merchant: 'Target',
        category: 'Storage',
        affiliateLink: 'https://www.target.com/s?searchTerm=food+storage+containers',
        imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=400',
        rating: 4.6,
        description: '14-piece container set with labels',
      ),
      const ProductRecommendation(
        name: 'Pantry Organizer Bins',
        price: 24.99,
        merchant: 'Amazon',
        category: 'Organizers',
        affiliateLink: 'https://www.amazon.com/s?k=pantry+organizer',
        imageUrl: 'https://images.unsplash.com/photo-1556911220-bff31c812dba?w=400',
        rating: 4.5,
        description: 'Clear storage bins with labels',
      ),
      const ProductRecommendation(
        name: 'Spice Rack Organizer',
        price: 19.99,
        merchant: 'Amazon',
        category: 'Organizers',
        affiliateLink: 'https://www.amazon.com/s?k=spice+rack',
        imageUrl: 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=400',
        rating: 4.4,
        description: 'Tiered spice rack for cabinet',
      ),
    ],
    'office': [
      const ProductRecommendation(
        name: 'Desk Organizer Set',
        price: 28.99,
        merchant: 'Amazon',
        category: 'Organizers',
        affiliateLink: 'https://www.amazon.com/s?k=desk+organizer',
        imageUrl: 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=400',
        rating: 4.5,
        description: 'Multi-compartment desk organizer',
      ),
      const ProductRecommendation(
        name: 'Pen and Pencil Holder',
        price: 14.99,
        merchant: 'Amazon',
        category: 'Organizers',
        affiliateLink: 'https://www.amazon.com/s?k=pen+holder',
        imageUrl: 'https://images.unsplash.com/photo-1452860606245-08befc0ff44b?w=400',
        rating: 4.3,
        description: 'Stylish desk accessory organizer',
      ),
    ],
    'furniture': [
      const ProductRecommendation(
        name: 'Storage Ottoman',
        price: 89.99,
        merchant: 'Amazon',
        category: 'Furniture',
        affiliateLink: 'https://www.amazon.com/s?k=storage+ottoman',
        imageUrl: 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400',
        rating: 4.6,
        description: 'Multi-functional storage furniture',
      ),
      const ProductRecommendation(
        name: 'Shelf Organizer Bins',
        price: 16.99,
        merchant: 'Target',
        category: 'Organizers',
        affiliateLink: 'https://www.target.com/s?searchTerm=shelf+bins',
        imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400',
        rating: 4.4,
        description: 'Bins for shelf organization',
      ),
    ],
    'toys': [
      const ProductRecommendation(
        name: 'Toy Storage Bins',
        price: 22.99,
        merchant: 'Target',
        category: 'Storage',
        affiliateLink: 'https://www.target.com/s?searchTerm=toy+storage',
        imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400',
        rating: 4.5,
        description: 'Colorful storage bins for toys',
      ),
      const ProductRecommendation(
        name: 'Toy Organizer Cart',
        price: 39.99,
        merchant: 'Amazon',
        category: 'Organizers',
        affiliateLink: 'https://www.amazon.com/s?k=toy+organizer',
        imageUrl: 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400',
        rating: 4.6,
        description: 'Rolling cart with multiple bins',
      ),
    ],
    'personal_care': [
      const ProductRecommendation(
        name: 'Bathroom Organizer Set',
        price: 24.99,
        merchant: 'Amazon',
        category: 'Organizers',
        affiliateLink: 'https://www.amazon.com/s?k=bathroom+organizer',
        imageUrl: 'https://images.unsplash.com/photo-1624222247344-550fb60583fd?w=400',
        rating: 4.4,
        description: 'Shower and countertop organizers',
      ),
    ],
    'miscellaneous': [
      const ProductRecommendation(
        name: 'Storage Baskets Set',
        price: 19.99,
        merchant: 'Amazon',
        category: 'Storage',
        affiliateLink: 'https://www.amazon.com/s?k=storage+baskets',
        imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400',
        rating: 4.3,
        description: 'Versatile storage solution',
      ),
      const ProductRecommendation(
        name: 'Label Maker',
        price: 29.99,
        merchant: 'Amazon',
        category: 'Organizers',
        affiliateLink: 'https://www.amazon.com/s?k=label+maker',
        imageUrl: 'https://images.unsplash.com/photo-1452860606245-08befc0ff44b?w=400',
        rating: 4.5,
        description: 'Portable label maker for organization',
      ),
    ],
  };

  /// Generates product recommendations based on detected objects
  static Future<List<ProductRecommendation>> generateRecommendations(
    VisionAnalysis analysis,
  ) async {
    final recommendations = <ProductRecommendation>[];
    final categoryCounts = <String, int>{};
    
    // Count objects by category
    for (final obj in analysis.objects) {
      final category = _categorizeObject(obj.name);
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }
    
    // Also consider labels for broader recommendations
    for (final label in analysis.labels.take(5)) {
      final category = _categorizeObject(label);
      if (category != 'miscellaneous') {
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
    }

    final addedProducts = <String>{};
    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Get top 3-6 recommendations
    for (final entry in sortedCategories.take(3)) {
      final category = entry.key;
      final count = entry.value;
      final categoryProducts = _productDatabase[category];
      
      if (categoryProducts != null && categoryProducts.isNotEmpty) {
        // More items in category = more recommendations
        final productsToAdd = count > 5 ? 2 : 1;
        final shuffled = List<ProductRecommendation>.from(categoryProducts)
          ..shuffle(Random());
        
        for (int i = 0; 
             i < min(productsToAdd, shuffled.length) && 
             recommendations.length < 6; 
             i++) {
          final product = shuffled[i];
          if (addedProducts.add(product.name)) {
            recommendations.add(product);
          }
        }
      }
    }

    // If we don't have enough, add general recommendations
    if (recommendations.length < 3) {
      final generalProducts = _productDatabase['miscellaneous'] ?? [];
      for (final product in generalProducts.take(3 - recommendations.length)) {
        if (addedProducts.add(product.name)) {
          recommendations.add(product);
        }
      }
    }

    return recommendations;
  }

  /// Categorizes an object name into a product category
  static String _categorizeObject(String objectName) {
    final name = objectName.toLowerCase();
    
    if ([
      'shirt', 'pants', 'dress', 'jacket', 'coat', 'shoe', 'clothing',
      'jeans', 'sweater', 'sock', 'tie', 'belt', 'hat', 'scarf', 'boot',
      'sneaker', 'sandal', 'shorts', 'skirt', 'blouse', 't-shirt'
    ].any((item) => name.contains(item))) {
      return 'clothing';
    }
    
    if ([
      'book', 'magazine', 'newspaper', 'paper', 'document', 'notebook',
      'folder', 'binder', 'journal', 'letter', 'envelope'
    ].any((item) => name.contains(item))) {
      return 'books_paper';
    }
    
    if ([
      'computer', 'laptop', 'phone', 'tablet', 'cable', 'charger',
      'headphones', 'keyboard', 'mouse', 'monitor', 'television', 'tv',
      'remote', 'speaker', 'printer', 'camera'
    ].any((item) => name.contains(item))) {
      return 'electronics';
    }
    
    if ([
      'plate', 'bowl', 'cup', 'mug', 'glass', 'fork', 'spoon', 'knife',
      'pot', 'pan', 'bottle', 'food', 'container', 'jar', 'can'
    ].any((item) => name.contains(item))) {
      return 'kitchen';
    }
    
    if (['toy', 'game', 'doll', 'puzzle', 'ball', 'lego', 'stuffed animal',
         'action figure', 'board game'].any((item) => name.contains(item))) {
      return 'toys';
    }
    
    if ([
      'pen', 'pencil', 'stapler', 'scissors', 'tape', 'ruler', 'eraser',
      'paperclip', 'calculator', 'marker', 'highlighter'
    ].any((item) => name.contains(item))) {
      return 'office';
    }
    
    if ([
      'towel', 'brush', 'cosmetics', 'makeup', 'perfume', 'lotion',
      'shampoo', 'soap', 'toothbrush', 'razor', 'mirror'
    ].any((item) => name.contains(item))) {
      return 'personal_care';
    }
    
    if ([
      'chair', 'table', 'desk', 'bed', 'sofa', 'couch', 'shelf', 'cabinet',
      'drawer', 'dresser', 'ottoman', 'stool', 'bench'
    ].any((item) => name.contains(item))) {
      return 'furniture';
    }
    
    return 'miscellaneous';
  }

  /// Gets all products for a specific category
  static List<ProductRecommendation> getProductsByCategory(String category) {
    return _productDatabase[category] ?? [];
  }

  /// Searches products by name or description
  static List<ProductRecommendation> searchProducts(String query) {
    final results = <ProductRecommendation>[];
    final lowerQuery = query.toLowerCase();
    
    for (final products in _productDatabase.values) {
      for (final product in products) {
        if (product.name.toLowerCase().contains(lowerQuery) ||
            product.description.toLowerCase().contains(lowerQuery) ||
            product.category.toLowerCase().contains(lowerQuery)) {
          results.add(product);
        }
      }
    }
    
    return results;
  }
}

