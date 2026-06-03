/// WebSocket connection state enumeration.
/// 
/// Represents the lifecycle states of a WebSocket connection.
enum WSState {
  /// The WebSocket is attempting to establish a connection.
  connecting,
  
  /// The WebSocket connection is established and ready for communication.
  open,
  
  /// The WebSocket is in the process of closing the connection.
  closing,
  
  /// The WebSocket connection is closed.
  closed,
}

/// Abstract base class for WebSocket client implementations.
/// 
/// [WsClient] provides a high-level, stream-based interface for WebSocket
/// communication. It supports cross-platform connectivity across Android, iOS,
/// macOS, Windows, Linux, and Web platforms.
/// 
/// ## Connection Management
/// 
/// Use [connect] to establish a WebSocket connection and [close] or
/// [closeWithCode] to terminate it. The connection state can be monitored
/// via the [onState] stream.
/// 
/// ## Message Communication
/// 
/// Send data using [send] for text messages or [sendJson] for JSON-encoded
/// objects. Incoming messages are delivered through the [onMessage] stream.
/// 
/// ## State Monitoring
/// 
/// Monitor connection events through four primary streams:
/// - [onOpen]: Emitted when the connection is successfully established
/// - [onMessage]: Emits incoming messages from the server
/// - [onClose]: Emitted when the connection is closed
/// - [onError]: Emits error events during the connection lifecycle
/// - [onState]: Emits connection state changes
/// 
/// ## Usage Example
/// 
/// ```dart
/// final client = createWsClient();
/// 
/// // Listen for connection established
/// client.onOpen.listen((_) {
///   print('Connected to WebSocket');
///   client.send('Hello Server');
/// });
/// 
/// // Listen for incoming messages
/// client.onMessage.listen((message) {
///   print('Received: $message');
/// });
/// 
/// // Listen for errors
/// client.onError.listen((error) {
///   print('Error: $error');
/// });
/// 
/// // Listen for disconnection
/// client.onClose.listen((_) {
///   print('Disconnected');
/// });
/// 
/// // Establish connection
/// await client.connect('wss://echo.websocket.org');
/// 
/// // Send JSON data
/// client.sendJson({'action': 'ping', 'timestamp': DateTime.now().toIso8601String()});
/// 
/// // Close connection gracefully
/// client.closeWithCode(1000, 'Normal closure');
/// ```
abstract class WsClient {
  /// Establishes a WebSocket connection to the specified [url].
  /// 
  /// The [url] should be a valid WebSocket URL starting with `ws://` or `wss://`.
  /// 
  /// This method is asynchronous and completes when the connection is established.
  /// Listen to [onOpen] to be notified when the connection is ready.
  /// 
  /// Throws an exception if the connection fails or if an invalid URL is provided.
  /// 
  /// Example:
  /// ```dart
  /// await client.connect('wss://echo.websocket.org');
  /// ```
  Future<void> connect(String url);

  /// Sends a text message to the WebSocket server.
  /// 
  /// The message must be a valid UTF-8 string. This method should only be called
  /// after a successful connection ([onOpen] has been emitted).
  /// 
  /// Example:
  /// ```dart
  /// client.send('Hello Server');
  /// ```
  void send(String data);

  /// Sends a JSON-encoded message to the WebSocket server.
  /// 
  /// The provided [json] map is automatically encoded to a JSON string before
  /// transmission. This is a convenience method for sending structured data.
  /// 
  /// Example:
  /// ```dart
  /// client.sendJson({
  ///   'action': 'subscribe',
  ///   'channel': 'updates',
  ///   'timestamp': DateTime.now().millisecondsSinceEpoch,
  /// });
  /// ```
  void sendJson(Map<String, dynamic> json);

  /// Closes the WebSocket connection gracefully.
  /// 
  /// This method closes the connection without a specific close code or reason.
  /// After closing, [onClose] will be emitted.
  void close();

