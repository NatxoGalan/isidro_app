import 'dart:typed_data';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

enum PrinterConnectionStatus {
  checking,
  connected,
  disconnected,
  error,
}

class PrinterService {
  static final SunmiPrinterPlus _printer = SunmiPrinterPlus();
  static bool _initialized = false;
  static PrinterConnectionStatus _status = PrinterConnectionStatus.disconnected;

  static PrinterConnectionStatus get status => _status;

  /// Inicializa el binding con el servicio de impresión Sunmi
  static Future<bool> init() async {
    try {
      await _printer.rebindPrinter();
      _initialized = true;
      return true;
    } catch (_) {
      _initialized = false;
      return false;
    }
  }

  /// Verifica si la impresora está conectada y lista
  static Future<PrinterConnectionStatus> checkConnection() async {
    _status = PrinterConnectionStatus.checking;

    try {
      if (!_initialized) {
        final ok = await init();
        if (!ok) {
          _status = PrinterConnectionStatus.disconnected;
          return _status;
        }
      }

      final statusResult = await _printer.getStatus();

      if (statusResult != null && statusResult.toUpperCase().contains('READY')) {
        _status = PrinterConnectionStatus.connected;
      } else {
        _status = PrinterConnectionStatus.connected;
      }
    } catch (_) {
      _initialized = false;
      _status = PrinterConnectionStatus.error;
    }

    return _status;
  }

  /// Imprime datos ESC/POS raw (bytes)
  static Future<bool> printEscPos(List<int> data) async {
    try {
      if (_status != PrinterConnectionStatus.connected) {
        final result = await checkConnection();
        if (result != PrinterConnectionStatus.connected) return false;
      }

      await _printer.printEscPos(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Imprime ticket desde hex string ESC/POS
  static Future<bool> printTicket(String escPosHex) async {
    try {
      final bytes = _hexToBytes(escPosHex);
      return await printEscPos(bytes);
    } catch (_) {
      return false;
    }
  }

  /// Corta el papel
  static Future<void> cutPaper() async {
    try {
      await _printer.cutPaper();
    } catch (_) {}
  }

  /// Reconecta la impresora
  static Future<bool> reconnect() async {
    _initialized = false;
    _status = PrinterConnectionStatus.disconnected;
    return await init();
  }

  /// Convierte hex string a bytes
  static Uint8List _hexToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      final byte = int.parse(hex.substring(i, i + 2), radix: 16);
      bytes.add(byte);
    }
    return Uint8List.fromList(bytes);
  }
}
