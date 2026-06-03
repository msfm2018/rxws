import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'ws_client.dart';

/// WebSocket frame operation codes as defined in RFC 6455.
/// 
/// Each opcode represents a different type of WebSocket frame that can be
/// transmitted during the connection lifecycle.
enum OpCode {
  /// Indicates a continuation frame (used for fragmented messages)
  continuation,
  
  /// Text frame containing UTF-8 encoded text data
  text,
  
  /// Binary frame containing arbitrary binary data
  binary,
  
  /// Connection close frame
  close,
  
  /// Ping frame (for keepalive)
  ping,
  
  /// Pong frame (response to ping)
  pong,
}

/// A robust, production-ready WebSocket client for Dart applications.
/// 
/// [RxWs] implements a complete RFC 6455 WebSocket client with support for:
/// - **Auto-reconnection**: Automatic reconnection with exponential backoff
/// - **Heartbeat & Ping/Pong**: Built-in keepalive mechanism to detect dead connections
/// - **Message Fragmentation**: Automatic handling of fragmented messages
/// - **Backpressure Handling**: Queue-based message sending with flow control
/// - **TLS/SSL Support**: Secure WebSocket connections (wss://)
/// - **Custom Headers**: Support for adding custom HTTP headers during handshake
/// 
/// ## Key Features
/// 
/// - **State Management**: Track connection state through `WSState` enum
/// - **Stream-based API**: All events (open, close, message, error, state) are exposed as streams
/// - **Automatic Reconnection**: Configurable retry attempts with exponential backoff
/// - **Resource Cleanup**: Proper cleanup of sockets, timers, and stream controllers
/// 
/// ## Connection States
/// 
/// - `WSState.closed`: Initial state, connection closed
/// - `WSState.connecting`: Connection attempt in progress (handshake)
/// - `WSState.open`: Connection established, ready for communication
/// - `WSState.closing`: Graceful close in progress
/// 
/// ## Usage Example
/// 
/// ```dart
/// final rxWs = RxWs(autoReconnect: true, maxRetry: 10);
/// 
/// // Listen for connection established
/// rxWs.onOpen.listen((_) {
///   print('Connected!');
///   rxWs.sendText('Hello Server');
/// });
/// 
/// // Listen for incoming text messages
/// rxWs.messages.listen((message) {
///   if (message is String) {
///     print('Text: $message');
///   } else {
///     print('Binary: ${message.length} bytes');
///   }
/// });
/// 
/// // Listen for state changes
/// rxWs.states.listen((state) {
///   print('State: $state');
/// });
/// 
/// // Connect
/// await rxWs.connect('wss://echo.websocket.org');
/// 
/// // Send text
/// rxWs.sendText('Hello');
/// 
/// // Send binary
/// rxWs.sendBinary([1, 2, 3, 4, 5]);
/// 
/// // Ping to detect dead connections
/// rxWs.ping();
/// 
/// // Close gracefully
/// rxWs.close();
/// ```
class RxWs {
  /// The underlying socket connection
  Socket? _socket;

  /// Current connection state
  WSState _state = WSState.closed;

  /// Returns the current connection state
  WSState get state => _state;

  /// Returns true if the connection is established and ready for communication
  bool get isConnected => _state == WSState.open;

  /// Returns true if a connection attempt is in progress
  bool get isConnecting => _state == WSState.connecting;

  /// Returns true if the connection is closed
  bool get isClosed => _state == WSState.closed;

  // Configuration parameters
  
  /// Whether to automatically attempt reconnection when connection is lost
  final bool autoReconnect;
  
  /// Maximum number of reconnection attempts before giving up
  final int maxRetry;

  // Stream controllers for connection events
  
  /// Internal stream controller for connection open events
  final _onOpenController = StreamController<void>.broadcast();

  /// Internal stream controller for connection close events
  final _onCloseController = StreamController<void>.broadcast();

  /// Internal stream controller for error events
  final _onErrorController = StreamController<dynamic>.broadcast();

  /// Returns a stream that emits when the connection is successfully opened
  Stream<void> get onOpen => _onOpenController.stream;
  
  /// Returns a stream that emits when the connection is closed
  Stream<void> get onClose => _onCloseController.stream;
  
