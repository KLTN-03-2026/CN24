import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: ChatScreen()),
  );
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  List<Map<String, String>> messages = [];

  void sendMessage() {
    String text = _controller.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add({"sender": "user", "text": text});
    });

    _controller.clear();

    botReply(text);
  }

  void botReply(String text) {
    String reply = "Tôi chưa hiểu câu hỏi.";

    if (text.toLowerCase().contains("hello") ||
        text.toLowerCase().contains("hi")) {
      reply = "Xin chào! Tôi có thể giúp gì cho bạn?";
    } else if (text.toLowerCase().contains("đặt xe")) {
      reply = "Bạn hãy nhập điểm đón và điểm đến để đặt xe.";
    } else if (text.toLowerCase().contains("giá")) {
      reply = "Giá chuyến đi phụ thuộc vào khoảng cách.";
    } else if (text.toLowerCase().contains("tài xế")) {
      reply = "Hệ thống đang tìm tài xế gần bạn.";
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        messages.add({"sender": "bot", "text": reply});
      });
    });
  }

  Widget buildMessage(Map<String, String> msg) {
    bool isUser = msg["sender"] == "user";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          msg["text"]!,
          style: TextStyle(color: isUser ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("RideNow Assistant")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return buildMessage(messages[index]);
              },
            ),
          ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Nhập tin nhắn...",
                    contentPadding: EdgeInsets.all(10),
                  ),
                ),
              ),

              IconButton(icon: const Icon(Icons.send), onPressed: sendMessage),
            ],
          ),
        ],
      ),
    );
  }
}
