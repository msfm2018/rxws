# rx_websocket
A reliable, cross-platform WebSocket client for Dart & Flutter.

## Features
- Cross-platform support (Android, iOS, macOS, Windows, Linux, Web)
- Auto-reconnection
- Heartbeat & ping/pong
- Simple stream-based API
- Text & JSON message support
- Clean error handling

## Getting started

### Install
Add to your `pubspec.yaml`:

```yaml
dependencies:
  rxws: ^1.1.0


import 'package:rxws/rxws.dart';

void connect() async {
  final client = createWsClient();

  // Listen events
  client.onOpen.listen((_) {
    print('Connected');
    client.send('Hello WebSocket');
  });

  client.onMessage.listen((message) {
    print('Received: $message');
  });

  client.onClose.listen((_) {
    print('Disconnected');
  });

  client.onError.listen((error) {
    print('Error: $error');
  });

  client.onState.listen((state) {
    print('State: $state');
  });

  // Connect
  await client.connect('wss://echo.websocket.org');
}
```
#### 应用截图
![image](https://github.com/msfm2018/rxws/blob/1.1.0/index.png)

