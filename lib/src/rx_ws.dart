import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

enum WSState { connecting, open, closing, closed }

enum OpCode { continuation, text, binary, close, ping, pong }

class RxWs {
  Socket? _socket;

  WSState _state = WSState.closed;

  final _messageController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get messages => _messageController.stream;

  final _stateController = StreamController<WSState>.broadcast();
  Stream<WSState> get states => _stateController.stream;

  Uint8List _buffer = Uint8List(0);

  // fragmentation
  List<int> _fragmentBuffer = [];
  int? _fragmentOpcode;
  String? _handshakeKey; // 保存 key 用于验证
  // backpressure
  final _sendQueue = <List<int>>[];
  bool _isSending = false;

  // reconnect
  int _retry = 0;
  final int _maxRetry = 10;

  // heartbeat
  Timer? _heartbeat;
  Timer? _pongTimeout;

  late String _host;
  late int _port;
  late String _path;
  bool _useTLS = false;

  Map<String, String> headers = {};

  // =========================
  // CONNECT (支持直接传入完整的 ws:// 或 wss:// 链接)
  // =========================
  Future<void> connect(String urlString, {Map<String, String>? headers}) async {
    try {
      // 1. 利用 Uri 自动解析 URL
      final uri = Uri.parse(urlString);
      if (uri.scheme != 'ws' && uri.scheme != 'wss') {
        throw ArgumentError("协议错误：必须以 ws:// 或 wss:// 开头");
      }

      // 2. 自动判定是否为安全连接 (wss)
      _useTLS = (uri.scheme == 'wss');
      _host = uri.host;
      // 如果 URL 里没写端口，ws 默认 80，wss 默认 443
      _port = uri.hasPort ? uri.port : (_useTLS ? 443 : 80);
      // 确保 path 不能为空，至少为 "/"
      _path = uri.path.isEmpty ? "/" : uri.path;
      if (uri.hasQuery) {
        _path += "?${uri.query}"; // 顺便把 query 参数也带上，比如 ?token=123
      }

      if (headers != null) this.headers = headers;

      _setState(WSState.connecting);

      // 3. 根据是否是 wss 选择 Socket 还是 SecureSocket
      _socket = await (_useTLS ? SecureSocket.connect(_host, _port) : Socket.connect(_host, _port)).timeout(const Duration(seconds: 10));

      _retry = 0;

      final key = base64Encode(List<int>.generate(16, (_) => Random().nextInt(256)));
      _handshakeKey = key;

      // 如果没有额外 header，记得给个空字符串，避免追加多余换行
      final headerStr = this.headers.isNotEmpty ? "${this.headers.entries.map((e) => "${e.key}: ${e.value}").join("\r\n")}\r\n" : "";

      // 4. 组装标准的 HTTP 握手报文
      final request = 'GET $_path HTTP/1.1\r\n'
          'Host: $_host:$_port\r\n'
          'Upgrade: websocket\r\n'
          'Connection: Upgrade\r\n'
          'Sec-WebSocket-Key: $key\r\n'
          'Sec-WebSocket-Version: 13\r\n'
          '$headerStr' // 已经自带末尾 \r\n
          '\r\n';

      _socket!.add(utf8.encode(request));
      _socket!.listen(_onData, onDone: _onClose, onError: (_) => _onClose());
    } catch (_) {
      _reconnect();
    }
  }

  void _setState(WSState s) {
    _state = s;
    _stateController.add(s);
  }

  void _onData(Uint8List data) {
    _buffer = Uint8List.fromList([..._buffer, ...data]);

    if (_state == WSState.connecting) {
      _tryCompleteHandshake();
      return;
    }

    _parseFrames();
  }

  // 新增：专门处理握手
  void _tryCompleteHandshake() {
    final str = utf8.decode(_buffer, allowMalformed: true);
    final headerEndIndex = str.indexOf("\r\n\r\n");

    if (headerEndIndex == -1) return; // 还没收到完整头

    final headerPart = str.substring(0, headerEndIndex + 4);

    // 1. 检查状态码
    if (!headerPart.contains("101 Switching Protocols")) {
      // print("握手失败: 非 101 响应");
      _reconnect();
      return;
    }

    // 2. 检查并验证 Sec-WebSocket-Accept
    final acceptPattern = RegExp(r'Sec-WebSocket-Accept:\s*([a-zA-Z0-9+/=]+)', caseSensitive: false);
    final match = acceptPattern.firstMatch(headerPart);
    if (match == null) {
      // print("握手失败: 缺少 Sec-WebSocket-Accept");
      _reconnect();
      return;
    }

    final serverAccept = match.group(1)!;
    final expectedAccept = base64Encode(sha1.convert(utf8.encode("${_handshakeKey!}258EAFA5-E914-47DA-95CA-C5AB0DC85B11")).bytes);

    if (serverAccept != expectedAccept) {
      // print("握手失败: Sec-WebSocket-Accept 不匹配");
      _reconnect();
      return;
    }

    // === 握手成功 ===
    // print("WebSocket 握手成功");

    // 关键修复：保留握手之后的数据
    final headerBytesLength = utf8.encode(headerPart).length;
    if (_buffer.length > headerBytesLength) {
      _buffer = _buffer.sublist(headerBytesLength);
    } else {
      _buffer = Uint8List(0);
    }

    _setState(WSState.open);
    _startHeartbeat();

    // 立即解析可能已经收到的第一帧
    if (_buffer.isNotEmpty) {
      _parseFrames();
    }
  }

  int _bufferOffset = 0;

