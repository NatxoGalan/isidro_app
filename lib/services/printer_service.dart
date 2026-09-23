import 'dart:async';
import 'dart:io';
import '../data/models/printer_dto.dart';

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
      final socket = await Socket.connect(
        printer.ip.trim(),
        printer.port,
        timeout: timeout,
      );
      socket.destroy();
      return PrinterConnectionStatus.connected;
    } on SocketException {
      return PrinterConnectionStatus.disconnected;
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
    try {
      final socket = await Socket.connect(
        printer.ip.trim(),
        printer.port,
        timeout: timeout,
      );
      socket.add(data);
      await socket.flush();
      // Dar tiempo a la impresora a procesar antes de cerrar.
      await Future.delayed(const Duration(milliseconds: 500));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
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
