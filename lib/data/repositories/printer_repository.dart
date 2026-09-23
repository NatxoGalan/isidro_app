import '../models/printer_dto.dart';
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
