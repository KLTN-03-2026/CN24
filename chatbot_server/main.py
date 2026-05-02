import json
import re
from http.server import BaseHTTPRequestHandler, HTTPServer

# Trạng thái của Chatbot (Mặc định là đang bật, nhưng ta có thể tuỳ chỉnh)
# Theo yêu cầu: nhắn "thoát" thì dừng, nhắn "bắt đầu" thì chạy lại.
chat_active = True 

def get_intent_response(text: str) -> str:
    global chat_active
    text = text.lower().strip()
    
    # Logic Bật/Tắt Chatbot
    if text == 'thoát' or text == 'thoat':
        chat_active = False
        return "🛑 Chatbot đã được tắt. File main.py tạm dừng nhận lệnh. (Nhắn 'bắt đầu' để khởi động lại)."
        
    if not chat_active:
        if text == 'bắt đầu' or text == 'bat dau':
            chat_active = True
            return "✅ Chatbot đã khởi động lại! Xin chào, tôi là RideNow Assistant. Tôi có thể giúp gì cho bạn?"
        else:
            return "💤 Chatbot đang trong trạng thái tắt. Vui lòng nhắn 'bắt đầu' để khởi động lại."

    # --- CÁC LOGIC CHATBOT BÌNH THƯỜNG BÊN DƯỚI (Chỉ chạy khi chat_active = True) ---
    
    if re.search(r'(đặt xe|gọi xe|book|bắt xe)', text):
        return "🚗 **Hướng dẫn đặt xe:**\n1. Mở app RideNow\n2. Chọn điểm đón và điểm đến\n3. Xem giá cước và bấm 'Đặt xe'\n4. Tài xế gần nhất sẽ đến đón bạn ngay!"
        
    if re.search(r'(giá|cước|bao nhiêu|tiền|phí)', text):
        return "💰 **Giá cước RideNow:**\n- 5.000đ cho mỗi km.\n- Phí tối thiểu cho mỗi chuyến là 15.000đ.\n- Giá hiển thị trên app là giá cuối cùng, không phụ thu!"
        
    if re.search(r'(hủy|huy chuyen|không đi nữa|hông di nữa| làm sao để huy chuyển)', text):
        return "❌ **Quy định hủy chuyến:**\nBạn có thể hủy chuyến miễn phí trước khi tài xế đến điểm đón. Lưu ý: Hủy chuyến quá nhiều lần có thể bị hạn chế tài khoản để đảm bảo quyền lợi cho tài xế."
        
    if re.search(r'(thanh toán|trả tiền|tiền mặt|chuyển khoản)', text):
        return "💳 **Thanh toán:**\nHiện tại RideNow hỗ trợ thanh toán bằng **Tiền mặt**. Bạn vui lòng thanh toán trực tiếp cho tài xế sau khi chuyến đi kết thúc nhé."
        
    if re.search(r'(khiếu nại|thái độ|đi ẩu|tài xế tệ|report)', text):
        return "🚨 **Khiếu nại:**\nRideNow rất tiếc nếu bạn có trải nghiệm không tốt. Để khiếu nại, bạn có thể:\n1. Đánh giá 1 sao sau chuyến đi và để lại nhận xét.\n2. Gọi hotline hỗ trợ 24/7: **1900-xxxx**."
        
    if re.search(r'(tài khoản|mật khẩu|đăng nhập|đăng ký|quên pass)', text):
        return "👤 **Hỗ trợ Tài khoản:**\n- Đăng ký: Bằng email.\n- Quên mật khẩu: Chọn 'Quên mật khẩu' ở màn hình đăng nhập.\n- Chỉnh sửa thông tin: Vào mục 'Hồ sơ' trong app."
        
    if re.search(r'(an toàn|bảo hiểm|mũ bảo hiểm|tai nạn|an toan)', text):
        return "🛡️ **Quy định an toàn:**\n- Vui lòng luôn đội mũ bảo hiểm khi lên xe.\n- Kiểm tra đúng biển số xe và tài xế trước khi đi.\n- Tất cả tài xế RideNow đều có bằng lái và bảo hiểm hợp lệ."
        
    if re.search(r'(chào|hello|hi|xin chào|xin chao)', text):
        return "👋 Xin chào! Tôi là RideNow Assistant. Tôi có thể giúp bạn các vấn đề về: Đặt xe, Giá cước, Hủy chuyến, Thanh toán, Khiếu nại, Tài khoản và An toàn. Bạn cần hỗ trợ gì?"

    return "🤔 Xin lỗi, tôi chưa hiểu ý bạn lắm. Bạn có thể hỏi rõ hơn về các chủ đề: đặt xe, giá cước, thanh toán, hủy chuyến, khiếu nại, tài khoản, hoặc an toàn không?"

class ChatbotHandler(BaseHTTPRequestHandler):
    def _set_headers(self, status_code=200):
        self.send_response(status_code)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def do_OPTIONS(self):
        self._set_headers()

    def do_GET(self):
        if self.path == '/':
            self._set_headers()
            response = {"message": "RideNow Chatbot Server is running!"}
            self.wfile.write(json.dumps(response).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path == '/api/chat':
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length)
            try:
                data = json.loads(post_data.decode('utf-8'))
                user_message = data.get('message', '')
                
                reply = get_intent_response(user_message)
                
                self._set_headers()
                response = {
                    "reply": reply,
                    "status": "success"
                }
                self.wfile.write(json.dumps(response).encode('utf-8'))
            except Exception as e:
                self._set_headers(400)
                response = {"error": str(e)}
                self.wfile.write(json.dumps(response).encode('utf-8'))
        elif self.path == '/api/reset':
            global chat_active
            chat_active = True
            self._set_headers()
            response = {"status": "success", "message": "Chatbot reset and active"}
            self.wfile.write(json.dumps(response).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

def run(server_class=HTTPServer, handler_class=ChatbotHandler, port=8000):
    server_address = ('0.0.0.0', port)
    httpd = server_class(server_address, handler_class)
    print(f'Starting httpd server on port {port}...')
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()
    print('Server stopped.')

if __name__ == '__main__':
    run()
