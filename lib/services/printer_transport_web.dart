/// Stub para web: sin sockets TCP, todo va por relay Firestore.
Future<bool> tcpCheck(String ip, int port, Duration timeout) async => false;

Future<bool> tcpPrint(
  String ip,
  int port,
  List<int> data,
  Duration timeout,
) async =>
    false;
