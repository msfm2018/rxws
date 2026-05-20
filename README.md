
```markdown
# RxWs

A lightweight, high-performance, raw WebSocket client implemented in pure Dart.  
No external WebSocket dependencies — full control over frames, masking, and connection lifecycle.

---

## ✨ Features

- ✅ Pure Dart implementation (no `web_socket_channel` dependency)
- ✅ TLS / SecureSocket support
- ✅ Full WebSocket protocol (framing, masking, fragmentation)
- ✅ Automatic Ping/Pong heartbeat (every 10s)
- ✅ Pong timeout detection + auto reconnect
- ✅ Exponential backoff reconnection strategy
- ✅ Strict handshake verification (`Sec-WebSocket-Accept`)
- ✅ Backpressure support for sending
- ✅ Clean resource management

---

## 📦 Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  rxws: ^1.0.0   # for SHA1 handshake
```

Then run:

```bash
flutter pub get    # or dart pub get
```

---

## 🚀 Usage

### Basic Example

```dart
import 'package:your_project/raw_websocket_client.dart';

final client = RawWebSocketClient();

client.states.listen((state) {
  print('State: $state');
});

client.messages.listen((message) {
  if (message is String) {
    print('Text: $message');
  } else if (message is List<int>) {
    print('Binary: ${message.length} bytes');
  }
});

// Connect
await client.connect('echo.websocket.org', 80, '/');

// Send messages
client.sendText('Hello WebSocket!');
client.sendBinary([1, 2, 3, 4]);

// Manual ping
client.ping();
```

---

## 📘 API

### Main Methods

| Method | Description |
|-------|-------------|
| `Future<void> connect(...)` | Connect to WebSocket server |
| `void sendText(String text)` | Send text message |
| `void sendBinary(List<int> data)` | Send binary message |
| `void ping()` | Send ping frame |
| `void close({int code = 1000})` | Close connection |
| `Stream<dynamic> get messages` | Received messages (String or Uint8List) |
| `Stream<WSState> get states` | Connection state changes |

### Connection States

```dart
enum WSState { connecting, open, closing, closed }
```

---

## Advanced Usage

### With custom headers

```dart
await client.connect(
  'example.com',
  443,
  '/ws',
  tls: true,
  headers: {
    'Authorization': 'Bearer your-token',
    'X-Custom-Header': 'value'
  }
);
```

### Listen to connection state

```dart
client.states.listen((state) {
  if (state == WSState.open) {
    print('✅ Connected');
  } else if (state == WSState.closed) {
    print('❌ Disconnected');
  }
});
```

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

---

## License

This project is licensed under the MIT License.

---

**Made with ❤️ for full control and reliability.**
```

