import json
import re
from http.server import BaseHTTPRequestHandler, HTTPServer

# Bộ quy tắc phản hồi (Rule-based) cho RideNow
def get_intent_response(text: str) -> str:
    text = text.lower().strip()
    
    # 1. Chào hỏi
    if re.search(r'(chào|hello|hi|xin chào|hey)', text):
        return "👋 Xin chào! Tôi là RideNow Assistant. Tôi có thể giúp bạn các vấn đề về: Đặt xe, Giá cước, Hủy chuyến, Thanh toán, Khiếu nại và An toàn. Bạn cần hỗ trợ gì?"
        
    # 2. Đặt xe
    if re.search(r'(đặt xe|gọi xe|book|bắt xe|làm sao để đi)', text):
        return "🚗 **Hướng dẫn đặt xe:**\n1. Nhập điểm đón và điểm đến trên màn hình chính.\n2. Hệ thống sẽ tính giá cước dự kiến.\n3. Nhấn 'Đặt xe' để tìm tài xế gần nhất.\n\nBạn đã thử nhập địa chỉ chưa?"
        
    # 3. Giá cước
    if re.search(r'(giá|cước|bao nhiêu|tiền|phí|đắt)', text):
        return "💰 **Giá cước RideNow:**\n- 5.000đ cho mỗi km.\n- Giá hiển thị trên app là giá cuối cùng, cam kết không thu thêm phụ phí!"
        
    # 4. Hủy chuyến
    if re.search(r'(hủy|không đi nữa|đổi ý|huy chuyen)', text):
        return "❌ **Quy định hủy chuyến:**\nBạn có thể hủy chuyến miễn phí trước khi tài xế đến điểm đón. Lưu ý: Tránh hủy chuyến liên tục để không bị hạn chế tài khoản nhé."
        
    # 5. Thanh toán
    if re.search(r'(thanh toán|trả tiền|tiền mặt|chuyển khoản|thanh toan)', text):
        return "💳 **Thanh toán:**\nHiện tại RideNow hỗ trợ thanh toán bằng **Tiền mặt**. Bạn vui lòng trả trực tiếp cho tài xế sau khi kết thúc hành trình."
        
    # 6. Khiếu nại / Thái độ
    if re.search(r'(khiếu nại|thái độ|đi ẩu|tài xế tệ|report|không hài lòng)', text):
        return "🚨 **Hỗ trợ khiếu nại:**\nChúng tôi rất tiếc về trải nghiệm này. Bạn có thể:\n1. Đánh giá sao và để lại bình luận sau chuyến đi.\n2. Liên hệ hotline hỗ trợ: **1900-xxxx** để được xử lý ngay."
        
    # 7. An toàn
    if re.search(r'(an toàn|bảo hiểm|mũ bảo hiểm|tai nạn|an toan)', text):
        return "🛡️ **Quy định an toàn:**\n- Luôn đội mũ bảo hiểm khi ngồi trên xe.\n- Kiểm tra biển số xe và ảnh tài xế trước khi lên xe.\n- Chia sẻ hành trình cho người thân nếu cần thiết."

    # 8. Tài khoản
    if re.search(r'(tài khoản|mật khẩu|đăng ký|quên pass|thông tin)', text):
        return "👤 **Hỗ trợ tài khoản:**\n- Bạn có thể chỉnh sửa thông tin trong mục 'Hồ sơ'.\n- Nếu quên mật khẩu, hãy dùng chức năng 'Quên mật khẩu' tại màn hình đăng nhập."

    # Mặc định khi không hiểu
    return "🤔 Xin lỗi, tôi chưa hiểu rõ ý bạn. Bạn có thể hỏi về: Cách đặt xe, Giá cước, Hủy chuyến, Thanh toán hoặc Khiếu nại không?"

class ChatbotHandler(BaseHTTPRequestHandler):
    def _set_headers(self, status_code=200, content_length=None):
        self.send_response(status_code)
        self.send_header('Content-type', 'application/json')
        self.send_header('Connection', 'close')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        if content_length is not None:
            self.send_header('Content-Length', str(content_length))
        self.end_headers()
        self.close_connection = True

    def do_OPTIONS(self):
        self._set_headers()

    def do_GET(self):
        if self.path == '/':
            response = {"message": "RideNow Rule-based Chatbot Server is running!"}
            response_data = json.dumps(response).encode('utf-8')
            self._set_headers(200, len(response_data))
            self.wfile.write(response_data)
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
                
                # Lấy phản hồi từ bộ quy tắc
                reply = get_intent_response(user_message)
                
                response = {
                    "reply": reply,
                    "status": "success"
                }
                response_data = json.dumps(response).encode('utf-8')
                self._set_headers(200, len(response_data))
                self.wfile.write(response_data)
            except Exception as e:
                response = {"error": str(e)}
                response_data = json.dumps(response).encode('utf-8')
                self._set_headers(400, len(response_data))
                self.wfile.write(response_data)
        elif self.path == '/api/reset':
            response = {"status": "success", "message": "Chatbot reset"}
            response_data = json.dumps(response).encode('utf-8')
            self._set_headers(200, len(response_data))
            self.wfile.write(response_data)
        else:
            self.send_response(404)
            self.end_headers()

def run(server_class=HTTPServer, handler_class=ChatbotHandler, port=8000):
    server_address = ('0.0.0.0', port)
    httpd = server_class(server_address, handler_class)
    print(f'Starting RideNow Rule-based Server on port {port}...')
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()
    print('Server stopped.')

if __name__ == '__main__':
    run()
