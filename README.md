# rxws

A reliable, cross-platform WebSocket client for Dart & Flutter.

## Features

- ✅ **Cross-platform support** (Android, iOS, macOS, Windows, Linux, Web)
- ✅ **Auto-reconnection** with exponential backoff retry strategy
- ✅ **Heartbeat & ping/pong** mechanism to detect dead connections
- ✅ **Simple stream-based API** with Dart async/await support
- ✅ **Text & JSON message support** for easy data transmission
- ✅ **Clean error handling** with comprehensive error streams
- ✅ **RFC 6455 compliant** WebSocket implementation
- ✅ **Message fragmentation** automatic handling
- ✅ **Backpressure support** for reliable message queuing
- ✅ **Custom HTTP headers** support for authentication and custom handshakes

## Getting Started

### Installation

Add `rxws` to your `pubspec.yaml`:

```yaml
dependencies:
  rxws: ^1.1.1
```

Then run:

```bash
flutter pub get
```

### Basic Usage

```dart
import 'package:rxws/rxws.dart';

void connect() async {
  final client = createWsClient();

  // Listen for connection established
  client.onOpen.listen((_) {
    print('Connected');
    client.send('Hello WebSocket');
  });

  // Listen for incoming messages
  client.onMessage.listen((message) {
    print('Received: $message');
  });

  // Listen for disconnection
  client.onClose.listen((_) {
    print('Disconnected');
  });

  // Listen for errors
  client.onError.listen((error) {
    print('Error: $error');
  });

  // Listen for state changes
  client.onState.listen((state) {
    print('State: $state');
  });

  // Establish connection
  await client.connect('wss://echo.websocket.org');
}
```

## API Reference

### WsClient Interface

The main public interface that abstracts platform-specific implementations.

#### Creating a Client

```dart
final client = createWsClient();
```

#### Connection Management

```dart
// Connect to WebSocket server
await client.connect('wss://example.com/ws');

// Connect with custom headers (e.g., for authentication)
await client.connect(
  'wss://example.com/ws',
  headers: {'Authorization': 'Bearer your-token'}
);

// Check connection status
if (client.isConnected) {
  print('Connected!');
}

// Close connection
client.close();

// Close with WebSocket close code
client.closeWithCode(1000, 'Normal closure');
```

#### Sending Messages

```dart
// Send text message
client.send('Hello Server');

// Send JSON message
client.sendJson({
  'action': 'subscribe',
  'channel': 'updates',
  'timestamp': DateTime.now().toIso8601String(),
});
```

#### Event Streams

```dart
// Connection opened
client.onOpen.listen((_) {
  print('Connected');
});

// Incoming messages (String or binary data)
client.onMessage.listen((message) {
  if (message is String) {
    print('Text: $message');
  } else {
    print('Binary: ${message.length} bytes');
  }
});

// Connection closed
client.onClose.listen((_) {
  print('Disconnected');
});

// Errors during connection lifecycle
client.onError.listen((error) {
  print('Error: $error');
});

// Connection state changes
client.onState.listen((state) {
  switch (state) {
    case WSState.connecting:
      print('Connecting...');
      break;
    case WSState.open:
      print('Connected');
      break;
    case WSState.closing:
      print('Closing...');
      break;
    case WSState.closed:
      print('Closed');
      break;
  }
});
```

### WSState Enum

Represents the connection state lifecycle:

- **`WSState.closed`** - Connection is closed (initial state)
- **`WSState.connecting`** - Connection attempt in progress
- **`WSState.open`** - Connection established and ready for communication
- **`WSState.closing`** - Graceful close in progress

## Advanced Usage

### Error Handling

```dart
client.onError.listen((error) {
  if (error is SocketException) {
    print('Network error: ${error.message}');
  } else {
    print('WebSocket error: $error');
  }
});
```

### Automatic Reconnection

The library includes built-in automatic reconnection with exponential backoff:

- Initial retry delay: 1 second
- Exponential backoff: Each retry doubles the delay (1s → 2s → 4s → 8s...)
- Max retries: 10 attempts (configurable)
- After max retries: Connection stops attempting

For lower-level control, use `RxWs` directly:

```dart
import 'package:rxws/src/rx_ws.dart';

final rxWs = RxWs(
  autoReconnect: true,  // Enable auto-reconnection
  maxRetry: 5,          // Max 5 retry attempts
);

await rxWs.connect('wss://example.com/ws');

rxWs.onOpen.listen((_) => print('Connected'));
rxWs.messages.listen((msg) => print('Message: $msg'));
rxWs.states.listen((state) => print('State: $state'));
```

### Sending Binary Data

