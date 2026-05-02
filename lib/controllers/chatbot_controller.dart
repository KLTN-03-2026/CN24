import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_now_khoaluan/models/chat_message_model.dart';
import 'package:ride_now_khoaluan/services/ai_service.dart';

class ChatbotController extends GetxController {
  final AIService _aiService = AIService();
  final messages = <ChatMessage>[].obs;
  final isTyping = false.obs;
  final textController = TextEditingController();
  final scrollController = ScrollController();

  // 7 chủ đề tư vấn quick reply
  final List<Map<String, String>> quickReplies = [
    {'icon': '🚗', 'text': 'Cách đặt xe'},
    {'icon': '💰', 'text': 'Giá cước dự kiến'},
    {'icon': '❌', 'text': 'Hủy chuyến'},
    {'icon': '💳', 'text': 'Thanh toán'},
    {'icon': '🚨', 'text': 'Khiếu nại tài xế'},
    {'icon': '👤', 'text': 'Hỗ trợ tài khoản'},
    {'icon': '🛡️', 'text': 'Quy định an toàn'},
  ];

  // System prompt chứa toàn bộ kiến thức về Ride Now
  static const String _systemPrompt = '''
Bạn là **RideNow Assistant** — trợ lý AI thông minh của ứng dụng đặt xe RideNow.

## Thông tin về RideNow:
- RideNow là ứng dụng đặt xe máy (xe ôm công nghệ) tại Việt Nam
- Giá cước: 5.000đ/km, phí tối thiểu 15.000đ mỗi chuyến
- Thanh toán: Tiền mặt (trả trực tiếp cho tài xế khi kết thúc chuyến)
- Hoạt động 24/7

## Hướng dẫn đặt xe:
1. Mở app RideNow → Màn hình Trang chủ
2. Nhập điểm đón (hoặc dùng vị trí hiện tại)
3. Nhập điểm đến (tìm kiếm địa chỉ)
4. Hệ thống hiển thị khoảng cách và giá cước dự kiến
5. Nhấn "Đặt xe" → Hệ thống tự động tìm tài xế gần nhất
6. Khi tài xế nhận chuyến → Hiển thị thông tin tài xế (tên, SĐT, biển số xe)
7. Theo dõi tài xế trên bản đồ realtime

## Quy định hủy chuyến:
- Khách có thể hủy chuyến bất cứ lúc nào trước khi tài xế đến điểm đón
- Hủy chuyến quá nhiều lần có thể bị hạn chế sử dụng
- Nếu tài xế đã đến điểm đón mà khách hủy, khách nên thông báo sớm

## Thanh toán:
- Hiện tại chỉ hỗ trợ thanh toán tiền mặt
- Trả tiền trực tiếp cho tài xế khi kết thúc chuyến
- Giá hiển thị trên app là giá cuối cùng, không phát sinh thêm

## Khiếu nại tài xế:
- Nếu gặp vấn đề với tài xế, khách có thể đánh giá sao sau chuyến đi
- Liên hệ hotline: 1900-xxxx để khiếu nại nghiêm trọng
- Các vấn đề: đi sai đường, thái độ không tốt, thu phí sai

## Hỗ trợ tài khoản:
- Đăng ký bằng email và mật khẩu
- Quên mật khẩu: dùng chức năng "Quên mật khẩu" trên màn hình đăng nhập
- Đổi mật khẩu: vào Hồ sơ → Đổi mật khẩu
- Cập nhật thông tin: vào Hồ sơ → chỉnh sửa tên, ảnh đại diện

## Quy định an toàn:
- Luôn đội mũ bảo hiểm khi ngồi trên xe
- Kiểm tra biển số xe và thông tin tài xế trước khi lên xe
- Chia sẻ hành trình với người thân nếu cần
- Không để đồ có giá trị ở nơi dễ rơi
- Tài xế phải có giấy phép lái xe và bảo hiểm xe hợp lệ

## Quy tắc trả lời:
- Trả lời bằng tiếng Việt, ngắn gọn, thân thiện, dễ hiểu
- Dùng emoji phù hợp để tạo sự thân thiện
- Nếu câu hỏi nằm ngoài phạm vi app RideNow, lịch sự từ chối và gợi ý liên hệ hotline
- Mỗi câu trả lời không quá 150 từ
- Khi không chắc chắn, đề nghị khách liên hệ hotline 1900-xxxx
''';

