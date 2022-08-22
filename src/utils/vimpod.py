#!/usr/bin/python3
from http.server import (HTTPServer, BaseHTTPRequestHandler)
from os import getenv
import sys

logfile = open('logfile.log', 'w')
sys.stdout = logfile
sys.stdin = logfile
sys.stderr = logfile


WS_ID = getenv('GITPOD_WORKSPACE_ID')
CLUSTER_HOST = getenv('GITPOD_WORKSPACE_CLUSTER_HOST')


class handler(BaseHTTPRequestHandler):
    def do_GET(self):
        logfile.flush()
        if "supervisor" in self.path or "version" in self.path:
            self.send_response(200)
            # self.send_header('Content-type', 'text/html')
            # self.end_headers()
        else:
            self.send_response(301)
            print(self.path)
            new_path = "ssh://" + WS_ID + "@" + WS_ID + ".ssh." + CLUSTER_HOST
            self.send_header('Location', new_path)
            self.end_headers()


with HTTPServer(('0.0.0.0', 25000), handler) as server:
    server.serve_forever()
