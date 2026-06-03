import 'dart:async';
import 'package:web/web.dart' as web;
import 'dart:convert';
import 'dart:js_interop';
import 'ws_client.dart';

/// Web platform implementation of [WsClient] using the browser WebSocket API.
/// 
/// [WsClientWeb] provides WebSocket connectivity on all web browsers by wrapping
/// the native browser WebSocket API (via the `package:web` package).
/// 
/// ## Browser Support
/// 
/// This implementation works on all modern browsers:
/// - **Chrome/Chromium** 43+
/// - **Firefox** 11+
/// - **Safari** 7+
/// - **Edge** 12+
/// - **Opera** 30+
/// - **Mobile browsers** (iOS Safari, Chrome Mobile, Firefox Mobile, Samsung Internet)
/// 
/// WebSocket support is automatically handled by the browser, making this
/// implementation very robust and standards-compliant.
/// 
/// ## Features
/// 
/// - **Native browser WebSocket** - Uses the browser's native WebSocket implementation
/// - **Automatic CORS handling** - Browser handles Cross-Origin Resource Sharing
/// - **Browser security** - Subject to browser security policies and same-origin rules
/// - **Standards compliant** - Fully compliant with RFC 6455
/// - **Zero additional latency** - Direct browser API access
/// - **Automatic message decoding** - Browser handles text/binary messages
/// 
/// ## How It Works
/// 
/// [WsClientWeb] wraps the browser's native `WebSocket` object and translates
/// its events into Dart streams:
/// 
/// 1. Creates a `web.WebSocket(url)` instance
/// 2. Listens to browser events: `onOpen`, `onMessage`, `onClose`, `onError`
/// 3. Converts events to Dart streams via `StreamController`
/// 4. Provides the same API as native platforms via [WsClient] interface
/// 
/// ## Usage Example
/// 
/// ```dart
/// import 'package:rxws/rxws.dart';
/// 
/// void main() {
///   final client = createWsClient(); // Returns WsClientWeb in browser
///   
///   client.onOpen.listen((_) {
///     print('Connected to WebSocket server');
///     client.send('Hello from web!');
///   });
///   
///   client.onMessage.listen((message) {
///     print('Server says: $message');
///   });
///   
///   client.onError.listen((error) {
///     print('Connection error: $error');
///   });
///   
///   client.onClose.listen((_) {
///     print('Disconnected');
///   });
///   
///   // Connect to server
///   await client.connect('wss://echo.websocket.org/');
/// }
/// ```
/// 
/// ## CORS and Same-Origin Policy
/// 
/// WebSocket connections are subject to browser security policies:
/// 
/// ### Same-Origin Connections
/// 
/// WebSocket URL on same origin as page:
/// ```dart
/// // If page is at https://example.com
/// await client.connect('wss://example.com/ws');  // ✅ Allowed
/// ```
/// 
/// ### Cross-Origin Connections
/// 
/// WebSocket connections to different origins require CORS:
/// ```dart
/// // If page is at https://example.com
/// await client.connect('wss://api.other.com/ws');  // Requires CORS
/// ```
/// 
/// The server must include proper CORS headers in the WebSocket upgrade response.
/// 
/// ## Message Handling
/// 
/// The browser automatically handles message type conversion:
/// 
/// ### Text Messages
/// 
/// ```dart
/// client.send('Hello'); // Sends as text frame
/// 
/// client.onMessage.listen((message) {
///   if (message is String) {
///     print('Text: $message');
///   }
/// });
/// ```
/// 
/// ### Binary Messages
/// 
/// ```dart
/// import 'dart:typed_data';
/// 
/// // Send binary
/// final data = Uint8List.fromList([1, 2, 3, 4]);
/// client.send(data.toString()); // Convert to string first
/// 
/// // Receive binary
/// client.onMessage.listen((message) {
///   if (message is! String) {
///     print('Binary data received: $message');
///   }
/// });
/// ```
/// 
/// ## Connection State Management
/// 
/// [WsClientWeb] tracks four connection states:
/// 
/// - **`WSState.closed`** - Initial state, no connection
/// - **`WSState.connecting`** - Connection attempt in progress
/// - **`WSState.open`** - Connected and ready for communication
/// - **`WSState.closing`** - Close initiated, awaiting completion
/// 
/// State transitions are emitted via the [onState] stream.
/// 
/// ## Connection Close Codes
/// 
/// When closing, the browser supports standard WebSocket close codes:
/// 
/// ```dart
/// // Normal closure
/// client.closeWithCode(1000, 'Goodbye');
/// 
/// // Going away
/// client.closeWithCode(1001, 'Page unload');
/// 
/// // Protocol error
/// client.closeWithCode(1002);
/// 
/// // Service restart
/// client.closeWithCode(1012);
/// ```
/// 
/// The server will receive the close code and reason, allowing proper cleanup.
/// 
/// ## Browser Developer Tools
/// 
/// Debug WebSocket connections using browser developer tools:
/// 
/// 1. **Chrome DevTools** → Network tab → Filter by WS (WebSocket)
/// 2. **Firefox Developer Tools** → Network → Right-click column header → WS
/// 3. **Safari Web Inspector** → Network → WebSocket connections
/// 
/// View all frames (sent/received) with timestamps and data.
/// 
/// ## Performance Considerations
/// 
/// - **Latency**: Native browser implementation has minimal latency
/// - **Memory**: Browser manages buffer sizes automatically
/// - **CPU**: Efficient event-driven architecture
/// - **Throttling**: Browser may throttle background tabs (depends on browser)
/// 
/// ## Known Limitations
/// 
/// 1. **No custom headers** - Browser API doesn't allow custom HTTP headers
/// 2. **No binary protocol upgrade** - Only text frames are reliably supported
/// 3. **No ping/pong control** - Browser handles ping/pong automatically
/// 4. **Same-origin only** - Cross-origin requires CORS support
/// 5. **No reconnection** - Browser doesn't auto-reconnect; handled at app level
/// 
/// ## Error Handling
/// 
/// Common errors encountered in web:
/// 
/// ```dart
/// client.onError.listen((error) {
///   final message = error.toString();
///   
///   if (message.contains('security')) {
///     // CORS or security policy violation
///     print('Security error: Check CORS headers');
///   } else if (message.contains('connect')) {
///     // Connection refused or timeout
///     print('Connection error: Server not reachable');
///   } else {
///     print('Unknown error: $error');
///   }
/// });
/// ```
/// 
/// ## Server Requirements
/// 
/// For secure web connections (`wss://`), the server must:
/// 1. Have a valid SSL/TLS certificate
/// 2. Support WebSocket protocol upgrade
/// 3. Handle CORS if cross-origin connections are needed
/// 
/// Example Node.js server:
/// 
/// ```javascript
/// const WebSocket = require('ws');
/// 
/// const wss = new WebSocket.Server({ port: 443 });
/// 
/// wss.on('connection', (ws) => {
///   ws.on('message', (message) => {
///     console.log('received:', message);
///     ws.send('echo: ' + message);
///   });
/// });
/// ```
/// 
/// ## Resource Cleanup
/// 
/// Properly clean up WebSocket connections to avoid memory leaks:
/// 
/// ```dart
/// class WebSocketWidget extends StatefulWidget {
///   @override
///   State<WebSocketWidget> createState() => _WebSocketWidgetState();
/// }
/// 
/// class _WebSocketWidgetState extends State<WebSocketWidget> {
///   late WsClient client;
///   late StreamSubscription messageSubscription;
///   
///   @override
///   void initState() {
///     super.initState();
///     _initializeWebSocket();
///   }
///   
///   Future<void> _initializeWebSocket() async {
///     client = createWsClient();
///     
///     messageSubscription = client.onMessage.listen((message) {
///       setState(() {
///         // Update UI with message
///       });
///     });
///     
///     await client.connect('wss://example.com/ws');
///   }
///   
///   @override
///   void dispose() {
///     client.close();
///     messageSubscription.cancel();
///     super.dispose();
///   }
/// }
/// ```
class WsClientWeb implements WsClient {
  /// Underlying browser WebSocket object (can be null before connection)
  web.WebSocket? _ws;

