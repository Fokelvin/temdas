"""Loopback-only PostgreSQL response-delay proxy for disposable benchmarks.

Delays ReadyForQuery, once per completed protocol exchange. This is controlled
application-level delay, not a measurement/emulation of the production WAN.
"""
import asyncio
import json
import struct
import threading
from urllib.parse import urlparse, parse_qs


class PgLatencyProxy:
    def __init__(self, target_port):
        self.target_port = int(target_port)
        self.delay_ms = 0
        self.ready_responses = 0
        self._started = threading.Event()
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._error = None

    def __enter__(self):
        self._thread.start()
        if not self._started.wait(10):
            raise RuntimeError('Local latency proxy did not start')
        if self._error:
            raise RuntimeError('Local latency proxy failed') from self._error
        return self

    def __exit__(self, *args):
        self._loop.call_soon_threadsafe(self._stop.set)
        self._thread.join(10)
        if self._thread.is_alive():
            raise RuntimeError('Local latency proxy did not stop')

    def _run(self):
        try:
            asyncio.run(self._main())
        except Exception as error:
            self._error = error
            self._started.set()

    async def _main(self):
        self._loop = asyncio.get_running_loop()
        self._stop = asyncio.Event()
        self._writers = set()
        db = await asyncio.start_server(self._connection, '127.0.0.1', 0)
        control = await asyncio.start_server(self._control, '127.0.0.1', 0)
        self.port = db.sockets[0].getsockname()[1]
        self.control_port = control.sockets[0].getsockname()[1]
        self._started.set()
        async with db, control:
            await self._stop.wait()
        for writer in tuple(self._writers):
            writer.close()

    async def _connection(self, client_reader, client_writer):
        upstream_writer = None
        tasks = []
        try:
            upstream_reader, upstream_writer = await asyncio.open_connection(
                '127.0.0.1', self.target_port)
            self._writers.update((client_writer, upstream_writer))

            async def send():
                while data := await client_reader.read(65536):
                    upstream_writer.write(data)
                    await upstream_writer.drain()

            async def receive():
                while True:
                    header = await upstream_reader.readexactly(5)
                    length = struct.unpack('!I', header[1:])[0]
                    if not 4 <= length <= 64 * 1024 * 1024:
                        raise RuntimeError('Invalid PostgreSQL message length')
                    body = await upstream_reader.readexactly(length - 4)
                    if header[:1] == b'Z':
                        self.ready_responses += 1
                        await asyncio.sleep(self.delay_ms / 1000)
                    client_writer.write(header + body)
                    await client_writer.drain()

            tasks = [asyncio.create_task(send()), asyncio.create_task(receive())]
            await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
        except (OSError, asyncio.IncompleteReadError, ConnectionError):
            pass
        finally:
            for task in tasks:
                task.cancel()
            if tasks:
                await asyncio.gather(*tasks, return_exceptions=True)
            for writer in (client_writer, upstream_writer):
                if writer:
                    self._writers.discard(writer)
                    writer.close()

    async def _control(self, reader, writer):
        try:
            line = (await reader.readline()).decode('ascii')
            path = urlparse(line.split()[1])
            args = parse_qs(path.query)
            if path.path == '/delay':
                delay = int(args.get('ms', ['0'])[0])
                if not 0 <= delay <= 2000:
                    raise ValueError('Delay out of range')
                self.delay_ms = delay
                self.ready_responses = 0
            data = json.dumps({'delay_ms': self.delay_ms,
                               'ready_responses': self.ready_responses}).encode()
            writer.write(b'HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: application/json\r\nContent-Length: ' +
                         str(len(data)).encode() + b'\r\n\r\n' + data)
            await writer.drain()
        finally:
            writer.close()
