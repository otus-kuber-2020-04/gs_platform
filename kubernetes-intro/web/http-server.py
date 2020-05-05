#!/usr/bin/env python3
import http.server
import socketserver
import os
import sys
import logging

PORT = 8000
DIRECTORY = os.environ['SERVER_FOLDER']


def setupLogging(loglevel=logging.DEBUG):
    logger = logging.getLogger()
    logger.setLevel(loglevel)
    ch = logging.StreamHandler(sys.stdout)
    ch.setLevel(loglevel)
    formatter = logging.Formatter("%(message)s")
    ch.setFormatter(formatter)
    logger.addHandler(ch)
    return logger


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)


logger = setupLogging("DEBUG")
with socketserver.TCPServer(("", PORT), Handler) as httpd:
    logger.debug("serving at port " + str(PORT))
    httpd.serve_forever()
