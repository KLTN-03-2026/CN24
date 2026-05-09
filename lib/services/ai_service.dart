import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  bool _isInitialized = true; // Luôn true vì custom server không cần init cầu kỳ
  
  // Lấy URL của Custom Server (nếu chạy giả lập Android dùng 10.0.2.2, iOS dùng 127.0.0.1)
  String get _serverUrl {
    if (kIsWeb) return 'http://localhost:8000/api/chat';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/chat';
    return 'http://127.0.0.1:8000/api/chat';
  }

  void initialize(String apiKey) {
    // Không cần dùng đến apiKey nữa do chạy local server
    print('AIService: Đã chuyển sang dùng Custom Local Server tại $_serverUrl');
  }

  bool get isInitialized => _isInitialized;

  void startNewChat(String systemPrompt) {
    // Custom Server của chúng ta không cần lưu context session (hiện tại)
    // Mỗi tin nhắn độc lập. Nếu sau này server hỗ trợ session, ta thêm vào đây.
  }

  /// Gửi tin nhắn lên Custom Server và nhận phản hồi
  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'message': message,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['reply'] ?? 'Lỗi: Server không trả về nội dung.';
      } else {
        print('AIService Server Error: ${response.statusCode}');
        return 'Xin lỗi, máy chủ Chatbot đang gặp sự cố (Lỗi ${response.statusCode}).';
      }
    } catch (e) {
      print('AIService Connection Error: $e');
      return 'Không thể kết nối đến máy chủ Chatbot. Hãy chắc chắn rằng bạn đã chạy Server Python!';
    }
  }

  void resetChat(String systemPrompt) async {
    try {
      final resetUrl = _serverUrl.replaceAll('/api/chat', '/api/reset');
      await http.post(Uri.parse(resetUrl));
      print('AIService: Đã gọi API reset trạng thái server thành công.');
    } catch (e) {
      print('AIService Reset Error: $e');
    }
  }
}
