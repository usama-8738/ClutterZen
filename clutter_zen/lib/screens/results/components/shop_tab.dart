import 'package:flutter/material.dart';

class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: List.generate(
        6,
        (i) => Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                color: Colors.grey[200],
                child: const Center(child: Icon(Icons.shopping_bag, size: 48)),
              ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Product Name', maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('\$4.99', style: TextStyle(fontWeight: FontWeight.bold))),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Shop Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