  /// Closes the WebSocket connection with a specific close code and optional reason.
  /// 
  /// The [code] parameter should be a valid WebSocket close code (e.g., 1000 for
  /// normal closure, 1001 for going away). The optional [reason] parameter provides
  /// a human-readable explanation for the closure.
  /// 
  /// Valid close codes:
  /// - `1000`: Normal closure
  /// - `1001`: Going away
  /// - `1002`: Protocol error
  /// - `1003`: Unsupported data
  /// - `1006`: Abnormal closure
  /// - `1008`: Policy violation
  /// - `1009`: Message too big
  /// - `1010`: Mandatory extension
  /// - `1011`: Server error
  /// 
  /// Example:
  /// ```dart
  /// client.closeWithCode(1000, 'Session ended');
  /// ```
  void closeWithCode(int code, [String? reason]);

  /// Stream of connection open events.
  /// 
  /// Emits when the WebSocket connection is successfully established and ready
  /// for communication. This is the appropriate time to send initial messages.
  /// 
  /// Example:
  /// ```dart
  /// client.onOpen.listen((_) {
  ///   print('Connected');
  ///   client.send('Initialization complete');
  /// });
  /// ```
  Stream<void> get onOpen;

  /// Stream of connection close events.
  /// 
  /// Emits when the WebSocket connection is closed, either by the client
  /// (via [close] or [closeWithCode]) or by the server.
  /// 
  /// Example:
  /// ```dart
  /// client.onClose.listen((_) {
  ///   print('Connection closed');
  ///   _reconnect(); // Implement reconnection logic
  /// });
  /// ```
  Stream<void> get onClose;

  /// Stream of incoming messages from the WebSocket server.
  /// 
  /// Emits data received from the server. The data type depends on the server's
  /// message format and may be either a string or a deserialized object.
  /// 
  /// For JSON messages, you may need to manually parse the data:
  /// ```dart
  /// client.onMessage.listen((message) {
  ///   if (message is String) {
  ///     final json = jsonDecode(message);
  ///     print('Received JSON: $json');
  ///   } else {
  ///     print('Received data: $message');
  ///   }
  /// });
  /// ```
  Stream<dynamic> get onMessage;

  /// Stream of error events during the WebSocket lifecycle.
  /// 
  /// Emits errors that occur during connection establishment, communication,
  /// or disconnection. Errors may be of various types, including connection
  /// failures, timeouts, and protocol errors.
  /// 
  /// Example:
  /// ```dart
  /// client.onError.listen((error) {
  ///   print('WebSocket error: $error');
  ///   if (error is SocketException) {
  ///     print('Network error: ${error.message}');
  ///   }
  /// });
  /// ```
  Stream<dynamic> get onError;

  /// Stream of connection state changes.
  /// 
  /// Emits [WSState] values representing the connection's lifecycle:
  /// - [WSState.connecting]: Connection attempt in progress
  /// - [WSState.open]: Connected and ready
  /// - [WSState.closing]: Graceful close in progress
  /// - [WSState.closed]: Connection fully closed
  /// 
  /// Example:
  /// ```dart
  /// client.onState.listen((state) {
  ///   switch (state) {
  ///     case WSState.connecting:
  ///       print('Connecting...');
  ///     case WSState.open:
  ///       print('Connected');
  ///     case WSState.closing:
  ///       print('Closing...');
  ///     case WSState.closed:
  ///       print('Closed');
  ///   }
  /// });
  /// ```
  Stream<WSState> get onState;

  /// Checks if the WebSocket connection is currently established.
  /// 
  /// Returns `true` if the connection is in the open state and ready for
  /// communication, `false` otherwise.
  /// 
  /// Example:
  /// ```dart
  /// if (client.isConnected) {
  ///   client.send('Status check');
  /// } else {
  ///   print('Not connected, attempting to reconnect...');
  ///   await client.connect('wss://example.com/ws');
  /// }
  /// ```
  bool get isConnected;
}
