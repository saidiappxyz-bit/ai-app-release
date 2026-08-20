import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

void main() => runApp(const AIChatApp());

class AIChatApp extends StatelessWidget {
  const AIChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'هوش مصنوعی فارسی',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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
  final FlutterTts _tts = FlutterTts();
  bool _isLoading = false;
  final String _apiKey = "YOUR_GEMINI_API_KEY";

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _tts.setLanguage("fa-IR");
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    String cleanText = text.replaceAll(RegExp(r'[*_#`]'), '');
    await _tts.speak(cleanText);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isLoading = true;
    });
    _controller.clear();

    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": "تو یک دستیار هوش مصنوعی هوشمند و مسلط به زبان فارسی و برنامه‌نویسی هستی. همیشه پاسخ‌ها را روان، به زبان فارسی و دقیق ارائه بده.\n\nکاربر: $text"}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _messages.add({"role": "ai", "content": aiResponse});
        });
        _speak(aiResponse);
      } else {
        setState(() {
          _messages.add({"role": "ai", "content": "خطا در برقراری ارتباط. لطفا کلید API را بررسی کنید."});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"role": "ai", "content": "خطایی رخ داد: $e"});
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دستیار هوشمند فارسی (با ویس)'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {override
                final msg = _messages[index];
                final isUser = msg["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.deepPurple[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: MarkdownBody(data: msg["content"] ?? ""),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: _sendMessage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      hintText: 'پیام خود را بنویسید...',
                      border: OutlineInputBorder(),
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
