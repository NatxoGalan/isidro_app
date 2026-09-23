/// Transporte TCP hacia impresoras de red.
 /// En web (sin sockets raw) usa stub que siempre falla; el relay
/// Firestore se encarga de imprimir desde un dispositivo con red.
export 'printer_transport_io.dart'
    if (dart.library.html) 'printer_transport_web.dart';
