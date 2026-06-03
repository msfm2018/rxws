import 'ws_client.dart';

import 'ws_client_stub.dart' if (dart.library.html) 'ws_client_web.dart' if (dart.library.io) 'ws_client_io.dart';

/// Factory function to create a platform-specific [WsClient] instance.
/// 
/// This function uses conditional imports to automatically select the correct
/// WebSocket implementation based on the target platform:
/// 
/// - **Web (dart.library.html)**: Returns [WsClientWeb] using browser WebSocket API
/// - **Native (dart.library.io)**: Returns [WsClientIO] using dart:io Socket
/// - **Other**: Returns a stub implementation (should not occur in practice)
/// 
/// ## How It Works
/// 
/// The factory uses Dart's conditional import feature to select the correct
/// implementation at compile time based on available libraries:
/// 
/// - If `dart.library.html` is available (browser environment), `ws_client_web.dart` is loaded
/// - If `dart.library.io` is available (native platforms), `ws_client_io.dart` is loaded
/// - Otherwise, `ws_client_stub.dart` is loaded (fallback, rarely used)
/// 
/// This approach ensures:
/// 1. No platform-specific code is included in the final bundle
/// 2. Tree-shaking removes unused platform implementations
/// 3. Optimal binary size for each platform
/// 4. Seamless API across all platforms
/// 
/// ## Usage
/// 
/// Simply call [createWsClient] without any parameters:
/// 
/// ```dart
/// import 'package:rxws/rxws.dart';
/// 
/// final client = createWsClient();
/// await client.connect('wss://example.com/ws');
/// ```
/// 
/// The returned [WsClient] works identically across all platforms:
/// - Android & iOS
/// - macOS, Windows, Linux
/// - Web (Chrome, Firefox, Safari, Edge)
/// 
/// ## Return Value
/// 
/// Returns a [WsClient] implementation appropriate for the current platform.
/// All implementations implement the same abstract [WsClient] interface,
/// ensuring consistent API across platforms.
/// 
/// ## Example: Platform-Agnostic Code
/// 
/// ```dart
/// Future<void> setupWebSocket() async {
///   // Same code works on all platforms!
///   final client = createWsClient();
///   
///   client.onOpen.listen((_) {
///     print('Connected');
///     client.send('Hello from ${Platform.operatingSystem}');
///   });
///   
///   client.onMessage.listen((message) {
///     print('Received: $message');
///   });
///   
///   await client.connect('wss://api.example.com/ws');
/// }
/// ```
/// 
/// ## Platform Implementation Details
/// 
/// ### Native Platforms (Android, iOS, macOS, Windows, Linux)
/// 
/// - Implementation: [WsClientIO]
/// - Uses: `dart:io` Socket and SecureSocket
/// - Features: Full RFC 6455 compliance, auto-reconnection, heartbeat
/// - Performance: Optimized for low-latency communication
/// 
/// ### Web Platform (Browser)
/// 
/// - Implementation: [WsClientWeb]
/// - Uses: Browser WebSocket API (via `package:web`)
/// - Features: Automatic CORS handling, browser security
/// - Performance: Native browser WebSocket implementation
/// 
/// See Also:
/// - [WsClient] - Abstract interface
/// - [WsClientIO] - Native platform implementation
/// - [WsClientWeb] - Web platform implementation
WsClient createWsClient() => createClient();
