#!/usr/bin/python3
from http.server import (HTTPServer, BaseHTTPRequestHandler)
from os import getenv

WS_ID = getenv('GITPOD_WORKSPACE_ID')
CLUSTER_HOST = getenv('GITPOD_WORKSPACE_CLUSTER_HOST')


class handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(301)
        new_path = "ssh://" + WS_ID + "@" + WS_ID + ".ssh." + CLUSTER_HOST
        self.send_header('Location', new_path)
        self.end_headers()


with HTTPServer(('0.0.0.0', 22000), handler) as server:
    server.serve_forever()
