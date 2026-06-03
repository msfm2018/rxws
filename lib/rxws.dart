/// RxWs - A reliable, cross-platform WebSocket client for Dart & Flutter
/// 
/// This package exports the public API for WebSocket functionality across all platforms:
/// - Android, iOS, macOS, Windows, Linux (via dart:io)
/// - Web/Browsers (via package:web)
/// 
/// ## Quick Start
/// 
/// ```dart
/// import 'package:rxws/rxws.dart';
/// 
/// void main() async {
///   // Create a WebSocket client (platform automatically detected)
///   final client = createWsClient();
///   
///   // Listen for connection events
///   client.onOpen.listen((_) {
///     print('Connected!');
///     client.send('Hello Server');
///   });
///   
///   // Listen for incoming messages
///   client.onMessage.listen((message) {
///     print('Received: $message');
///   });
///   
///   // Listen for errors
///   client.onError.listen((error) {
///     print('Error: $error');
///   });
///   
///   // Connect to server
///   await client.connect('wss://echo.websocket.org/');
/// }
/// ```
/// 
/// ## Core Exports
/// 
/// This library exports:
/// 
/// - [WsClient] - Abstract interface for WebSocket clients
/// - [WSState] - Connection state enum
/// - [createWsClient] - Factory function to create platform-specific clients
/// 
/// ## Platform Support
/// 
/// The library automatically selects the correct implementation based on platform:
/// 
/// | Platform | Implementation | Technology |
/// |----------|-----------------|-----------|
/// | Android  | WsClientIO | dart:io Socket |
/// | iOS      | WsClientIO | dart:io Socket |
/// | macOS    | WsClientIO | dart:io Socket |
/// | Windows  | WsClientIO | dart:io Socket |
/// | Linux    | WsClientIO | dart:io Socket |
/// | Web      | WsClientWeb | Browser WebSocket API |
/// 
/// ## Features
/// 
/// ✅ **Cross-Platform** - Single API works on all platforms
/// ✅ **Auto-Reconnection** - Automatic retry with exponential backoff
/// ✅ **Heartbeat** - Built-in ping/pong mechanism
/// ✅ **Stream-Based** - Dart async/await compatible
/// ✅ **Error Handling** - Comprehensive error streams
/// ✅ **Text & Binary** - Support for both message types
/// ✅ **RFC 6455** - Full WebSocket protocol compliance
/// ✅ **Backpressure** - Queue-based message sending
/// 
/// ## Connection Management
/// 
/// ### Creating a Client
/// 
/// ```dart
/// final client = createWsClient();
/// ```
/// 
/// ### Connecting
/// 
/// ```dart
/// // Basic connection
/// await client.connect('wss://example.com/ws');
/// 
/// // With custom headers (native platforms only)
/// await client.connect(
///   'wss://example.com/ws',
///   headers: {'Authorization': 'Bearer token'}
/// );
/// ```
/// 
/// ### Sending Messages
/// 
/// ```dart
/// // Text message
/// client.send('Hello');
/// 
/// // JSON message
/// client.sendJson({'type': 'ping', 'data': 'test'});
/// ```
/// 
/// ### Closing
/// 
/// ```dart
/// // Simple close
/// client.close();
/// 
/// // Close with code and reason
/// client.closeWithCode(1000, 'Normal closure');
/// ```
/// 
/// ## Event Streams
/// 
/// All events are exposed as streams:
/// 
/// ```dart
/// // Connection opened
/// client.onOpen.listen((_) => print('Connected'));
/// 
/// // Incoming messages
/// client.onMessage.listen((msg) => print('Message: $msg'));
/// 
/// // Connection closed
/// client.onClose.listen((_) => print('Disconnected'));
/// 
/// // Errors
/// client.onError.listen((err) => print('Error: $err'));
/// 
/// // State changes
/// client.onState.listen((state) {
///   print('State: $state'); // connecting, open, closing, closed
/// });
/// ```
/// 
/// ## Common Use Cases
/// 
/// ### Real-Time Chat Application
/// 
/// ```dart
/// class ChatService {
///   late WsClient _ws;
///   
///   Future<void> initialize() async {
///     _ws = createWsClient();
///     
///     _ws.onOpen.listen((_) {
///       _ws.sendJson({'action': 'login', 'token': authToken});
///     });
///     
///     _ws.onMessage.listen(_handleMessage);
///     _ws.onError.listen(_handleError);
///     _ws.onClose.listen((_) => _reconnect());
///     
///     await _ws.connect('wss://api.example.com/chat');
///   }
///   
///   void sendMessage(String text) {
///     _ws.sendJson({'type': 'message', 'text': text});
///   }
///   
///   void _handleMessage(dynamic data) {
///     final message = jsonDecode(data);
///     print('${message['user']}: ${message['text']}');
///   }
/// }
/// ```
/// 
/// ### Real-Time Stock Price Updates
/// 
/// ```dart
/// class StockPriceService {
///   late WsClient _ws;
///   final prices = StreamController<Map<String, double>>();
///   
///   Future<void> connect() async {
///     _ws = createWsClient();
///     
///     _ws.onOpen.listen((_) {
///       // Subscribe to stock updates
///       _ws.sendJson({
///         'action': 'subscribe',
///         'symbols': ['AAPL', 'GOOGL', 'MSFT']
///       });
///     });
///     
///     _ws.onMessage.listen((data) {
///       final update = jsonDecode(data);
///       prices.add({
///         update['symbol']: update['price']
///       });
///     });
///     
///     await _ws.connect('wss://api.example.com/stocks');
///   }
/// }
/// ```
/// 
/// ### IoT Device Communication
/// 
/// ```dart
/// class IoTDevice {
///   late WsClient _ws;
///   
///   Future<void> connect(String deviceId) async {
///     _ws = createWsClient();
///     
///     _ws.onOpen.listen((_) {
///       _sendCommand('initialize', {'device_id': deviceId});
///     });
///     
///     _ws.onMessage.listen(_processDeviceData);
///     _ws.onState.listen(_updateDeviceStatus);
///     
///     await _ws.connect('wss://iot.example.com/devices');
///   }
///   
///   void _sendCommand(String action, Map<String, dynamic> data) {
///     _ws.sendJson({
///       'action': action,
///       'data': data,
///       'timestamp': DateTime.now().toIso8601String()
///     });
///   }
/// }
/// ```
/// 
/// ## State Enum
/// 
/// Connection states are represented by [WSState]:
/// 
/// - **closed** - No connection (initial state)
/// - **connecting** - Connection attempt in progress
/// - **open** - Connected and ready
/// - **closing** - Graceful close in progress
/// 
/// ## Platform-Specific Details
/// 
/// ### Native Platforms (iOS, Android, macOS, Windows, Linux)
/// 
/// - Auto-reconnection with exponential backoff (1s, 2s, 4s, 8s...)
/// - Up to 10 retry attempts (configurable)
/// - Heartbeat ping every 10 seconds
/// - 5-second timeout for pong response
/// - Full RFC 6455 compliance
/// - TLS/SSL certificate validation
/// 
/// ### Web Platform (Browsers)
/// 
/// - Uses browser's native WebSocket API
/// - CORS automatically handled by browser
/// - Subject to browser security policies
/// - No custom headers in handshake (browser limitation)
/// - Automatic message type detection
/// - Same API as native platforms
/// 
/// ## Performance Tips
/// 
/// 1. **Reuse clients** - Create once, reuse throughout app lifecycle
/// 2. **Batch messages** - Send related messages together
/// 3. **Use JSON for structured data** - More efficient than string parsing
/// 4. **Monitor state** - Use state stream to avoid sending on closed connections
/// 5. **Clean up subscriptions** - Cancel stream subscriptions when done
/// 
/// ## Error Handling
/// 
/// ```dart
/// client.onError.listen((error) {
///   if (error is SocketException) {
///     print('Network error: ${error.message}');
///   } else if (error.toString().contains('security')) {
///     print('Security/CORS error');
///   } else {
///     print('WebSocket error: $error');
///   }
/// });
/// ```
/// 
/// ## Requirements
/// 
/// - **Dart**: 3.0.6 or higher
/// - **Flutter**: 1.17.0 or higher (for Flutter apps)
/// 
/// ## Documentation
/// 
/// For detailed API documentation, see:
/// - [WsClient] - Main interface documentation
/// - [WSState] - State enum documentation
/// - README.md - Full feature documentation
/// 
/// ## Links
/// 
/// - **GitHub**: https://github.com/msfm2018/rxws
/// - **Pub.dev**: https://pub.dev/packages/rxws
/// - **Issues**: https://github.com/msfm2018/rxws/issues

export 'src/ws_client_factory.dart';
export 'src/ws_client.dart';
