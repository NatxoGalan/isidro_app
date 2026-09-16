import 'package:flutter/material.dart';
import '../../config/theme.dart';

class ProductSearchBar extends StatelessWidget {
  final String query;
  final ValueChanged<String> onChanged;

  const ProductSearchBar({super.key, required this.query, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Buscar productos...',
        prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}