  /// Flag to track connection status
  bool _isConnected = false;

  /// Stream controller for connection open events
  final _onOpen = StreamController<void>.broadcast();
  
  /// Stream controller for connection close events
  final _onClose = StreamController<void>.broadcast();
  
  /// Stream controller for incoming messages
  final _onMessage = StreamController<dynamic>.broadcast();
  
  /// Stream controller for error events
  final _onError = StreamController<dynamic>.broadcast();

  /// Stream controller for state change events
  final _stateController = StreamController<WSState>.broadcast();

  /// Updates connection state and notifies listeners.
  /// 
  /// This method is called internally when the connection state changes
  /// due to browser WebSocket events.
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
      /// Create browser WebSocket instance
      _ws = web.WebSocket(url);

      /// Listen for connection open event
      _ws!.onOpen.listen((_) {
        _isConnected = true;
        _setState(WSState.open);
        _onOpen.add(null);
      });

      /// Listen for incoming messages
      _ws!.onMessage.listen((web.MessageEvent event) {
        _onMessage.add(event.data);
      });

      /// Listen for connection close event
      _ws!.onClose.listen((web.CloseEvent event) {
        _isConnected = false;
        _setState(WSState.closed);
        _onClose.add(null);
      });

      /// Listen for error events
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
      /// Send data to server using browser WebSocket API
      /// The toJS extension converts Dart String to JavaScript string
      _ws?.send(data.toJS);
    } else {
      _onError.add('WebSocket is not connected');
    }
  }

  @override
  void sendJson(Map<String, dynamic> json) {
    /// Encode map to JSON string and send as text message
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
    /// Close with WebSocket close code and optional reason
    /// Browser will send these values in the close frame to the server
    _ws?.close(code, reason ?? "");
    _isConnected = false;
  }

  /// Disposes all resources including WebSocket and stream controllers.
  /// 
  /// This method should be called when the WebSocket connection is no longer needed
  /// to prevent resource leaks and orphaned event listeners.
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

  /// Cleans up all stream controllers and resources.
  /// 
  /// Call this method in the dispose/cleanup phase of your application
  /// to ensure proper resource cleanup and prevent memory leaks.
  /// 
  /// After calling this method, the client should not be used.
  void dispose() {
    _dispose();
    _onOpen.close();
    _onClose.close();
    _onMessage.close();
    _onError.close();
    _stateController.close();
  }
}

/// Creates and returns a Web platform WebSocket client.
/// 
/// This function is called by [createWsClient] on web platforms (browsers).
/// 
/// The returned [WsClientWeb] instance uses the browser's native WebSocket API
/// and is automatically selected when building for web targets.
/// 
/// Returns: A new [WsClientWeb] instance ready for WebSocket connections.
WsClient createClient() => WsClientWeb();
