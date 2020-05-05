#!/usr/bin/env python3
import http.server
import socketserver
import os

PORT = 8000
DIRECTORY = os.environ['SERVER_FOLDER']
print(DIRECTORY)


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)


with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print("serving at port", PORT)
    httpd.serve_forever()
