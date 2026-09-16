import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../data/models/print_dto.dart';
import '../providers/printer_provider.dart';

class MockPrinterOverlay extends ConsumerWidget {
  const MockPrinterOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(printQueueProvider);
    final pendingCount = tickets.where((t) => t.status == PrintStatus.pending).length;

    if (pendingCount == 0) return const SizedBox.shrink();

    return Positioned(
      right: 20,
      bottom: 100,
      child: GestureDetector(
        onTap: () => _showPrintQueue(context, ref, tickets),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: AppColors.orange.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.print_rounded, color: Colors.white, size: 24),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text('$pendingCount', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrintQueue(BuildContext context, WidgetRef ref, List<PrintQueueTicket> tickets) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PrintQueueSheet(tickets: tickets),
    );
  }
}

class _PrintQueueSheet extends ConsumerWidget {
  final List<PrintQueueTicket> tickets;
  const _PrintQueueSheet({required this.tickets});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 5,
              decoration: BoxDecoration(color: AppColors.gray4, borderRadius: BorderRadius.circular(3)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.print_rounded, size: 18, color: AppColors.orange)),
                const SizedBox(width: 10),
                Text('Cola de impresión', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.label)),
                const Spacer(),
                if (tickets.any((t) => t.status == PrintStatus.pending))
                  GestureDetector(
                    onTap: () {
                      ref.read(printQueueProvider.notifier).printAllPending();
                      Navigator.pop(context);
                    },
                    child: Text('Imprimir todo', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.blue)),
                  ),
              ],
            ),
          ),
          const Divider(height: 0.5, color: AppColors.separator),
          Flexible(
            child: tickets.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('No hay tickets en la cola', style: GoogleFonts.inter(color: AppColors.secondaryLabel)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: tickets.length,
                    separatorBuilder: (_, _) => Container(height: 0.5, color: AppColors.separator, margin: const EdgeInsets.only(left: 60)),
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      final isPending = ticket.status == PrintStatus.pending;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isPending ? AppColors.orange.withValues(alpha: 0.1) : AppColors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isPending ? Icons.pending_actions_rounded : Icons.check_circle_rounded,
                            size: 20,
                            color: isPending ? AppColors.orange : AppColors.green,
                          ),
                        ),
                        title: Text('${ticket.targetDisplayName} - Mesa ${ticket.tableNumber}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.label)),
                        subtitle: Text('${ticket.itemsCount} items · ${_formatTime(ticket.createdAt)}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.secondaryLabel)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            final notifier = ref.read(printQueueProvider.notifier);
                            switch (action) {
                              case 'reprint': notifier.reprint(ticket.id); break;
                              case 'remove': notifier.removeTicket(ticket.id); break;
                            }
                          },
                          itemBuilder: (_) => [
                            if (!isPending) const PopupMenuItem(value: 'reprint', child: Text('Reimprimir')),
                            const PopupMenuItem(value: 'remove', child: Text('Eliminar')),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
