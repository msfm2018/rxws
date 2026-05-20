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
  final ws = RxWs();

  final List<String> messages = [];

  StreamSubscription? _msgSub;
  StreamSubscription? _stateSub;

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
    // 1. 连接本地测试服务 (ws)
    await ws.connect("ws://127.0.0.1:8080/ws");
    // 2. 连接线上生产环境 (wss)
    // await ws.connect("wss://example.com/live");
    // 消息流
    _msgSub = ws.messages.listen((message) {
      if (!mounted) return;
      print(message.toString());
      setState(() {
        messages.add(message.toString());
      });
    });

    // 状态流
    _stateSub = ws.states.listen((s) {
      if (!mounted) return;

      setState(() {
        status = s.toString();
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
      ws.sendText(text);

      setState(() {
        messages.add("me: $text");
      });

      _inputCtrl.clear();
    } finally {
      _isSending = false;
    }
  }

  // =========================
  // RECONNECT MANUAL
  // =========================
  Future<void> reconnect() async {
    ws.close();
    await Future.delayed(const Duration(seconds: 1));
    await ws.connect("ws://127.0.0.1:8080/ws");
  }

  // =========================
  // DISPOSE
  // =========================
  @override
  void dispose() {
    _msgSub?.cancel();
    _stateSub?.cancel();
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
        title: const Text("Raw WebSocket (Protocol Level)"),
        actions: [IconButton(onPressed: reconnect, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          // =====================
          // STATUS BAR
          // =====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: _getStatusColor(status),
            child: Text("状态: $status", style: const TextStyle(color: Colors.white)),
          ),

          // =====================
          // MESSAGE LIST
          // =====================
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (_, i) {
                return ListTile(title: Text(messages[i]));
              },
            ),
          ),

          // =====================
          // INPUT AREA
          // =====================
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

  // =========================
  // STATUS COLOR
  // =========================
  Color _getStatusColor(String status) {
    if (status.contains("open")) return Colors.green;
    if (status.contains("connecting")) return Colors.orange;
    if (status.contains("closed")) return Colors.red;
    return Colors.grey;
  }
}