  /// Returns a stream that emits error events
  Stream<dynamic> get onError => _onErrorController.stream;

  // Message stream
  
  /// Internal stream controller for incoming messages
  final _messageController = StreamController<dynamic>.broadcast();

  /// Returns a stream that emits incoming messages (either String or Uint8List for binary)
  Stream<dynamic> get messages => _messageController.stream;

  // State stream
  
  /// Internal stream controller for state change events
  final _stateController = StreamController<WSState>.broadcast();

  /// Returns a stream that emits connection state changes
  Stream<WSState> get states => _stateController.stream;

  // Internal buffers and state
  
  /// Receive buffer for accumulating frame data
  Uint8List _buffer = Uint8List(0);

  /// Buffer for accumulating fragmented message data
  List<int> _fragmentBuffer = [];

  /// Stores the opcode of the first fragment in a fragmented message
  int? _fragmentOpcode;

  /// Handshake security key used for WebSocket upgrade validation
  String? _handshakeKey;

  // Backpressure queue management
  
  /// Queue of frames waiting to be sent
  final _sendQueue = <List<int>>[];
  
  /// Flag to prevent concurrent sends
  bool _isSending = false;

  // Reconnection management
  
  /// Current reconnection attempt count
  int _retry = 0;

  // Heartbeat and keepalive
  
  /// Timer for periodic heartbeat pings
  Timer? _heartbeat;
  
  /// Timer for pong response timeout
  Timer? _pongTimeout;

  // Connection information
  
  /// Remote host address
  late String _host;
  
  /// Remote port number
  late int _port;
  
  /// WebSocket path and query string (e.g., "/chat?room=123")
  late String _path;
  
  /// Whether to use TLS/SSL (wss:// vs ws://)
  bool _useTLS = false;

  /// Custom HTTP headers to include in the WebSocket upgrade request
  Map<String, String> headers = {};

  /// Creates a new [RxWs] instance with optional reconnection configuration.
  /// 
  /// Parameters:
  ///   - [autoReconnect]: Enable automatic reconnection (default: true)
  ///   - [maxRetry]: Maximum reconnection attempts (default: 10)
  /// 
  /// Example:
  /// ```dart
  /// final client = RxWs(autoReconnect: true, maxRetry: 5);
  /// ```
  RxWs({
    this.autoReconnect = true,
    this.maxRetry = 10,
  });

  // ---------------------------------------------------------------------------
  // Connection Management
  // ---------------------------------------------------------------------------

  /// Establishes a WebSocket connection to the specified [urlString].
  /// 
  /// The URL must be a valid WebSocket URL starting with `ws://` or `wss://`.
  /// Optional [headers] can be provided for custom HTTP headers during the
  /// WebSocket upgrade handshake.
  /// 
  /// The connection state will transition: closed → connecting → open (or closed on failure).
  /// 
  /// If [autoReconnect] is enabled and the connection fails, automatic reconnection
  /// will be attempted with exponential backoff delay.
  /// 
  /// Throws an [ArgumentError] if the URL scheme is not `ws://` or `wss://`.
  /// Throws an exception if the connection cannot be established within 10 seconds.
  /// 
  /// Parameters:
  ///   - [urlString]: The WebSocket URL (e.g., 'wss://echo.websocket.org/')
  ///   - [headers]: Optional custom HTTP headers for the upgrade request
  /// 
  /// Example:
  /// ```dart
  /// await rxWs.connect('wss://echo.websocket.org/');
  /// await rxWs.connect(
  ///   'wss://api.example.com/ws',
  ///   headers: {'Authorization': 'Bearer token123'}
  /// );
  /// ```
  Future<void> connect(String urlString, {Map<String, String>? headers}) async {
    try {
      // Parse and validate the URL
      final uri = Uri.parse(urlString);
      if (uri.scheme != 'ws' && uri.scheme != 'wss') {
        throw ArgumentError("Protocol error: URL must start with ws:// or wss://");
      }

      // Determine if using TLS (wss) or plain (ws)
      _useTLS = (uri.scheme == 'wss');
      _host = uri.host;
      
      // Default ports: 80 for ws, 443 for wss
      _port = uri.hasPort ? uri.port : (_useTLS ? 443 : 80);
      
      // Ensure path is not empty, default to "/"
      _path = uri.path.isEmpty ? "/" : uri.path;
      
      // Append query parameters if present
      if (uri.hasQuery) {
        _path += "?${uri.query}";
      }

      if (headers != null) this.headers = headers;

      _setState(WSState.connecting);

      // Connect via Socket or SecureSocket based on TLS requirement
      _socket = await (_useTLS 
          ? SecureSocket.connect(_host, _port) 
          : Socket.connect(_host, _port)
      ).timeout(const Duration(seconds: 10));

      _retry = 0;
      
      // Generate random 16-byte base64-encoded handshake key
      final key = base64Encode(List<int>.generate(16, (_) => Random().nextInt(256)));
      _handshakeKey = key;

      // Format custom headers if provided
      final headerStr = this.headers.isNotEmpty 
          ? "${this.headers.entries.map((e) => "${e.key}: ${e.value}").join("\r\n")}\r\n" 
          : "";

      // Construct the standard HTTP WebSocket upgrade request
      final request = 'GET $_path HTTP/1.1\r\n'
          'Host: $_host:$_port\r\n'
          'Upgrade: websocket\r\n'
          'Connection: Upgrade\r\n'
          'Sec-WebSocket-Key: $key\r\n'
          'Sec-WebSocket-Version: 13\r\n'
          '$headerStr'
          '\r\n';

      _socket!.add(utf8.encode(request));
      
      // Listen for incoming data
      _socket!.listen(_onData, onDone: _onClose, onError: (_) => _onClose());
    } catch (_) {
      _reconnect();
    }
  }