  void _parseFrames() {
    while (true) {
      if (_bufferOffset + 2 > _buffer.length) return;

      int offset = _bufferOffset;

      final byte1 = _buffer[offset++];
      final fin = (byte1 & 0x80) != 0;
      final opcode = byte1 & 0x0F;

      final byte2 = _buffer[offset++];
      final masked = (byte2 & 0x80) != 0;
      int payloadLen = byte2 & 0x7F;

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

      List<int>? maskKey;
      if (masked) {
        if (offset + 4 > _buffer.length) return;
        maskKey = _buffer.sublist(offset, offset + 4);
        offset += 4;
      }

      if (offset + payloadLen > _buffer.length) return;

      final payload = _buffer.sublist(offset, offset + payloadLen);

      if (masked && maskKey != null) {
        for (int i = 0; i < payload.length; i++) {
          payload[i] ^= maskKey[i % 4];
        }
      }

      _handleFrame(fin, opcode, payload);

      // 更新 offset
      _bufferOffset = offset + payloadLen;

      // 如果已经解析完当前 buffer 的内容，清空 buffer
      if (_bufferOffset >= _buffer.length) {
        _buffer = Uint8List(0);
        _bufferOffset = 0;
        break;
      }
    }
  }

  // =========================
  // FRAME HANDLE
  // =========================
  void _handleFrame(bool fin, int opcode, List<int> payload) {
    // fragmentation
    if (opcode == 0x0) {
      _fragmentBuffer.addAll(payload);
      if (fin) {
        _emitMessage(_fragmentOpcode!, _fragmentBuffer);
        _fragmentBuffer = [];
      }
      return;
    }

    if (!fin) {
      _fragmentOpcode = opcode;
      _fragmentBuffer = payload;
      return;
    }

    _emitMessage(opcode, payload);
  }

  void _emitMessage(int opcode, List<int> payload) {
    switch (opcode) {
      case 0x1: // text
        try {
          final text = utf8.decode(payload, allowMalformed: false);
          _messageController.add(text);
        } catch (_) {
          close();
        }
        break;

      case 0x2: // binary
        _messageController.add(payload);
        break;

      case 0x8: // close
        // if (payload.length >= 2) {
        //  final code = (payload[0] << 8) | payload[1];
        // final reason = payload.length > 2 ? utf8.decode(payload.sublist(2)) : '';
        // 可以加个 close 事件
        // }
        close();
        break;

      case 0x9: // ping
        _enqueue(_buildFrame(0xA, []));
        break;

      case 0xA: // pong
        // print("收到");
        _pongTimeout?.cancel();
        break;
    }
  }

  // =========================
  // SEND (backpressure)
  // =========================
  void _enqueue(List<int> frame) {
    _sendQueue.add(frame);
    _flush();
  }

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
  // PUBLIC SEND API
  // =========================
  void sendText(String text) {
    _enqueue(_buildFrame(0x1, utf8.encode(text)));
  }

  void sendBinary(List<int> data) {
    _enqueue(_buildFrame(0x2, data));
  }

  void ping() {
    _enqueue(_buildFrame(0x9, []));
    _startPongTimeout();
  }

  // =========================
  // FRAME BUILD
  // =========================
  List<int> _buildFrame(int opcode, List<int> payload) {
    final frame = <int>[];

    frame.add(0x80 | opcode);

    final maskBit = 0x80;
    final length = payload.length;

    if (length <= 125) {
      frame.add(maskBit | length);
    } else if (length <= 65535) {
      frame.add(maskBit | 126);
      frame.add((length >> 8) & 0xFF);
      frame.add(length & 0xFF);
    } else {
      frame.add(maskBit | 127);
      for (int i = 7; i >= 0; i--) {
        frame.add((length >> (8 * i)) & 0xFF);
      }
    }

    final maskKey = List.generate(4, (_) => Random().nextInt(256));
    frame.addAll(maskKey);

    for (int i = 0; i < payload.length; i++) {
      frame.add(payload[i] ^ maskKey[i % 4]);
    }

    return frame;
  }

  // =========================
  // HEARTBEAT
  // =========================
  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(Duration(seconds: 10), (_) {
      ping();
    });
  }

  void _startPongTimeout() {
    _pongTimeout?.cancel();
    _pongTimeout = Timer(Duration(seconds: 5), () {
      _reconnect();
    });
  }

  // =========================
  // RECONNECT
  // =========================
  void _reconnect() {
    if (_state == WSState.closing) return;

    // 彻底清理旧资源
    _cleanup();

    _setState(WSState.closed);

    if (_retry >= _maxRetry) {
      // print("达到最大重连次数，停止重连");
      return;
    }

    final delay = pow(2, _retry).toInt();
    _retry++;

    // print("将在 $delay 秒后重连...");
    // 在 _reconnect() 的 Future.delayed 内部：
    Future.delayed(Duration(seconds: delay), () {
      // 重新组装原始的 URL 传进去即可
      final scheme = _useTLS ? "wss" : "ws";
      connect("$scheme://$_host:$_port$_path", headers: headers);
    });
  }

  void _cleanup() {
    _heartbeat?.cancel();
    _pongTimeout?.cancel();
    _socket?.destroy();
    _socket = null;
    _buffer = Uint8List(0);
    _bufferOffset = 0;
    _sendQueue.clear();
    _fragmentBuffer.clear();
    _isSending = false;
  }

  // =========================
  // CLOSE
  // =========================
  void close() {
    _setState(WSState.closing);
    _enqueue(_buildFrame(0x8, []));
    _socket?.close();
    _setState(WSState.closed);
  }

  void _onClose() {
    _heartbeat?.cancel();
    _pongTimeout?.cancel();
    _reconnect();
  }
}
