enum WSState { connecting, open, closing, closed }

abstract class WsClient {
  Future<void> connect(String url);

  void send(String data);
  void sendJson(Map<String, dynamic> json);
  void close();
  void closeWithCode(int code, [String? reason]);

  Stream<void> get onOpen;
  Stream<void> get onClose;
  Stream<dynamic> get onMessage;
  Stream<dynamic> get onError;

  Stream<WSState> get onState;

  bool get isConnected;
}
