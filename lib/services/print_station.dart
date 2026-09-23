import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/utils/constants.dart';
import '../data/models/print_job_dto.dart';
import '../data/models/printer_dto.dart';
import '../data/repositories/printer_repository.dart';
import 'printer_service.dart';

/// Identificador único de este dispositivo (para createdBy/claimedBy).
Future<String> getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  var id = prefs.getString('device_id');
  if (id == null || id.isEmpty) {
    id = const Uuid().v4();
    await prefs.setString('device_id', id);
  }
  return id;
}

/// Estación de impresión: escucha trabajos pendientes en Firestore y los
/// imprime en cuanto este dispositivo puede alcanzar la impresora.
/// El reclamo es atómico (transacción), así que aunque varios dispositivos
/// escuchen, solo uno imprime cada trabajo.
class PrintStationService {
  final PrinterRepository _repo;
  final String venueId;

  StreamSubscription<List<PrintJobEntity>>? _sub;
  bool _processing = false;
  String? _deviceId;

  PrintStationService(this._repo, {this.venueId = Constants.defaultVenueId});

  Future<void> start() async {
    await stop();
    try {
      _deviceId ??= await getDeviceId();
    } catch (_) {
      return;
    }
    try {
      await _repo.cleanOldJobs(venueId);
    } catch (_) {}
    _sub = _repo.watchPendingJobs(venueId).listen(
          _onJobs,
          onError: (_) {},
        );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> _onJobs(List<PrintJobEntity> jobs) async {
    if (_processing || _deviceId == null) return;
    _processing = true;
    try {
      for (final job in jobs) {
        final claimed = await _repo.claimJob(
          venueId: venueId,
          jobId: job.id,
          deviceId: _deviceId!,
        );
        if (!claimed) continue;
        await _processJob(job);
      }
    } catch (_) {
      // Se reintenta con el siguiente evento del stream.
    } finally {
      _processing = false;
    }
  }

  Future<void> _processJob(PrintJobEntity job) async {
    PrinterEntity? printer;
    try {
      final printers =
          (await _repo.watchPrinters(venueId).first).where((p) => p.isConfigured).toList();
      // 1) Por id concreto
      for (final p in printers) {
        if (p.id == job.printerId) {
          printer = p;
          break;
        }
      }
      // 2) Por espacio de trabajo (p. ej. Cocina)
      if (printer == null && job.workspace.isNotEmpty) {
        for (final p in printers) {
          if (p.workspaces.contains(job.workspace)) {
            printer = p;
            break;
          }
        }
      }
      // 3) Principal, 4) primera configurada
      if (printer == null) {
        for (final p in printers) {
          if (p.isPrincipal) {
            printer = p;
            break;
          }
        }
      }
      printer ??= printers.isNotEmpty ? printers.first : null;
    } catch (_) {}

    if (printer == null) {
      await _repo.finishJob(
        venueId: venueId,
        jobId: job.id,
        ok: false,
        error: 'Impresora no configurada en este dispositivo',
      );
      return;
    }

    final target = printer;
    final ok = await PrinterService.printHex(target, job.escPosHex);
    await _repo.finishJob(
      venueId: venueId,
      jobId: job.id,
      ok: ok,
      error: ok ? null : 'Sin conexión con ${target.ip}',
    );
  }
}
