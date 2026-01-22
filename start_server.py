#!/usr/bin/env python3
import http.server
import socketserver
import os
import mimetypes
from pathlib import Path

PORT = 9999
WEB_DIR = Path("build/web").resolve()

# Add MIME types for Flutter Web
mimetypes.add_type('application/wasm', '.wasm')
mimetypes.add_type('application/dart', '.dart')

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WEB_DIR), **kwargs)

    def end_headers(self):
        # Add CORS headers to allow loading from any origin
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        super().end_headers()

    def log_message(self, format, *args):
        # Suppress verbose logging
        pass

print(f"Starting server on http://localhost:{PORT}")
print(f"Serving files from: {WEB_DIR}")

with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
    httpd.serve_forever()
