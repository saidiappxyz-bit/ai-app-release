import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF101014),
        primaryColor: Colors.blueAccent,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final FlutterTts flutterTts = FlutterTts();
  bool _isLoading = false;
  
  // کلید API اختصاصی
  final String apiKey = "YOUR_GEMINI_API_KEY";

  @override
  void initState() {
    super.initState();
    flutterTts.setLanguage("fa-IR");
    flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await flutterTts.speak(text);
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _isLoading = true;
    });
    _controller.clear();

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey'
    );

    final contents = _messages.map((m) => {
      "role": m["role"] == "user" ? "user" : "model",
      "parts": [{"text": m["text"]}]
    }).toList();

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"contents": contents}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _messages.add({"role": "model", "text": reply});
        });
        _speak(reply);
      } else {
        setState(() {
          _messages.add({"role": "model", "text": "خطا در برقراری ارتباط با API"});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"role": "model", "text": "خطای شبکه: $e"});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دستیار هوشمند (صوتی + کدنویسی)'),
        backgroundColor: const Color(0xFF1E1E24),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : const Color(0xFF282830),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: MarkdownBody(
                      data: msg["text"] ?? "",
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Colors.white, fontSize: 15),
                        code: const TextStyle(backgroundColor: Colors.black45, color: Colors.greenAccent),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF1E1E24),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () => _sendMessage(_controller.text),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      hintText: 'دستور یا سوال خود را بنویسید...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
