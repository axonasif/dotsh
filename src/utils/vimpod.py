#!/usr/bin/python3
from http.server import (HTTPServer, BaseHTTPRequestHandler)
from os import getenv
from sys import stdout, stderr

logfile = open('/tmp/.vimpod.log', 'w')
stdout = logfile
stderr = logfile

WS_ID = getenv('GITPOD_WORKSPACE_ID')
CLUSTER_HOST = getenv('GITPOD_WORKSPACE_CLUSTER_HOST')


class handler(BaseHTTPRequestHandler):
    def do_GET(self):
        logfile.flush()
        if "version" in self.path:
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            message = "663d7021754843f9f3532c556963e31d04fa5231"
            self.wfile.write(bytes(message, "utf8"))
        else:
            self.send_response(301)
            print(self.path)
            new_path = "ssh://" + WS_ID + "@" + WS_ID + ".ssh." + CLUSTER_HOST
            self.send_header('Location', new_path)
            self.end_headers()


with HTTPServer(('0.0.0.0', 29000), handler) as server:
    server.serve_forever()
