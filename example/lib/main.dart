import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rxws/rxws.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: WSPage());
  }
}

class WSPage extends StatefulWidget {
  const WSPage({super.key});

  @override
  State<WSPage> createState() => _WSPageState();
}

class _WSPageState extends State<WSPage> {
  final ws = createWsClient();

  final List<String> messages = [];

  StreamSubscription? _msgSub;
  StreamSubscription? _openSub;
  StreamSubscription? _closeSub;
  StreamSubscription? _errorSub;

  String status = "connecting...";

  final TextEditingController _inputCtrl = TextEditingController();

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initWS();
  }

  // =========================
  // CONNECT
  // =========================
  Future<void> _initWS() async {
    // await ws.connect("ws://127.0.0.1:8080/ws");
    await ws.connect("wss://echo.websocket.org");
    // await ws.connect("ws://127.0.0.1:1234");

    ws.onState.listen((state) {
      switch (state) {
        case WSState.connecting:
          print("连接中...");
          break;

        case WSState.open:
          print("已连接");
          break;

        case WSState.closed:
          print("已断开");
          break;

        case WSState.closing:
          print("关闭中");
          break;
      }
    });
    // ✅ 消息
    _msgSub = ws.onMessage.listen((message) {
      if (!mounted) return;
      // print(message.toString());
      setState(() {
        messages.add(message.toString());
      });
    });

    // ✅ 打开
    _openSub = ws.onOpen.listen((_) {
      if (!mounted) return;

      setState(() {
        status = "open";
      });
    });

    // ✅ 关闭
    _closeSub = ws.onClose.listen((_) {
      if (!mounted) return;

      setState(() {
        status = "closed";
      });
    });

    // ✅ 错误
    _errorSub = ws.onError.listen((e) {
      if (!mounted) return;

      setState(() {
        status = "error";
        messages.add("❌ error: $e");
      });
    });
  }

  // =========================
  // SEND MESSAGE
  // =========================
  Future<void> sendMessage() async {
    if (_isSending) return;

    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    _isSending = true;

    try {
      ws.send(text); // ✅ 改这里

      setState(() {
        messages.add("me: $text");
      });

      _inputCtrl.clear();
    } finally {
      _isSending = false;
    }
  }

  // =========================
  // RECONNECT
  // =========================
  Future<void> reconnect() async {
    ws.close();
    await Future.delayed(const Duration(seconds: 1));
    await _initWS();
  }

  // =========================
  // DISPOSE
  // =========================
  @override
  void dispose() {
    _msgSub?.cancel();
    _openSub?.cancel();
    _closeSub?.cancel();
    _errorSub?.cancel();
    ws.close();
    _inputCtrl.dispose();
    super.dispose();
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cross Platform WebSocket"),
        actions: [IconButton(onPressed: reconnect, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          // 状态
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: _getStatusColor(status),
            child: Text("状态: $status", style: const TextStyle(color: Colors.white)),
          ),

          // 消息列表
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (_, i) {
                return ListTile(title: Text(messages[i]));
              },
            ),
          ),

          // 输入框
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: const InputDecoration(hintText: "输入消息...", border: OutlineInputBorder()),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: sendMessage, child: const Text("发送")),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == "open") return Colors.green;
    if (status == "connecting") return Colors.orange;
    if (status == "closed") return Colors.red;
    if (status == "error") return Colors.redAccent;
    return Colors.grey;
  }
}
