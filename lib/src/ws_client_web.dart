import 'dart:async';
import 'package:web/web.dart' as web;
import 'dart:convert';
import 'dart:js_interop';
import 'ws_client.dart';

/// Web platform implementation of [WsClient] using the official `package:web`
class WsClientWeb implements WsClient {
  web.WebSocket? _ws;

  bool _isConnected = false;

  final _onOpen = StreamController<void>.broadcast();
  final _onClose = StreamController<void>.broadcast();
  final _onMessage = StreamController<dynamic>.broadcast();
  final _onError = StreamController<dynamic>.broadcast();

  final _stateController = StreamController<WSState>.broadcast();

  /// Update connection state and notify listeners
  void _setState(WSState s) {
    _stateController.add(s);
  }

  @override
  bool get isConnected => _isConnected && _ws?.readyState == web.WebSocket.OPEN;

  @override
  Future<void> connect(String url) async {
    _dispose();
    _setState(WSState.connecting);

    try {
      _ws = web.WebSocket(url);

      // Connection opened
      _ws!.onOpen.listen((_) {
        _isConnected = true;
        _setState(WSState.open);
        _onOpen.add(null);
      });
      // Received message
      _ws!.onMessage.listen((web.MessageEvent event) {
        _onMessage.add(event.data);
      });

      // Connection closed
      _ws!.onClose.listen((web.CloseEvent event) {
        _isConnected = false;
        _setState(WSState.closed);
        _onClose.add(null);
      });
      // Error occurred
      _ws!.onError.listen((web.Event event) {
        _onError.add('WebSocket error occurred');
      });
    } catch (e) {
      _onError.add(e);
      _setState(WSState.closed);
      rethrow;
    }
  }

  @override
  void send(String data) {
    if (isConnected) {
      _ws?.send(data.toJS);
    } else {
      _onError.add('WebSocket is not connected');
    }
  }

  @override
  void sendJson(Map<String, dynamic> json) {
    send(jsonEncode(json));
  }

  @override
  void close() {
    _setState(WSState.closing);
    _ws?.close();
    _isConnected = false;
  }

  @override
  Stream<WSState> get onState => _stateController.stream;

  @override
  void closeWithCode(int code, [String? reason]) {
    _ws?.close(code, reason ?? "");
    _isConnected = false;
  }

  /// Dispose all stream controllers and resources
  void _dispose() {
    _ws?.close();
    _ws = null;
    _isConnected = false;
  }

  @override
  Stream<void> get onOpen => _onOpen.stream;
  @override
  Stream<void> get onClose => _onClose.stream;
  @override
  Stream<dynamic> get onMessage => _onMessage.stream;
  @override
  Stream<dynamic> get onError => _onError.stream;

  void dispose() {
    _dispose();
    _onOpen.close();
    _onClose.close();
    _onMessage.close();
    _onError.close();
    _stateController.close();
  }
}

/// Create a Web platform WebSocket client
WsClient createClient() => WsClientWeb();
