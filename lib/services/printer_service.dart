import 'dart:async';
import '../data/models/printer_dto.dart';
import 'printer_transport.dart';

enum PrinterConnectionStatus {
  checking,
  connected,
  disconnected,
  error,
}

/// Impresión real en impresoras térmicas de red (WiFi) por TCP puerto 9100.
class PrinterService {
  static const Duration _defaultTimeout = Duration(seconds: 3);

  /// Comprueba si la impresora responde en su IP:puerto.
  static Future<PrinterConnectionStatus> checkConnection(
    PrinterEntity printer, {
    Duration timeout = _defaultTimeout,
  }) async {
    if (!printer.isConfigured) return PrinterConnectionStatus.disconnected;
    try {
      final ok = await tcpCheck(printer.ip.trim(), printer.port, timeout);
      return ok
          ? PrinterConnectionStatus.connected
          : PrinterConnectionStatus.disconnected;
    } on TimeoutException {
      return PrinterConnectionStatus.disconnected;
    } catch (_) {
      return PrinterConnectionStatus.error;
    }
  }

  /// Envía bytes ESC/POS a la impresora.
  static Future<bool> printBytes(
    PrinterEntity printer,
    List<int> data, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!printer.isConfigured) return false;
    return tcpPrint(printer.ip.trim(), printer.port, data, timeout);
  }

  /// Convierte hex string ESC/POS a bytes e imprime.
  static Future<bool> printHex(PrinterEntity printer, String escPosHex) async {
    try {
      final bytes = <int>[];
      final hex = escPosHex.trim();
      for (var i = 0; i + 1 < hex.length; i += 2) {
        bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
      }
      return printBytes(printer, bytes);
    } catch (_) {
      return false;
    }
  }
}