  @override
  void onInit() {
    super.onInit();
    _initChat();
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _initChat() {
    // Khởi tạo phiên chat với system prompt
    if (_aiService.isInitialized) {
      _aiService.startNewChat(_systemPrompt);
    }

    // Tin nhắn chào mừng
    messages.add(ChatMessage(
      text:
          'Xin chào! 👋 Tôi là **RideNow Assistant**, trợ lý AI của bạn.\n\nTôi có thể giúp bạn về:\n🚗 Đặt xe\n💰 Giá cước\n❌ Hủy chuyến\n💳 Thanh toán\n🚨 Khiếu nại\n👤 Tài khoản\n🛡️ An toàn\n\nBạn cần hỗ trợ gì?',
      isUser: false,
    ));
  }

  /// Gửi tin nhắn
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = text.trim();
    textController.clear();

    // Thêm tin nhắn user
    messages.add(ChatMessage(text: userMessage, isUser: true));

    // Scroll xuống
    _scrollToBottom();

    // Hiển thị typing indicator
    isTyping.value = true;
    final loadingMsg = ChatMessage(
      text: '',
      isUser: false,
      type: MessageType.loading,
    );
    messages.add(loadingMsg);
    _scrollToBottom();

    // Gọi AI
    String response;
    if (_aiService.isInitialized) {
      response = await _aiService.sendMessage(userMessage);
    } else {
      response = _getFallbackResponse(userMessage);
    }

    // Xóa loading, thêm response
    messages.removeWhere((m) => m.id == loadingMsg.id);
    isTyping.value = false;

    messages.add(ChatMessage(text: response, isUser: false));
    _scrollToBottom();
  }

  /// Gửi quick reply
  void sendQuickReply(String text) {
    sendMessage(text);
  }

  /// Reset chat
  void resetChat() {
    messages.clear();
    if (_aiService.isInitialized) {
      _aiService.resetChat(_systemPrompt);
    }
    _initChat();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Fallback khi AI chưa sẵn sàng (tương tự chatbot cũ nhưng tốt hơn)
  String _getFallbackResponse(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('đặt xe') || lower.contains('dat xe')) {
      return '🚗 **Cách đặt xe:**\n1. Nhập điểm đón và điểm đến\n2. Xem giá cước dự kiến\n3. Nhấn "Đặt xe"\n4. Đợi tài xế nhận chuyến\n\nRất đơn giản! Bạn cần hỗ trợ thêm gì không?';
    }
    if (lower.contains('giá') || lower.contains('cước') || lower.contains('gia')) {
      return '💰 **Giá cước RideNow:**\n• 5.000đ/km\n• Phí tối thiểu: 15.000đ/chuyến\n• Giá hiển thị trên app là giá cuối cùng\n\nVí dụ: Chuyến 5km = 25.000đ';
    }
    if (lower.contains('hủy') || lower.contains('huy')) {
      return '❌ Bạn có thể hủy chuyến trước khi tài xế đến điểm đón. Lưu ý hủy quá nhiều có thể bị hạn chế nhé!';
    }
    if (lower.contains('thanh toán') || lower.contains('trả tiền')) {
      return '💳 Hiện tại RideNow hỗ trợ **thanh toán tiền mặt** — trả trực tiếp cho tài xế khi kết thúc chuyến.';
    }
    if (lower.contains('khiếu nại') || lower.contains('report')) {
      return '🚨 Để khiếu nại, bạn có thể đánh giá sao sau chuyến đi hoặc liên hệ hotline **1900-xxxx**.';
    }
    if (lower.contains('tài khoản') || lower.contains('mật khẩu') || lower.contains('đăng ký')) {
      return '👤 **Hỗ trợ tài khoản:**\n• Đăng ký bằng email\n• Quên mật khẩu → dùng "Quên mật khẩu"\n• Đổi MK → Hồ sơ → Đổi mật khẩu';
    }
    if (lower.contains('an toàn') || lower.contains('bảo hiểm')) {
      return '🛡️ **Quy định an toàn:**\n• Luôn đội mũ bảo hiểm\n• Kiểm tra biển số xe và tài xế\n• Chia sẻ hành trình với người thân';
    }

    return '🤔 Tôi có thể hỗ trợ bạn về: đặt xe, giá cước, hủy chuyến, thanh toán, khiếu nại, tài khoản, an toàn. Bạn muốn hỏi về vấn đề nào?';
  }
}