```dart
import 'package:rxws/src/rx_ws.dart';

final rxWs = RxWs();
await rxWs.connect('wss://example.com/ws');

// Send binary data
rxWs.sendBinary([0x01, 0x02, 0x03, 0x04]);

// Receive binary or text
rxWs.messages.listen((message) {
  if (message is String) {
    print('Text: $message');
  } else {
    // message is Uint8List
    print('Binary data received: ${message.length} bytes');
  }
});
```

### Heartbeat and Ping/Pong

The library automatically sends ping frames every 10 seconds to keep the connection alive and detect dead connections. If no pong response is received within 5 seconds, the connection is considered dead and reconnection is triggered.

For manual control with `RxWs`:

```dart
final rxWs = RxWs();
await rxWs.connect('wss://example.com/ws');

// Send manual ping
rxWs.ping();
```

### Custom Headers

```dart
await client.connect(
  'wss://api.example.com/ws',
  headers: {
    'Authorization': 'Bearer eyJhbGc...',
    'User-Agent': 'MyApp/1.0',
    'X-Custom-Header': 'custom-value',
  },
);
```

### JSON Message Handling

```dart
// Send JSON
client.sendJson({
  'type': 'subscribe',
  'data': {
    'channel': 'prices',
    'symbols': ['BTC', 'ETH'],
  },
});

// Receive and parse JSON
client.onMessage.listen((message) {
  if (message is String) {
    final data = jsonDecode(message);
    print('Received: $data');
  }
});
```

## WebSocket Close Codes

Standard WebSocket close codes:

- **`1000`** - Normal closure (most common)
- **`1001`** - Going away (endpoint is going down)
- **`1002`** - Protocol error
- **`1003`** - Unsupported data
- **`1006`** - Abnormal closure (connection lost)
- **`1008`** - Policy violation
- **`1009`** - Message too big
- **`1010`** - Mandatory extension (server requires extension)
- **`1011`** - Server error

Example:

```dart
client.closeWithCode(1000, 'Normal session end');
```

## Platform-Specific Details

### Android & iOS

- Uses native `dart:io` Socket implementation
- Full support for wss:// (TLS/SSL)
- Automatic certificate validation
- Battery-efficient with built-in timeouts

### macOS, Windows, Linux

- Uses native `dart:io` Socket implementation
- Complete RFC 6455 compliance
- High-performance frame parsing

### Web

- Uses browser WebSocket API (via `package:web`)
- Automatic CORS handling
- Browser security restrictions apply
- Same API as native platforms

## Troubleshooting

### Connection Fails Immediately

1. Check the WebSocket URL format (must start with `ws://` or `wss://`)
2. Verify the server is running and accessible
3. Check firewall and network connectivity
4. For `wss://`, ensure SSL certificate is valid

```dart
try {
  await client.connect('wss://example.com/ws');
} catch (e) {
  print('Connection failed: $e');
}
```

### Messages Not Received

1. Verify connection is in `WSState.open` state
2. Check that the server is sending messages
3. Ensure onMessage listener is attached before connecting
4. Check the error stream for any errors

```dart
// Always listen before connecting
client.onMessage.listen((msg) => print('Got: $msg'));
await client.connect('wss://example.com/ws');
```

### Connection Drops Frequently

1. Check your network connectivity
2. Verify server stability (check server logs)
3. Increase `maxRetry` if needed
4. Check for network timeouts or proxy issues

```dart
import 'package:rxws/src/rx_ws.dart';

final rxWs = RxWs(maxRetry: 15); // More retries
await rxWs.connect('wss://example.com/ws');
```

### High CPU/Memory Usage

1. Verify you're not receiving too many large messages
2. Process messages efficiently in listeners
3. Use unsubscribe patterns to clean up listeners

```dart
final subscription = client.onMessage.listen((msg) => processMessage(msg));

// Clean up when done
subscription.cancel();
```

## Performance Tips

1. **Reuse clients** - Don't create a new client for each connection; reuse the same instance
2. **Batch messages** - Send multiple messages in one batch instead of individual sends
3. **Use binary for large data** - Binary frames are more efficient than JSON for large payloads
4. **Monitor connection state** - Use the state stream to make decisions about message sending

## Supported Dart Versions

- Dart 3.0.6 and above
- Flutter 1.17.0 and above

## License

[Include your license information here]

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## Support

For issues, feature requests, or questions:
- GitHub Issues: [https://github.com/msfm2018/rxws/issues](https://github.com/msfm2018/rxws/issues)
- GitHub Discussions: [https://github.com/msfm2018/rxws/discussions](https://github.com/msfm2018/rxws/discussions)
