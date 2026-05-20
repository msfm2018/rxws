```markdown
# RxWs

A lightweight, high-performance, pure Dart WebSocket client with automatic reconnection and full protocol control.

---

## ✨ Features

- ✅ Pure Dart implementation — no external WebSocket dependencies
- ✅ Support for `ws://` and `wss://` URLs
- ✅ Automatic URL parsing (`Uri.parse`)
- ✅ TLS (`SecureSocket`) support
- ✅ Full WebSocket protocol (framing, masking, fragmentation)
- ✅ Automatic Ping/Pong heartbeat (every 10 seconds)
- ✅ Pong timeout detection + auto reconnect
- ✅ Exponential backoff reconnection (up to 10 retries)
- ✅ Strict handshake verification (`Sec-WebSocket-Accept`)
- ✅ Backpressure handling for sending messages
- ✅ Clean resource management

---

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  crypto: ^3.0.0   # Required for SHA-1 handshake verification
```

Then run:

```bash
flutter pub get    # or dart pub get
```

---

## 🚀 Quick Start

```dart
final ws = RxWs();

ws.states.listen((state) {
  print('WebSocket State: $state');
});

ws.messages.listen((message) {
  if (message is String) {
    print('Text: $message');
  } else if (message is List<int>) {
    print('Binary: ${message.length} bytes');
  }
});

// Connect using full URL
await ws.connect('ws://echo.websocket.events');

// Or with TLS
// await ws.connect('wss://echo.websocket.events');

ws.sendText('Hello from RxWs!');
ws.sendBinary([1, 2, 3, 4, 5]);
ws.ping();
```

---

## 📘 API

### Main Methods

| Method | Description |
|--------|-------------|
| `Future<void> connect(String url)` | Connect using `ws://` or `wss://` URL |
| `void sendText(String text)` | Send text message |
| `void sendBinary(List<int> data)` | Send binary message |
| `void ping()` | Send a ping frame |
| `void close()` | Close the connection |
| `Stream<dynamic> get messages` | Received messages (`String` or `List<int>`) |
| `Stream<WSState> get states` | Connection state stream |

### Connection States

```dart
enum WSState { connecting, open, closing, closed }
```

---

## Advanced Usage

### Connect with Custom Headers

```dart
await ws.connect(
  'wss://example.com/chat',
  headers: {
    'Authorization': 'Bearer your-token',
    'X-User-Id': '123',
  },
);
```

### Listen to States

```dart
ws.states.listen((state) {
  switch (state) {
    case WSState.open:
      print('✅ Connected');
      break;
    case WSState.closed:
      print('❌ Disconnected');
      break;
    case WSState.connecting:
      print('🔄 Connecting...');
      break;
  }
});
```

### Send Messages

```dart
ws.sendText('Hello World');
ws.sendBinary(Uint8List.fromList([0x01, 0x02, 0xFF]));
```

---

## Example URLs

- `ws://echo.websocket.events`
- `wss://echo.websocket.events`
- `ws://localhost:8080/ws`
- `wss://api.example.com/chat?token=abc123`

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

---

## License

MIT License

---

**Built for performance, reliability, and ease of use.**
```