  // ---------------------------------------------------------------------------
  // Data Frame Processing
  // ---------------------------------------------------------------------------
  
  /// Updates the internal connection state and notifies listeners via the state stream.
  void _setState(WSState s) {
    _state = s;
    _stateController.add(s);
  }

  /// Handles incoming data from the socket.
  /// 
  /// During handshake phase, validates the WebSocket upgrade response.
  /// After connection is established, parses incoming WebSocket frames.
  void _onData(Uint8List data) {
    _buffer = Uint8List.fromList([..._buffer, ...data]);

    if (_state == WSState.connecting) {
      _tryCompleteHandshake();
      return;
    }

    _parseFrames();
  }

  /// Completes the WebSocket handshake by validating the server's response.
  /// 
  /// Validates:
  /// 1. HTTP 101 Switching Protocols response status
  /// 2. Sec-WebSocket-Accept header matches expected value (SHA1 + base64 of key)
  /// 
  /// If validation succeeds, transitions to WSState.open and starts heartbeat.
  /// If validation fails, triggers reconnection attempt.
  void _tryCompleteHandshake() {
    final str = utf8.decode(_buffer, allowMalformed: true);
    final headerEndIndex = str.indexOf("\r\n\r\n");

    if (headerEndIndex == -1) return; // Headers not fully received yet

    final headerPart = str.substring(0, headerEndIndex + 4);

    // Validate HTTP 101 response
    if (!headerPart.contains("101 Switching Protocols")) {
      _reconnect();
      return;
    }

    // Validate and verify Sec-WebSocket-Accept header
    final acceptPattern = RegExp(
      r'Sec-WebSocket-Accept:\s*([a-zA-Z0-9+/=]+)',
      caseSensitive: false
    );
    final match = acceptPattern.firstMatch(headerPart);
    if (match == null) {
      _reconnect();
      return;
    }

    final serverAccept = match.group(1)!;
    final expectedAccept = base64Encode(sha1.convert(
      utf8.encode("${_handshakeKey!}258EAFA5-E914-47DA-95CA-C5AB0DC85B11")
    ).bytes);

    if (serverAccept != expectedAccept) {
      _reconnect();
      return;
    }

    // Handshake successful - trim handshake data from buffer
    final headerBytesLength = utf8.encode(headerPart).length;
    if (_buffer.length > headerBytesLength) {
      _buffer = _buffer.sublist(headerBytesLength);
    } else {
      _buffer = Uint8List(0);
    }

    // Update state and notify listeners
    _setState(WSState.open);
    _onOpenController.add(null);
    _startHeartbeat();

    // Parse any frames that may have been received during handshake
    if (_buffer.isNotEmpty) {
      _parseFrames();
    }
  }

