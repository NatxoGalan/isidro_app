import 'package:flutter/material.dart';

class CategoryPills extends StatelessWidget {
  const CategoryPills({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: ['Todos', 'Tapas', 'Bebidas', 'Bocadillos', 'Varios'].map((cat) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(cat),
              selected: cat == 'Todos',
              onSelected: (_) {},
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.green.shade200,
            ),
          );
        }).toList(),
      ),
    );
  }
}
