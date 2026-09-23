import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/utils/constants.dart';
import '../../data/models/table_dto.dart';
import '../../services/seed_service.dart';
import '../providers/table_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/printer_provider.dart';
import '../widgets/table_card.dart';
import '../widgets/add_table_dialog.dart';
import '../widgets/table_toolbar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final zone = _tabController.index == 0 ? 'Comedor' : 'Terraza';
        ref.read(selectedZoneProvider.notifier).state = zone;
      }
    });
    Future.microtask(() => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final seed = SeedService();
    await seed.seedIfEmpty();
    if (mounted) {
      ref.read(tableProvider.notifier).watchTables(Constants.defaultVenueId);
      // Estación de impresión: procesar trabajos pendientes en este equipo
      ref.read(printStationProvider).start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tableProvider);
    final allTables = tablesAsync.value ?? [];
    final selectedZone = ref.watch(selectedZoneProvider);
    final zoneTables =
        allTables.where((t) => t.zoneId == selectedZone).toList();
    final occupied = allTables.where((t) => t.hasItems).length;

    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      body: Stack(
        children: [
          Column(
            children: [
              // Frosted Header
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                        20, MediaQuery.of(context).padding.top + 12, 20, 16),
                    decoration: BoxDecoration(
                      color: AppColors.systemBackground.withValues(alpha: 0.85),
                      border: const Border(
                        bottom: BorderSide(
                            color: AppColors.separator, width: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'LaSede',
                              style: GoogleFonts.inter(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: AppColors.label,
                              ),
                            ),
                            const Spacer(),
                            _HeaderBadge(
                              occupied: occupied,
                              total: allTables.length,
                            ),
                            const SizedBox(width: 8),
                            _HeaderButton(
                              icon: Icons.menu_book_rounded,
                              onTap: () => context.push('/dashboard/menu'),
                            ),
                            const SizedBox(width: 4),
                            _HeaderButton(
                              icon: Icons.print_rounded,
                              onTap: () => context.push('/dashboard/printers'),
                            ),
                            const SizedBox(width: 4),
                            _HeaderButton(
                              icon: Icons.logout_rounded,
                              onTap: () async {
                                await ref.read(authProvider.notifier).signOut();
                              },
                            ),
                            const SizedBox(width: 4),
                            _HeaderButton(
                              icon: Icons.add_rounded,
                              onTap: () => _showAddTableDialog(context),
                              isPrimary: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // iOS Segmented Control
                        _SegmentedControl(
                          tabs: const ['Comedor', 'Terraza'],
                          selectedIndex: _tabController.index,
                          onChanged: (index) {
                            _tabController.animateTo(index);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Tables Grid
              Expanded(
                child: tablesAsync.when(
                  data: (_) => zoneTables.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.blue.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.table_chart_rounded,
                                    size: 48,
                                    color: AppColors.blue,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Sin mesas en $selectedZone',
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.label,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Añade una mesa con el botón +',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    color: AppColors.secondaryLabel,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _getCrossAxisCount(context),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: zoneTables.length,
                          itemBuilder: (context, index) {
                            final table = zoneTables[index];
                            return TableCard(
                              table: table,
                              onTap: () => _openTable(table),
                            );
                          },
                        ),
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.blue)),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: TableToolbar(),
          ),
        ],
      ),
    );
  }

  Future<void> _openTable(TableEntity table) async {
    await ref.read(cartProvider.notifier).setTable(
          table.id,
          table.tableNumber,
          existingOrderId: table.currentOrderId,
        );
    if (mounted) {
      context.push('/dashboard/table/${table.id}');
    }
  }

  void _showAddTableDialog(BuildContext context) {
    final zone = ref.read(selectedZoneProvider);
    showDialog(
      context: context,
      builder: (_) => AddTableDialog(initialZone: zone),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 500) return 2;
    if (width < 800) return 3;
    if (width < 1200) return 4;
    return 5;
  }
}

// ── iOS-style Segmented Control ──────────────────────────────────────
class _SegmentedControl extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedControl({
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.gray5,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.label : AppColors.gray1,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Header Badge ─────────────────────────────────────────────────────
class _HeaderBadge extends StatelessWidget {
  final int occupied;
  final int total;

  const _HeaderBadge({required this.occupied, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: occupied > 0
            ? AppColors.green.withValues(alpha: 0.12)
            : AppColors.gray5,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: occupied > 0 ? AppColors.green : AppColors.gray3,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$occupied/$total',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: occupied > 0 ? AppColors.green : AppColors.gray1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header Button ────────────────────────────────────────────────────
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _HeaderButton({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.blue : AppColors.gray5,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isPrimary ? Colors.white : AppColors.blue,
        ),
      ),
    );
  }
}
