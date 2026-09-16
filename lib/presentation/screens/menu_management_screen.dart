import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/utils/constants.dart';
import '../../data/models/product_dto.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/product_management_tile.dart';

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  String _selectedCategory = 'Todos';
  String _searchQuery = '';

  static const Map<String, String> _categorySlugs = {
    'Todos': '',
    'Tapas': 'tapas',
    'Bocadillos': 'bocadillos',
    'Bebidas': 'bebidas',
    'Varios': 'varios',
    'Cafetería': 'cafeteria',
  };

  String get _selectedCategorySlug => _categorySlugs[_selectedCategory] ?? '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.systemBackground,
              border: Border(bottom: BorderSide(color: AppColors.separator, width: 0.5)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.gray5, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.blue)),
                    ),
                    const SizedBox(width: 12),
                    Text('Gestión de Carta', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.label)),
                    const Spacer(),
                    GestureDetector(
                      onTap: _showProductDialog,
                      child: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.add_rounded, color: Colors.white, size: 22)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: GoogleFonts.inter(fontSize: 15, color: AppColors.label),
                  decoration: InputDecoration(
                    hintText: 'Buscar productos...',
                    hintStyle: GoogleFonts.inter(color: AppColors.gray2),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.gray2),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categorySlugs.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final cat = _categorySlugs.keys.elementAt(index);
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.blue : AppColors.gray6,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(cat, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.secondaryLabel)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Products
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filtered = products.where((p) {
                  final matchesCat = _selectedCategory == 'Todos' || p.categoryId == _selectedCategorySlug;
                  final matchesSearch = _searchQuery.isEmpty || p.name.toLowerCase().contains(_searchQuery.toLowerCase());
                  return matchesCat && matchesSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(child: Text('No hay productos', style: GoogleFonts.inter(color: AppColors.secondaryLabel, fontSize: 15)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => Container(height: 0.5, color: AppColors.separator, margin: const EdgeInsets.only(left: 56)),
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    return ProductManagementTile(
                      product: p,
                      onEdit: () => _showProductDialog(product: p),
                      onDelete: () => _deleteProduct(p),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.blue)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDialog({ProductEntity? product}) {
    showDialog(context: context, builder: (_) => ProductDialog(product: product));
  }

  void _deleteProduct(ProductEntity product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar "${product.name}"', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text('¿Estás seguro? Esta acción no se puede deshacer.', style: GoogleFonts.inter(color: AppColors.secondaryLabel)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: TextStyle(color: AppColors.blue))),
          TextButton(
            onPressed: () {
              ref.read(productRepositoryProvider).deleteProduct(product.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.name} eliminado'), backgroundColor: AppColors.green),
              );
            },
            child: Text('Eliminar', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

class ProductDialog extends ConsumerStatefulWidget {
  final ProductEntity? product;
  const ProductDialog({super.key, this.product});

  @override
  ConsumerState<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends ConsumerState<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late double _price;
  late String _category;
  late String _description;
  bool _isAvailable = true;

  static const List<String> _categoryDisplayNames = ['Tapas', 'Bocadillos', 'Bebidas', 'Varios', 'Cafetería'];
  static const Map<String, String> _categorySlugs = {
    'Tapas': 'tapas',
    'Bocadillos': 'bocadillos',
    'Bebidas': 'bebidas',
    'Varios': 'varios',
    'Cafetería': 'cafeteria',
  };

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = p?.name ?? '';
    _price = p?.basePrice ?? 0.0;
    final slugToDisplay = _categorySlugs.entries.where((e) => e.value == p?.categoryId).map((e) => e.key).firstOrNull;
    _category = slugToDisplay ?? 'Tapas';
    _description = p?.description ?? '';
    _isAvailable = p?.isAvailable ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(widget.product == null ? 'Nuevo producto' : 'Editar producto', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.label)),
            ),
            const Divider(height: 0.5, color: AppColors.separator),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: _name,
                        style: GoogleFonts.inter(fontSize: 15, color: AppColors.label),
                        decoration: const InputDecoration(labelText: 'Nombre *'),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        onChanged: (v) => _name = v,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        initialValue: _price.toString(),
                        style: GoogleFonts.inter(fontSize: 15, color: AppColors.label),
                        decoration: const InputDecoration(labelText: 'Precio (€) *', prefixText: '€ '),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        onChanged: (v) => _price = double.tryParse(v) ?? 0,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _category,
                        items: _categoryDisplayNames.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.inter()))).toList(),
                        onChanged: (v) => setState(() => _category = v!),
                        decoration: const InputDecoration(labelText: 'Categoría'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        initialValue: _description,
                        style: GoogleFonts.inter(fontSize: 15, color: AppColors.label),
                        decoration: const InputDecoration(labelText: 'Descripción'),
                        onChanged: (v) => _description = v,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text('Disponible', style: GoogleFonts.inter(fontSize: 15, color: AppColors.label)),
                          const Spacer(),
                          Switch(
                            value: _isAvailable,
                            onChanged: (v) => setState(() => _isAvailable = v),
                            activeColor: AppColors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 0.5, color: AppColors.separator),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.secondaryLabel, side: const BorderSide(color: AppColors.separator, width: 0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Text('Cancelar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Text(widget.product == null ? 'Crear' : 'Guardar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final slug = _categorySlugs[_category] ?? 'tapas';
    final repo = ref.read(productRepositoryProvider);

    if (widget.product != null) {
      repo.updateProduct(widget.product!.id, {'name': _name, 'basePrice': _price, 'categoryId': slug, 'description': _description, 'isAvailable': _isAvailable});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto actualizado'), backgroundColor: AppColors.green),
      );
    } else {
      final product = ProductEntity(id: '', categoryId: slug, venueId: Constants.defaultVenueId, name: _name, description: _description, basePrice: _price, isAvailable: _isAvailable);
      repo.createProduct(product);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto creado'), backgroundColor: AppColors.green),
      );
    }

    Navigator.pop(context);
  }
}
