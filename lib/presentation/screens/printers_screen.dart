import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/utils/constants.dart';
import '../../data/models/printer_dto.dart';
import '../../data/models/print_job_dto.dart';
import '../../services/esc_pos_generator.dart';
import '../../services/print_station.dart';
import '../providers/auth_provider.dart';
import '../providers/printer_provider.dart';
import '../../services/printer_service.dart';

class PrintersScreen extends ConsumerStatefulWidget {
  const PrintersScreen({super.key});

  @override
  ConsumerState<PrintersScreen> createState() => _PrintersScreenState();
}

class _PrintersScreenState extends ConsumerState<PrintersScreen> {
  final Map<String, PrinterConnectionStatus> _status = {};
  final Set<String> _checking = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref
        .read(printerRepositoryProvider)
        .seedIfEmpty(Constants.defaultVenueId));
  }

  void _check(PrinterEntity printer) {
    if (_checking.contains(printer.id)) return;
    _checking.add(printer.id);
    setState(() => _status[printer.id] = PrinterConnectionStatus.checking);
    ref
        .read(printerActionsProvider.notifier)
        .testConnection(printer)
        .then((result) {
      _checking.remove(printer.id);
      if (mounted) setState(() => _status[printer.id] = result);
    });
  }

  Future<void> _testPrint(PrinterEntity printer) async {
    final ok =
        await ref.read(printerActionsProvider.notifier).printTest(printer);
    String message;
    Color bg;
    if (ok) {
      message = 'Prueba impresa en ${printer.name}';
      bg = AppColors.green;
    } else {
      // Sin WiFi directo: se encola para que la imprima la estación
      var queued = false;
      try {
        final bytes = EscPosGenerator.generateTestTicket(
          printerName: printer.name,
          ip: printer.ip,
        );
        final deviceId = await getDeviceId();
        await ref.read(printerRepositoryProvider).enqueueJob(
              venueId: Constants.defaultVenueId,
              printerId: printer.id,
              printerName: printer.name,
              workspace: '',
              type: PrintJobType.test,
              escPosHex: EscPosGenerator.bytesToHex(bytes),
              createdBy: deviceId,
            );
        queued = true;
      } catch (_) {}
      message = queued
          ? 'Sin conexión directa: prueba encolada, se imprimirá sola'
          : 'No se pudo imprimir en ${printer.name}';
      bg = queued ? AppColors.orange : AppColors.red;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: bg),
      );
    }
  }

  void _showPrinterDialog({PrinterEntity? printer}) {
    showDialog(
      context: context,
      builder: (_) => _PrinterDialog(printer: printer),
    );
  }

  Future<void> _confirmDelete(PrinterEntity printer) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar impresora'),
        content: Text('¿Eliminar "${printer.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(printerActionsProvider.notifier).deletePrinter(printer.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final printersAsync = ref.watch(printersProvider);

    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      appBar: AppBar(
        backgroundColor: AppColors.systemBackground,
        elevation: 0,
        leading: const BackButton(color: AppColors.label),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.print_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Impresoras',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.label,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: printersAsync.maybeWhen(
                data: (list) => Text(
                  '${list.length} impresora${list.length == 1 ? '' : 's'} configurada${list.length == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.secondaryLabel,
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.blue),
            onPressed: () => _showPrinterDialog(),
          ),
        ],
      ),
      body: printersAsync.when(
        data: (printers) {
          for (final p in printers) {
            if (!_status.containsKey(p.id) && !_checking.contains(p.id)) {
              Future.microtask(() => _check(p));
            }
          }
          if (printers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.print_disabled_rounded,
                      size: 56, color: AppColors.gray3),
                  const SizedBox(height: 12),
                  Text(
                    'Sin impresoras',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.label,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Añade la IP de tu impresora WiFi',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showPrinterDialog(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Añadir impresora'),
                  ),
                ],
              ),
            );
          }
          return Consumer(
            builder: (context, ref, _) {
              final jobsAsync = ref.watch(printJobsProvider);
              final jobs = jobsAsync.value ?? [];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  for (final printer in printers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PrinterCard(
                  printer: printer,
                status: _status[printer.id] ??
                    PrinterConnectionStatus.disconnected,
                allPrinters: printers,
                onCheck: () => _check(printer),
                onTestPrint: () => _testPrint(printer),
                onEdit: () => _showPrinterDialog(printer: printer),
                onDelete: () => _confirmDelete(printer),
                onSetPrincipal: (v) {
                  if (v) {
                    ref
                        .read(printerActionsProvider.notifier)
                        .setPrincipal(printers, printer.id);
                  }
                },
                      ),
                    ),
                  const SizedBox(height: 8),
                  _JobsSection(jobs: jobs),
                ],
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.blue)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ── Tarjeta de impresora ─────────────────────────────────────────────
class _PrinterCard extends StatelessWidget {
  final PrinterEntity printer;
  final PrinterConnectionStatus status;
  final List<PrinterEntity> allPrinters;
  final VoidCallback onCheck;
  final VoidCallback onTestPrint;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onSetPrincipal;

