import 'dart:convert';

import 'ws_client.dart';
import 'rx_ws.dart';

/// Native platform implementation of [WsClient] for Android, iOS, macOS, Windows, and Linux.
/// 
/// [WsClientIO] uses the `dart:io` Socket and SecureSocket classes to provide
/// native WebSocket connectivity on all non-web Dart platforms.
/// 
/// ## Platform Support
/// 
/// This implementation is automatically used on:
/// - **Android** - via Flutter engine's Dart VM
/// - **iOS** - via Flutter engine's Dart VM
/// - **macOS** - via Dart SDK native runtime
/// - **Windows** - via Dart SDK native runtime
/// - **Linux** - via Dart SDK native runtime
/// - **Flutter Desktop** - on all desktop platforms
/// - **Dart Server** - via dart:io
/// 
/// ## Features
/// 
/// - Complete RFC 6455 WebSocket protocol implementation
/// - Automatic TLS/SSL support for `wss://` connections
/// - Built-in certificate validation
/// - Auto-reconnection with exponential backoff
/// - Heartbeat mechanism to detect dead connections
/// - Message fragmentation handling
/// - Backpressure-aware message queuing
/// - Custom HTTP headers support
/// 
/// ## How It Works
/// 
/// [WsClientIO] wraps the internal [RxWs] implementation which:
/// 1. Initiates a TCP connection using `Socket.connect()` or `SecureSocket.connect()`
/// 2. Performs WebSocket protocol handshake (HTTP upgrade)
/// 3. Parses incoming WebSocket frames according to RFC 6455
/// 4. Manages connection state and automatic reconnection
/// 5. Provides stream-based API for all events
/// 
/// ## Usage Example
/// 
/// ```dart
/// import 'package:rxws/rxws.dart';
/// 
/// void main() async {
///   final client = createWsClient(); // Returns WsClientIO on native platforms
///   
///   client.onOpen.listen((_) {
///     print('Connected to server');
///     client.send('Hello from native app!');
///   });
///   
///   client.onMessage.listen((message) {
///     print('Received: $message');
///   });
///   
///   client.onClose.listen((_) {
///     print('Connection closed');
///   });
///   
///   await client.connect('wss://echo.websocket.org/');
/// }
/// ```
/// 
/// ## Connection Details
/// 
/// ### URL Schemes
/// 
/// - `ws://` - Plain WebSocket (port 80 by default)
/// - `wss://` - Secure WebSocket with TLS/SSL (port 443 by default)
/// 
/// ### Handshake Process
/// 
/// 1. Opens TCP socket to host:port
/// 2. For `wss://`, initiates TLS handshake
/// 3. Sends HTTP upgrade request with:
///    - `Upgrade: websocket` header
///    - `Sec-WebSocket-Key` (random 16-byte base64-encoded value)
///    - `Sec-WebSocket-Version: 13` (RFC 6455 standard)
///    - Any custom headers provided
/// 4. Validates server response (HTTP 101 Switching Protocols)
/// 5. Validates `Sec-WebSocket-Accept` header
/// 6. Transitions to open state
/// 
/// ### TLS/SSL Certificate Validation
/// 
/// For `wss://` connections:
/// - Certificate chain is validated against system trust store
/// - Invalid certificates are rejected
/// - Self-signed certificates require additional configuration via `SecurityContext`
/// 
/// ### Automatic Reconnection
/// 
/// The underlying [RxWs] automatically reconnects on connection loss with:
/// - Exponential backoff: 1s, 2s, 4s, 8s, 16s, ...
/// - Default max retries: 10 (configurable)
/// - Automatic retry reset on successful connection
/// 
/// ## Performance Considerations
/// 
/// - **Memory**: Efficient frame parsing with minimal copying
/// - **CPU**: Non-blocking I/O using Dart's event loop
/// - **Network**: Support for backpressure prevents buffer overflow
/// - **Latency**: Direct native socket access provides low latency
/// 
/// ## Error Handling
/// 
/// Common errors and their causes:
/// 
/// ```dart
/// client.onError.listen((error) {
///   if (error is SocketException) {
///     // Network connectivity issue
///     print('Network error: ${error.message}');
///   } else if (error is HandshakeException) {
///     // TLS/SSL handshake failed
///     print('TLS error: $error');
///   } else {
///     // WebSocket protocol error
///     print('WebSocket error: $error');
///   }
/// });
/// ```
/// 
/// ## Thread Safety
/// 
/// [WsClientIO] operations should be called from the main Dart isolate.
/// All callbacks and streams operate within the Dart event loop context.
/// 
/// For multi-isolate communication, use Dart's port-based messaging.
/// 
/// ## Resource Cleanup
/// 
/// The underlying socket and timers are automatically cleaned up on:
/// - `client.close()` - User-initiated closure
/// - Connection loss - Followed by reconnection attempts
/// 
/// Ensure to properly dispose of client instances in cleanup methods:
/// 
/// ```dart
/// class MyApp extends StatefulWidget {
///   late WsClient client;
///   
///   @override
///   void initState() {
///     super.initState();
///     client = createWsClient();
///     client.connect('wss://example.com/ws');
///   }
///   
///   @override
///   void dispose() {
///     client.close(); // Cleanup on widget disposal
///     super.dispose();
///   }
/// }
/// ```
class WsClientIO implements WsClient {
  /// Internal RxWs implementation with auto-reconnection
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

/// Creates and returns an IO platform WebSocket client.
/// 
/// This function is called by [createWsClient] on native (non-web) platforms.
/// 
/// Returns: A new [WsClientIO] instance with auto-reconnection enabled.
WsClient createClient() => WsClientIO();
