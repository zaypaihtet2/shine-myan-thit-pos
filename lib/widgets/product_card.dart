import 'dart:io';

import 'package:flutter/material.dart';

import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child:
                      product.imagePath != null &&
                          File(product.imagePath!).existsSync()
                      ? Image.file(
                          File(product.imagePath!),
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          width: double.infinity,
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 36,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text('Stock: ${product.stockQuantity}'),
              Text('Price: ${product.sellingPrice.toStringAsFixed(2)}'),
              if (product.discountPercent > 0)
                Text(
                  'Discount: ${product.discountPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
