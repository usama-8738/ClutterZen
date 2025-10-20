import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/product_recommendation.dart';
import '../../../models/vision_models.dart';

class ShopTab extends StatefulWidget {
  const ShopTab({super.key, required this.analysis});
  final VisionAnalysis analysis;

  @override
  State<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<ShopTab> {
  late Future<List<ProductRecommendation>> _recommendationsFuture;

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = _matchOrganizingProducts(widget.analysis.objects);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductRecommendation>>(
      future: _recommendationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final recommendations = snapshot.data ?? [];
        if (recommendations.isEmpty) {
          return const Center(child: Text('No product recommendations available.'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.65,
          ),
          itemCount: recommendations.length,
          itemBuilder: (context, i) {
            final product = recommendations[i];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 120,
                    color: Colors.grey[200],
                    child: Center(
                      child: product.imageUrl.isNotEmpty
                          ? Image.network(product.imageUrl, fit: BoxFit.cover, width: double.infinity)
                          : const Icon(Icons.shopping_bag, size: 48),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      onPressed: () => _launchUrl(product.affiliateLink),
                      child: const Text('Shop Now'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _categorizeObject(String objectName) {
    final name = objectName.toLowerCase();
    if (['shirt', 'pants', 'dress', 'jacket', 'coat', 'shoe', 'clothing', 'jeans', 'sweater', 'sock', 'tie', 'belt', 'hat', 'scarf'].any((item) => name.contains(item))) {
      return 'clothing';
    }
    if (['book', 'magazine', 'newspaper', 'paper', 'document', 'notebook', 'folder', 'binder', 'journal'].any((item) => name.contains(item))) {
      return 'books_paper';
    }
    if (['computer', 'laptop', 'phone', 'tablet', 'cable', 'charger', 'headphones', 'keyboard', 'mouse', 'monitor', 'television', 'remote'].any((item) => name.contains(item))) {
      return 'electronics';
    }
    if (['plate', 'bowl', 'cup', 'mug', 'glass', 'fork', 'spoon', 'knife', 'pot', 'pan', 'bottle', 'food'].any((item) => name.contains(item))) {
      return 'kitchen';
    }
    if (['toy', 'game', 'doll', 'puzzle', 'ball', 'lego', 'stuffed animal'].any((item) => name.contains(item))) {
      return 'toys';
    }
    if (['pen', 'pencil', 'stapler', 'scissors', 'tape', 'ruler', 'eraser', 'paperclip', 'calculator'].any((item) => name.contains(item))) {
      return 'office';
    }
    if (['towel', 'brush', 'cosmetics', 'makeup', 'perfume', 'lotion', 'shampoo', 'soap', 'toothbrush'].any((item) => name.contains(item))) {
      return 'personal_care';
    }
    if (['chair', 'table', 'desk', 'bed', 'sofa', 'couch', 'shelf', 'cabinet', 'drawer', 'dresser'].any((item) => name.contains(item))) {
      return 'furniture';
    }
    return 'miscellaneous';
  }

  Future<List<ProductRecommendation>> _matchOrganizingProducts(List<DetectedObject> objects) async {
    final recommendations = <ProductRecommendation>[];
    final categoryCounts = <String, int>{};
    for (var obj in objects) {
      final category = _categorizeObject(obj.name);
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    final productDatabase = <String, List<ProductRecommendation>>{
      'clothing': [
        const ProductRecommendation(name: 'Slim Velvet Hangers 50-Pack', price: 29.99, merchant: 'Amazon', category: 'Hangers', affiliateLink: 'https://amzn.to/example1', imageUrl: 'https://i.imgur.com/example.jpg', rating: 4.5, description: 'Space-saving hangers for all clothing types'),
        const ProductRecommendation(name: 'Drawer Divider Organizers Set', price: 15.99, merchant: 'Amazon', category: 'Organizers', affiliateLink: 'https://amzn.to/example2', imageUrl: 'https://i.imgur.com/example.jpg', rating: 4.3, description: 'Adjustable dividers for drawers'),
      ],
      'electronics': [
        const ProductRecommendation(name: 'Cable Management Box', price: 19.99, merchant: 'Amazon', category: 'Cable Management', affiliateLink: 'https://amzn.to/cable1', imageUrl: 'https://i.imgur.com/example.jpg', rating: 4.6, description: 'Hide and organize all cables'),
      ],
      'books_paper': [
        const ProductRecommendation(name: 'Desktop File Organizer', price: 22.99, merchant: 'Walmart', category: 'Filing', affiliateLink: 'https://walmart.com/file1', imageUrl: 'https://i.imgur.com/example.jpg', rating: 4.2, description: 'Multi-tier paper organizer'),
      ],
      'kitchen': [
        const ProductRecommendation(name: 'Airtight Food Storage Set', price: 32.99, merchant: 'Target', category: 'Storage', affiliateLink: 'https://target.com/food1', imageUrl: 'https://i.imgur.com/example.jpg', rating: 4.6, description: '14-piece container set with labels'),
      ],
    };

    final addedProducts = <String>{};
    for (var entry in categoryCounts.entries) {
      final category = entry.key;
      final count = entry.value;
      final categoryProducts = productDatabase[category];
      if (categoryProducts != null && categoryProducts.isNotEmpty) {
        final productsToAdd = count > 5 ? 2 : 1;
        for (int i = 0; i < min(productsToAdd, categoryProducts.length); i++) {
          var product = categoryProducts[i];
          if (addedProducts.add(product.name)) {
            recommendations.add(product);
          }
        }
      }
    }
    return recommendations;
  }
}