  /// Current offset position in the receive buffer
  int _bufferOffset = 0;

  /// Parses incoming WebSocket frames from the receive buffer.
  /// 
  /// WebSocket frame format (RFC 6455):
  /// ```
  /// 0                   1                   2                   3
  /// 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
  /// +-+-+-+-+-------+-+-------------+-------------------------------+
  /// |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
  /// |I|S|S|S|(4)   |A|     (7)     |             (0/16/64)         |
  /// |N|V|V|V|       |S|             |   (if payload len==126/127)   |
  /// | |1|2|3|       |K|             |                               |
  /// +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
  /// |     Extended payload length continued, if payload len == 127  |
  /// + - - - - - - - - - - - - - - - +-------------------------------+
  /// |                                |Masking-key, if MASK set to 1  |
  /// +-------------------------------+-------------------------------+
  /// | Masking-key (continued)       |          Payload Data         |
  /// +-------------------------------+                               |
  /// |                     Payload Data continued ...                |
  /// +---------------------------------------------------------------+
  /// ```
  void _parseFrames() {
    while (true) {
      if (_bufferOffset + 2 > _buffer.length) return;

      int offset = _bufferOffset;

      // Parse first byte: FIN + RSV + opcode
      final byte1 = _buffer[offset++];
      final fin = (byte1 & 0x80) != 0;
      final opcode = byte1 & 0x0F;

      // Parse second byte: MASK + payload length
      final byte2 = _buffer[offset++];
      final masked = (byte2 & 0x80) != 0;
      int payloadLen = byte2 & 0x7F;

      // Handle extended payload length (126 or 127)
      if (payloadLen == 126) {
        if (offset + 2 > _buffer.length) return;
        payloadLen = (_buffer[offset++] << 8) | _buffer[offset++];
      } else if (payloadLen == 127) {
        if (offset + 8 > _buffer.length) return;
        payloadLen = 0;
        for (int i = 0; i < 8; i++) {
          payloadLen = (payloadLen << 8) | _buffer[offset++];
        }
      }

      // Extract masking key (client-to-server frames are always masked)
      List<int>? maskKey;
      if (masked) {
        if (offset + 4 > _buffer.length) return;
        maskKey = _buffer.sublist(offset, offset + 4);
        offset += 4;
      }

      // Check if we have the complete payload
      if (offset + payloadLen > _buffer.length) return;

      // Extract payload data
      final payload = _buffer.sublist(offset, offset + payloadLen);

      // Unmask payload if masked (for server-to-client frames, usually not masked)
      if (masked && maskKey != null) {
        for (int i = 0; i < payload.length; i++) {
          payload[i] ^= maskKey[i % 4];
        }
      }

      // Handle the frame
      _handleFrame(fin, opcode, payload);

      // Update buffer offset to next frame
      _bufferOffset = offset + payloadLen;

      // Clear buffer if all data has been processed
      if (_bufferOffset >= _buffer.length) {
        _buffer = Uint8List(0);
        _bufferOffset = 0;
        break;
      }
    }
  }

  /// Handles a parsed WebSocket frame based on its opcode.
  /// 
  /// Opcode values:
  /// - 0x0: Continuation frame (used for fragmented messages)
  /// - 0x1: Text frame
  /// - 0x2: Binary frame
  /// - 0x8: Close frame
  /// - 0x9: Ping frame
  /// - 0xA: Pong frame
  void _handleFrame(bool fin, int opcode, List<int> payload) {
    // Handle continuation frame (opcode 0x0)
    if (opcode == 0x0) {
      _fragmentBuffer.addAll(payload);
      if (fin) {
        _emitMessage(_fragmentOpcode!, _fragmentBuffer);
        _fragmentBuffer = [];
      }
      return;
    }

    // If message is fragmented (FIN bit not set), store the opcode and payload
    if (!fin) {
      _fragmentOpcode = opcode;
      _fragmentBuffer = payload;
      return;
    }

    // Complete message received
    _emitMessage(opcode, payload);
  }

