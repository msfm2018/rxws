import 'dart:convert';

import 'ws_client.dart';
import 'rx_ws.dart';

/// IO platform implementation of [WsClient]
class WsClientIO implements WsClient {
  final RxWs _ws = RxWs(autoReconnect: true, maxRetry: 10);

  @override
  bool get isConnected => _ws.isConnected;

  @override
  Future<void> connect(String url) async {
    await _ws.connect(url);
  }

  @override
  void send(String data) {
    _ws.sendText(data);
  }

  @override
  void sendJson(Map<String, dynamic> json) {
    send(jsonEncode(json));
  }

  @override
  void close() {
    _ws.close();
  }

  @override
  void closeWithCode(int code, [String? reason]) {
    close();
  }

  @override
  Stream<void> get onOpen => _ws.onOpen;

  @override
  Stream<void> get onClose => _ws.onClose;

  @override
  Stream get onMessage => _ws.messages;

  @override
  Stream get onError => _ws.onError;

  @override
  Stream<WSState> get onState => _ws.states;
}

/// Create IO platform WebSocket client
WsClient createClient() => WsClientIO();