  const _PrinterCard({
    required this.printer,
    required this.status,
    required this.allPrinters,
    required this.onCheck,
    required this.onTestPrint,
    required this.onEdit,
    required this.onDelete,
    required this.onSetPrincipal,
  });

  @override
  Widget build(BuildContext context) {
    final connected = status == PrinterConnectionStatus.connected;
    final checking = status == PrinterConnectionStatus.checking;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Cabecera
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: connected ? AppColors.blue : AppColors.gray1,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wifi_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printer.name,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Red',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (printer.isPrincipal)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'PRINCIPAL',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onCheck,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: checking
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                connected ? 'Activa' : 'Inactiva',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Conexión
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conexión',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.systemBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.separator),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.wifi_rounded,
                        size: 20,
                        color: connected
                            ? AppColors.green
                            : AppColors.secondaryLabel,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        printer.connectionLabel,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.label,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Espacios de trabajo (${printer.workspaces.length})',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: printer.workspaces
                      .map((w) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.separator),
                            ),
                            child: Text(
                              w == PrinterWorkspace.kitchen
                                  ? 'Cocina'
                                  : 'Barra',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.label,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          // Pie: principal + acciones
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.systemBackground,
            child: Row(
              children: [
                Switch(
                  value: printer.isPrincipal,
                  onChanged: onSetPrincipal,
                  activeThumbColor: AppColors.blue,
                ),
                Text(
                  'Principal',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.label,
                  ),
                ),
                const Spacer(),
                _RoundButton(
                  icon: Icons.print_rounded,
                  color: AppColors.label,
                  onTap: onTestPrint,
                ),
                const SizedBox(width: 10),
                _RoundButton(
                  icon: Icons.settings_rounded,
                  color: AppColors.blue,
                  onTap: onEdit,
                ),
                const SizedBox(width: 10),
                _RoundButton(
                  icon: Icons.delete_rounded,
                  color: AppColors.red,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoundButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ── Diálogo añadir/editar ────────────────────────────────────────────
class _PrinterDialog extends ConsumerStatefulWidget {
  final PrinterEntity? printer;

  const _PrinterDialog({this.printer});

  @override
  ConsumerState<_PrinterDialog> createState() => _PrinterDialogState();
}

class _PrinterDialogState extends ConsumerState<_PrinterDialog> {
  late final TextEditingController _name;
  late final TextEditingController _ip;
  late final TextEditingController _port;
  late Set<String> _workspaces;
  late bool _isPrincipal;

  @override
  void initState() {
    super.initState();
    final p = widget.printer;
    _name = TextEditingController(text: p?.name ?? '');
    _ip = TextEditingController(text: p?.ip ?? '');
    _port = TextEditingController(text: '${p?.port ?? 9100}');
    _workspaces = Set.of(p?.workspaces ?? const [PrinterWorkspace.bar]);
    _isPrincipal = p?.isPrincipal ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _ip.dispose();
    _port.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final ip = _ip.text.trim();
    final port = int.tryParse(_port.text.trim()) ?? 9100;
    if (name.isEmpty || ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre e IP son obligatorios')),
      );
      return;
    }
    final actions = ref.read(printerActionsProvider.notifier);
    if (widget.printer == null) {
      await actions.addPrinter(
        name: name,
        ip: ip,
        port: port,
        isPrincipal: _isPrincipal,
        workspaces: _workspaces.toList(),
      );
    } else {
      await actions.updatePrinter(widget.printer!.id, {
        'name': name,
        'ip': ip,
        'port': port,
        'isPrincipal': _isPrincipal,
        'workspaces': _workspaces.toList(),
      });
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(printerActionsProvider).isLoading;
    return AlertDialog(
      title: Text(widget.printer == null
          ? 'Añadir impresora'
          : 'Editar impresora'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Nombre (p. ej. Barra)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ip,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              decoration: const InputDecoration(
                  labelText: 'IP (p. ej. 192.168.0.11)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _port,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Puerto (9100)'),
            ),
            const SizedBox(height: 16),
            const Text('Espacios de trabajo'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final entry in const [
                  MapEntry(PrinterWorkspace.bar, 'Barra'),
                  MapEntry(PrinterWorkspace.kitchen, 'Cocina'),
                ])
                  FilterChip(
                    label: Text(entry.value),
                    selected: _workspaces.contains(entry.key),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _workspaces.add(entry.key);
                      } else {
                        _workspaces.remove(entry.key);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Switch(
                  value: _isPrincipal,
                  onChanged: (v) => setState(() => _isPrincipal = v),
                  activeThumbColor: AppColors.blue,
                ),
                const Text('Principal'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: saving ? null : _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// ── Cola de impresión (relay) ────────────────────────────────────────
class _JobsSection extends ConsumerWidget {
  final List<PrintJobEntity> jobs;

  const _JobsSection({required this.jobs});

  String _typeLabel(String type) {
    switch (type) {
      case PrintJobType.kitchen:
        return 'Cocina';
      case PrintJobType.bill:
        return 'Cuenta';
      case PrintJobType.test:
        return 'Prueba';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(printerRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(
            'Cola de impresión (${jobs.where((j) => j.status == PrintJobStatus.pending || j.status == PrintJobStatus.printing).length} pendientes)',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.label,
            ),
          ),
        ),
        if (jobs.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              'Cola vacía',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.secondaryLabel,
              ),
            ),
          ),
        for (final job in jobs)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.separator),
            ),
            child: Row(
              children: [
                Icon(
                  job.type == PrintJobType.bill
                      ? Icons.receipt_rounded
                      : Icons.print_rounded,
                  size: 20,
                  color: AppColors.secondaryLabel,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_typeLabel(job.type)}'
                        '${job.tableNumber.isNotEmpty ? ' · Mesa ${job.tableNumber}' : ''}'
                        '${job.printerName.isNotEmpty ? ' · ${job.printerName}' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.label,
                        ),
                      ),
                      if (job.error != null && job.error!.isNotEmpty)
                        Text(
                          job.error!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.red,
                          ),
                        ),
                    ],
                  ),
                ),
                _JobStatusPill(status: job.status),
                if (job.status == PrintJobStatus.failed) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => repo.requeueJob(
                      venueId: Constants.defaultVenueId,
                      jobId: job.id,
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        size: 22, color: AppColors.blue),
                  ),
                ],
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => repo.deleteJob(
                    venueId: Constants.defaultVenueId,
                    jobId: job.id,
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 20, color: AppColors.secondaryLabel),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _JobStatusPill extends StatelessWidget {
  final PrintJobStatus status;

  const _JobStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    switch (status) {
      case PrintJobStatus.pending:
        label = 'En cola';
        color = AppColors.orange;
        break;
      case PrintJobStatus.printing:
        label = 'Imprimiendo';
        color = AppColors.blue;
        break;
      case PrintJobStatus.done:
        label = 'OK';
        color = AppColors.green;
        break;
      case PrintJobStatus.failed:
        label = 'Fallo';
        color = AppColors.red;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
