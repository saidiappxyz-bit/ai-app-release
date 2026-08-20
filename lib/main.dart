import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const GeminiMohammadApp());

class GeminiMohammadApp extends StatelessWidget {
  const GeminiMohammadApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'جمنای محمد',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
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
  final String _apiKey = "کلید_واقعی_خودت";

  @override
  void initState() {
    super.initState();
    _tts.setLanguage("fa-IR");
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
          "system_instruction": {"parts": [{"text": "تو 'جمنای محمد' هستی. هوش مصنوعی فوق‌هوشمند، مسلط به تمام زبان‌های دنیا و استاد کدنویسی. پاسخ‌ها را دقیق، کامل و به زبان خود کاربر بنویس. اگر کاربر فارسی خواست، اولویت با فارسی است."}]},
          "contents": [{"parts": [{"text": text}]}]
        }),
      );
      if (response.statusCode == 200) {
        final aiResponse = jsonDecode(response.body)['candidates'][0]['content']['parts'][0]['text'];
        setState(() => _messages.add({"role": "ai", "content": aiResponse}));
        _tts.speak(aiResponse);
      }
    } catch (e) {
      setState(() => _messages.add({"role": "ai", "content": "خطا: $e"}));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جمنای محمد'), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      body: Column(
        children: [
          Expanded(child: ListView.builder(itemCount: _messages.length, itemBuilder: (context, i) => ListTile(title: Text(_messages[i]['content']!)))),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(children: [Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'بپرس...'))), IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage)]),
          )
        ],
      ),
    );
  }
}