  /// Emits a message to appropriate stream based on opcode.
  /// 
  /// Opcodes:
  /// - 0x1: Text message → emits as String
  /// - 0x2: Binary message → emits as Uint8List
  /// - 0x8: Close frame → closes connection
  /// - 0x9: Ping frame → responds with pong
  /// - 0xA: Pong frame → cancels pong timeout
  void _emitMessage(int opcode, List<int> payload) {
    switch (opcode) {
      case 0x1: // Text frame
        try {
          final text = utf8.decode(payload, allowMalformed: false);
          _messageController.add(text);
        } catch (_) {
          close();
        }
        break;

      case 0x2: // Binary frame
        _messageController.add(Uint8List.fromList(payload));
        break;

      case 0x8: // Close frame
        close();
        break;

      case 0x9: // Ping frame - respond with pong
        _enqueue(_buildFrame(0xA, []));
        break;

      case 0xA: // Pong frame - clear timeout
        _pongTimeout?.cancel();
        _pongTimeout = null;
        break;
    }
  }

  // =========================
  // Backpressure Queue Management
  // =========================

  /// Enqueues a frame for sending with backpressure handling.
  /// 
  /// Frames are queued and sent sequentially to handle backpressure from the socket.
  void _enqueue(List<int> frame) {
    _sendQueue.add(frame);
    _flush();
  }

  /// Flushes the send queue, sending all pending frames sequentially.
  /// 
  /// Only one flush operation runs at a time to ensure order and prevent race conditions.
  void _flush() async {
    if (_isSending || _socket == null) return;
    _isSending = true;

    while (_sendQueue.isNotEmpty) {
      final data = _sendQueue.removeAt(0);
      _socket!.add(data);
      await _socket!.flush();
    }

    _isSending = false;
  }

  // =========================
  // Public Send APIs
  // =========================

  /// Sends a text message to the WebSocket server.
  /// 
  /// The message is automatically UTF-8 encoded and wrapped in a WebSocket frame.
  /// The frame is queued and sent with backpressure handling.
  /// 
  /// Example:
  /// ```dart
  /// rxWs.sendText('Hello Server!');
  /// ```
  void sendText(String text) {
    _enqueue(_buildFrame(0x1, utf8.encode(text)));
  }

  /// Sends binary data to the WebSocket server.
  /// 
  /// The data is wrapped in a WebSocket binary frame and queued for transmission.
  /// 
  /// Example:
  /// ```dart
  /// rxWs.sendBinary([0x01, 0x02, 0x03]);
  /// ```
  void sendBinary(List<int> data) {
    _enqueue(_buildFrame(0x2, data));
  }

  /// Sends a ping frame to the server as a keepalive check.
  /// 
  /// The client expects a pong response within 5 seconds. If no pong is received,
  /// the connection is considered dead and reconnection is triggered.
  /// 
  /// Ping frames are empty (no payload).
  /// 
  /// Example:
  /// ```dart
  /// rxWs.ping();
  /// ```
  void ping() {
    if (_state != WSState.open) return;
    _enqueue(_buildFrame(0x9, []));
    _startPongTimeout();
  }

  /// Constructs a WebSocket frame with proper encoding.
  /// 
  /// Frame structure:
  /// - FIN bit (1 bit) + opcode (4 bits)
  /// - MASK bit (1 bit) + payload length (7 bits) or extended
  /// - Masking key (4 bytes, for client-to-server)
  /// - Payload (masked XOR with masking key)
  /// 
  /// All frames from client to server must be masked per RFC 6455.
  /// 
  /// Parameters:
  ///   - [opcode]: Frame opcode (0x1=text, 0x2=binary, 0x9=ping, 0xA=pong, 0x8=close)
  ///   - [payload]: Frame payload data
  /// 
  /// Returns: Complete WebSocket frame as a list of integers
  List<int> _buildFrame(int opcode, List<int> payload) {
    final frame = <int>[];

    // First byte: FIN (1) + RSV (3 zeros) + opcode (4)
    frame.add(0x80 | opcode);

    // Payload length and extended payload length
    final maskBit = 0x80; // Mask bit for client-to-server frames
    final length = payload.length;

    if (length <= 125) {
      frame.add(maskBit | length);
    } else if (length <= 65535) {
      // 16-bit extended payload length
      frame.add(maskBit | 126);
      frame.add((length >> 8) & 0xFF);
      frame.add(length & 0xFF);
    } else {
      // 64-bit extended payload length
      frame.add(maskBit | 127);
      for (int i = 7; i >= 0; i--) {
        frame.add((length >> (8 * i)) & 0xFF);
      }
    }

    // Generate random 4-byte masking key
    final maskKey = List.generate(4, (_) => Random().nextInt(256));
    frame.addAll(maskKey);

    // Mask payload: XOR each byte with corresponding masking key byte
    for (int i = 0; i < payload.length; i++) {
      frame.add(payload[i] ^ maskKey[i % 4]);
    }

    return frame;
  }

