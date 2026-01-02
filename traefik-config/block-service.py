#!/usr/bin/env python3
"""
Service HTTP minimal qui retourne toujours 403 Forbidden
Utilisé par Traefik pour bloquer l'accès aux API non autorisées depuis le WAN
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import sys

class BlockHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(403)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(b'{"error": "Forbidden", "message": "This API endpoint is not accessible from WAN"}')
    
    def do_POST(self):
        self.do_GET()
    
    def do_PUT(self):
        self.do_GET()
    
    def do_DELETE(self):
        self.do_GET()
    
    def log_message(self, format, *args):
        # Désactiver les logs pour réduire le bruit
        pass

def run(port=8082):
    server_address = ('127.0.0.1', port)
    httpd = HTTPServer(server_address, BlockHandler)
    print(f"Block service démarré sur port {port}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nArrêt du service de blocage...")
        httpd.shutdown()

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8082
    run(port)

