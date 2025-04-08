from http.server import BaseHTTPRequestHandler, HTTPServer
import json
from urllib.parse import urlparse, parse_qs

# 사용 불가능한 사용자 이름 목록
unavailable_usernames = ['jmbae', 'johnnyappleseed', 'page', 'johndoe']

class UserNameHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # URL 파싱
        parsed_url = urlparse(self.path)
        
        # 요청 경로가 /isUserNameAvailable인지 확인
        if parsed_url.path == '/isUserNameAvailable':
            # 쿼리 파라미터 파싱
            query_params = parse_qs(parsed_url.query)

            # userName 파라미터가 있는지 확인
            if 'userName' in query_params:
                username = query_params['userName'][0]
                # 금지된 사용자 이름 확인
                if username in ['admin', 'superuser']:
                    self.send_response(400)
                    self.send_header('Content-Type', 'application/json; charset=utf-8') # UTF-8 명시
                    self.end_headers()
                    error_response = {
                        "error": True,
                        "reason": f"Username is not valid: {username}."
                    }
                    self.wfile.write(json.dumps(error_response).encode('utf-8')) # UTF-8 인코딩
                    return

                # 서버 에러 시뮬레이션 - 데이터베이스 손상
                if username == 'servererror':
                    self.send_response(500)
                    self.send_header('Content-Type', 'application/json; charset=utf-8') # UTF-8 명시
                    self.end_headers()
                    error_response = {
                        "error": True,
                        "reason": "The database is corrupted"
                    }
                    self.wfile.write(json.dumps(error_response).encode('utf-8')) # UTF-8 인코딩
                    return
                
                # 유지보수 에러 시뮬레이션
                if not hasattr(self.__class__, 'maintenance_counter'):
                    self.__class__.maintenance_counter = 0
                
                if username == 'maintenance':
                    self.__class__.maintenance_counter += 1
                    print(f"Maintenance counter: {self.__class__.maintenance_counter}")

                    if self.__class__.maintenance_counter % 3 != 0:
                        print("... throwing maintenance error")
                        self.send_response(500)
                        self.send_header('Content-Type', 'application/json; charset=utf-8') # UTF-8 명시
                        self.send_header('Retry-After', '120')
                        self.end_headers()
                        error_response = {
                            "error": True,
                            "reason": "Temporarily unavailable for maintenance"
                        }
                        self.wfile.write(json.dumps(error_response).encode('utf-8')) # UTF-8 인코딩
                        return
                    else:
                        print("... NOT throwing maintenance error")

                # 항상 유지보수 에러
                if username == 'maintenance!':
                    self.send_response(500)
                    self.send_header('Content-Type', 'application/json; charset=utf-8') # UTF-8 명시
                    self.send_header('Retry-After', '120')
                    self.end_headers()
                    error_response = {
                        "error": "Internal Server Error",
                        "reason": "Temporarily unavailable for maintenance"
                    }
                    self.wfile.write(json.dumps(error_response).encode('utf-8')) # UTF-8 인코딩
                    return

                # 잘못된 응답 형식 시뮬레이션
                if username == 'illegalresponse':
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json; charset=utf-8') # UTF-8 명시
                    self.end_headers()
                    result = {"isAvailable": False}
                    # 이 부분은 JSON이므로 이미 UTF-8로 인코딩됩니다.
                    self.wfile.write(json.dumps(result).encode('utf-8'))
                    return
                    
                # 사용자 이름이 비어있는지 확인
                if not username:
                    self.send_response(400)
                    # Content-Type 헤더 추가 및 인코딩 명시
                    self.send_header('Content-Type', 'text/plain; charset=utf-8')
                    self.end_headers()
                    # 문자열을 utf-8로 인코딩하여 전송
                    self.wfile.write('Bad Request: userName 이 비어있습니다.'.encode('utf-8'))
                    return

                # 사용자 이름이 3자 이상인지 확인
                if len(username) < 3:
                    self.send_response(400)
                    # Content-Type 헤더 추가 및 인코딩 명시
                    self.send_header('Content-Type', 'text/plain; charset=utf-8')
                    self.end_headers()
                    # 문자열을 utf-8로 인코딩하여 전송
                    self.wfile.write('Bad Request: userName은 최소 3자 이상이어야 합니다.'.encode('utf-8'))
                    return

                # 요청 로깅
                print(f"Checking availability for username: {username}")

                # 사용자 이름이 사용 불가능한 목록에 있는지 확인
                is_available = username not in unavailable_usernames

                # JSON 응답 생성
                response = {
                    "isAvailable": is_available,
                    "userName": username
                }

                # HTTP 응답 헤더 설정 (JSON 응답이므로 UTF-8 명시)
                self.send_response(200)
                self.send_header('Content-Type', 'application/json; charset=utf-8')
                self.end_headers()

                # JSON 응답 전송 (JSON은 기본적으로 UTF-8 사용)
                self.wfile.write(json.dumps(response).encode('utf-8'))
                return

        # 요청 경로가 일치하지 않는 경우 404 반환
        self.send_response(404)
        self.send_header('Content-Type', 'text/plain; charset=utf-8') # UTF-8 명시
        self.end_headers()
        self.wfile.write('Not Found'.encode('utf-8')) # ASCII 문자열이지만 일관성을 위해 인코딩

def run_server(port=8080):
    server_address = ('127.0.0.1', port)
    httpd = HTTPServer(server_address, UserNameHandler)
    print(f"Starting username availability server at http://127.0.0.1:{port}")
    print("Available endpoints:")
    print(f"  GET http://127.0.0.1:{port}/isUserNameAvailable?userName=<username>")
    print("\nUnavailable usernames for testing:")
    for name in unavailable_usernames:
        print(f"  - {name}")
    print("\n서버를 중지하려면 Ctrl+C를 누르세요.")

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n서버가 종료됩니다.")
        httpd.server_close()

if __name__ == '__main__':
    run_server()