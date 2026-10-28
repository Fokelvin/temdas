"""Serve a local Flutter release directory with the production SPA fallback."""
import functools
import http.server
import os
import sys


class SPA(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        path = self.translate_path(self.path)
        if not os.path.isfile(path) and not os.path.isdir(path):
            self.path = '/index.html'
        return super().do_GET()

    def log_message(self, *args):
        # Request URLs can contain credentials, even in this fixture server.
        pass


if __name__ == '__main__':
    handler = functools.partial(SPA, directory=sys.argv[1])
    http.server.ThreadingHTTPServer(('127.0.0.1', 38431), handler).serve_forever()
