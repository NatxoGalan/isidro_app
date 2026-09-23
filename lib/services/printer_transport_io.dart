import 'dart:async';
import 'dart:io';

Future<bool> tcpCheck(String ip, int port, Duration timeout) async {
  try {
    final socket = await Socket.connect(ip, port, timeout: timeout);
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> tcpPrint(
  String ip,
  int port,
  List<int> data,
  Duration timeout,
) async {
  try {
    final socket = await Socket.connect(ip, port, timeout: timeout);
    socket.add(data);
    await socket.flush();
    await Future.delayed(const Duration(milliseconds: 500));
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}
