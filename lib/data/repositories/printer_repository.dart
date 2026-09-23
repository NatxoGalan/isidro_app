import '../models/printer_dto.dart';
import '../models/print_job_dto.dart';
import '../datasources/firebase_firestore_datasource.dart';

class PrinterRepository {
  final FirebaseFirestoreDatasource _datasource;

  PrinterRepository({FirebaseFirestoreDatasource? datasource})
      : _datasource = datasource ?? FirebaseFirestoreDatasource();

  Stream<List<PrinterEntity>> watchPrinters(String venueId) {
    return _datasource.watchPrinters(venueId);
  }

  Future<String> addPrinter({
    required String venueId,
    required String name,
    required String ip,
    int port = 9100,
    bool isPrincipal = false,
    List<String> workspaces = const [],
  }) async {
    return _datasource.addPrinter(venueId, {
      'venueId': venueId,
      'name': name,
      'ip': ip,
      'port': port,
      'isPrincipal': isPrincipal,
      'workspaces': workspaces,
    });
  }

  Future<void> updatePrinter({
    required String venueId,
    required String printerId,
    required Map<String, dynamic> data,
  }) async {
    await _datasource.updatePrinter(venueId, printerId, data);
  }

  Future<void> deletePrinter({
    required String venueId,
    required String printerId,
  }) async {
    await _datasource.deletePrinter(venueId, printerId);
  }

  /// Marca una impresora como principal (desmarca las demás con batch).
  Future<void> setPrincipal({
    required String venueId,
    required List<PrinterEntity> printers,
    required String printerId,
  }) async {
    final batch = _datasource.firestore.batch();
    final ref = _datasource.firestore
        .collection('venues')
        .doc(venueId)
        .collection('printers');
    for (final p in printers) {
      batch.update(ref.doc(p.id), {'isPrincipal': p.id == printerId});
    }
    await batch.commit();
  }

  Stream<List<PrintJobEntity>> watchPendingJobs(String venueId) {
    return _datasource.watchPendingJobs(venueId);
  }

  Stream<List<PrintJobEntity>> watchRecentJobs(String venueId) {
    return _datasource.watchRecentJobs(venueId);
  }

  Future<String> enqueueJob({
    required String venueId,
    required String printerId,
    String printerName = '',
    String workspace = '',
    required String type,
    String tableNumber = '',
    required String escPosHex,
    required String createdBy,
  }) async {
    return _datasource.addPrintJob(venueId, {
      'venueId': venueId,
      'printerId': printerId,
      'printerName': printerName,
      'workspace': workspace,
      'type': type,
      'tableNumber': tableNumber,
      'escPosHex': escPosHex,
      'status': PrintJobStatus.pending.name,
      'createdBy': createdBy,
      'claimedBy': null,
      'createdAt': DateTime.now(),
      'printedAt': null,
      'error': null,
    });
  }

  Future<bool> claimJob({
    required String venueId,
    required String jobId,
    required String deviceId,
  }) {
    return _datasource.claimPrintJob(venueId, jobId, deviceId);
  }

  Future<void> finishJob({
    required String venueId,
    required String jobId,
    required bool ok,
    String? error,
  }) {
    return _datasource.finishPrintJob(venueId, jobId, ok: ok, error: error);
  }

  Future<void> requeueJob({
    required String venueId,
    required String jobId,
  }) {
    return _datasource.requeuePrintJob(venueId, jobId);
  }

  Future<void> deleteJob({
    required String venueId,
    required String jobId,
  }) {
    return _datasource.deletePrintJob(venueId, jobId);
  }

  Future<void> cleanOldJobs(String venueId) {
    return _datasource.deleteOldJobs(
      venueId,
      DateTime.now().subtract(const Duration(hours: 24)),
    );
  }

  /// Crea las impresoras por defecto si no hay ninguna.
  Future<void> seedIfEmpty(String venueId) async {
    final current = await watchPrinters(venueId).first;
    if (current.isNotEmpty) return;
    await addPrinter(
      venueId: venueId,
      name: 'Barra',
      ip: '',
      isPrincipal: true,
      workspaces: const [PrinterWorkspace.bar],
    );
    await addPrinter(
      venueId: venueId,
      name: 'Cocina',
      ip: '',
      workspaces: const [PrinterWorkspace.kitchen],
    );
  }
}
