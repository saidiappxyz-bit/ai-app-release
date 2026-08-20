import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

void main() {
  runApp(const GeminiMohammadApp());
}

class GeminiMohammadApp extends StatelessWidget {
  const GeminiMohammadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'جمنای محمد',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
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
  bool _autoSpeak = true;
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
    String cleanText = text.replaceAll(RegExp(r'[*_#`\-\+\[\]\(\)]'), ' ');
    await _tts.speak(cleanText);
  }

  Future<void> _stopSpeak() async {
    await _tts.stop();
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
          "system_instruction": {
            "parts": [
              {
                "text": "اسم تو 'جمنای محمد' است. تو یک هوش مصنوعی بسیار پیشرفته، باهوش، مهربان و استاد در کدنویسی و برنامه‌نویسی هستی. پاسخ‌هایت باید کاملاً به زبان فارسی، روان، محترمانه و دقیق باشد. تمام برنامه‌ها و کدهای درخواستی کاربر را با کیفیت عالی و توضیحات کامل فارسی ارائه بده."
              }
            ]
          },
          "contents": [
            {
              "parts": [
                {"text": text}
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
        if (_autoSpeak) {
          _speak(aiResponse);
        }
      } else {
        setState(() {
          _messages.add({
            "role": "ai",
            "content": "خطا در ارتباط با سرور. لطفاً کلید API را بررسی کنید."
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"role": "ai", "content": "خطا در اتصال: $e"});
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology, color: Colors.amber),
            SizedBox(width: 8),
            Text('جمنای محمد', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_autoSpeak ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() {
                _autoSpeak = !_autoSpeak;
              });
              if (!_autoSpeak) _stopSpeak();
            },
            tooltip: _autoSpeak ? 'خاموش کردن صدا' : 'روشن کردن صدا',
          )
        ],
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
                final content = msg["content"] ?? "";

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    maxWidth: MediaQuery.of(context).size.width * 0.85,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.indigo[100] : Colors.grey[100],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isUser ? "شما" : "جمنای محمد",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isUser ? Colors.indigo[900] : Colors.deepOrange[800],
                                fontSize: 12,
                              ),
                            ),
                            if (!isUser) ...[
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _speak(content),
                                child: const Icon(Icons.play_circle_fill, size: 18, color: Colors.indigo),
                              ),
                            ]
                          ],
                        ),
                        const SizedBox(height: 6),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: MarkdownBody(
                            data: content,
                            selectable: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(color: Colors.indigo),
            ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                )
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.indigo, size: 28),
                  onPressed: _sendMessage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textDirection: TextDirection.rtl,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'از جمنای محمد بپرسید...',
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