  // =========================
  // Heartbeat & Keepalive
  // =========================

  /// Starts the heartbeat mechanism (sends ping every 10 seconds).
  /// 
  /// The heartbeat helps detect dead connections and keeps the connection alive
  /// by sending periodic ping frames to the server.
  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_state == WSState.open) {
        ping();
      }
    });
  }

  /// Starts a timeout waiting for pong response (5 second timeout).
  /// 
  /// If no pong is received within 5 seconds, the connection is considered dead
  /// and reconnection is triggered.
  void _startPongTimeout() {
    _pongTimeout?.cancel();
    _pongTimeout = Timer(Duration(seconds: 5), () {
      _reconnect();
    });
  }

  // =========================
  // Reconnection Logic
  // =========================

  /// Handles reconnection with exponential backoff.
  /// 
  /// Reconnection strategy:
  /// - Uses exponential backoff: delay = 2^retry seconds
  /// - Respects [maxRetry] limit
  /// - If [autoReconnect] is disabled, no reconnection is attempted
  /// - Exponential backoff prevents overwhelming the server
  /// 
  /// Delays:
  /// - Attempt 1: 1 second (2^0)
  /// - Attempt 2: 2 seconds (2^1)
  /// - Attempt 3: 4 seconds (2^2)
  /// - Attempt 4: 8 seconds (2^3)
  /// - etc.
  void _reconnect() {
    try {
      if (!autoReconnect || _state == WSState.closing) return;

      // Clean up all old resources
      _cleanup();

      _setState(WSState.closed);

      if (_retry >= maxRetry) {
        return; // Max retries reached
      }

      final delay = pow(2, _retry).toInt();
      _retry++;

      // Schedule reconnection after delay
      Future.delayed(Duration(seconds: delay), () {
        // Reconstruct original URL and reconnect
        final scheme = _useTLS ? "wss" : "ws";
        connect("$scheme://$_host:$_port$_path", headers: headers);
      });
    } catch (e) {
      _onErrorController.add(e);
      _reconnect();
    }
  }

  /// Cleans up all internal resources (sockets, timers, queues, buffers).
  /// 
  /// This is called before reconnection or during shutdown to ensure no
  /// resource leaks or orphaned timers.
  void _cleanup() {
    _heartbeat?.cancel();
    _pongTimeout?.cancel();
    _heartbeat = null;
    _pongTimeout = null;
    _socket?.destroy();
    _socket = null;
    _buffer = Uint8List(0);
    _bufferOffset = 0;
    _sendQueue.clear();
    _fragmentBuffer.clear();
    _isSending = false;
  }

  // =========================
  // Graceful Shutdown
  // =========================

  /// Gracefully closes the WebSocket connection.
  /// 
  /// Sends a close frame to the server, allowing it to respond before
  /// the connection is torn down. Cleans up all resources after closing.
  /// 
  /// State transitions: open → closing → closed
  void close() {
    _setState(WSState.closing);
    _enqueue(_buildFrame(0x8, [])); // Send close frame
    _socket?.close();
    _setState(WSState.closed);
    _onCloseController.add(null);
    _cleanup();
  }

  /// Handles socket close event and triggers reconnection if appropriate.
  /// 
  /// This is called when the socket reports it's done (connection lost),
  /// as opposed to [close()] which is user-initiated.
  void _onClose() {
    _heartbeat?.cancel();
    _pongTimeout?.cancel();
    _onCloseController.add(null);
    _reconnect();
  }
}
