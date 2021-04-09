"""The pynmapservice Server."""
import json
import time
import asyncio
import logging

import websockets

from .config import PyNmapServiceConfig
from .utils import get_ifaces, discover_hosts

LOGGER = logging.getLogger(__name__)


class PyNmapServerSingleton:
    """Server singleton that creates the websocket."""

    _instance = None
    _queue: asyncio.Queue = asyncio.Queue()

    def __new__(cls):
        """Create or get an instance of the singleton object."""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.setup()
        return cls._instance

    def setup(self):
        """Set up the class instance variables."""
        self._config = PyNmapServiceConfig.get()
        self._server = None

    def send_message(self, contents, mtype: str):
        """
        Create a message to send to the client with the appropriate type set.

        :param contents: The contents of the message
        :param mtype: The message type
        """
        msg = {"contents": contents, "type": mtype}
        self._queue.put_nowait(json.dumps(msg))

    def _parse_message(self, message: bytes) -> dict:
        """
        Parse a message from the client.

        :param message: The raw byte data from the client
        :returns: A dict with type and contents keys
        """
        try:
            return json.loads(message.decode())
        except json.JSONDecodeError as exc:
            return {
                "type": "error",
                "contents": f"Invalid JSON: {exc}"
            }

    async def producer(self):
        """Grab a message that needs to be sent to the client."""
        return await self._queue.get()

    async def consumer(self, message):
        """Consume a message from the client."""
        LOGGER.debug(f"Message received: {message}")
        obj = self._parse_message(message)
        mtype = obj.get("type")
        contents = obj.get("contents")

        if mtype == "error":
            LOGGER.error(contents)
        elif mtype == "discover":
            LOGGER.info(f"Discover hosts in CIDR: {contents}")
            for host in await discover_hosts(contents):
                self.send_message(host, "discover")
        else:
            LOGGER.warning(f"Unknown message type {mtype}")

    async def producer_handler(self, websocket, path):
        """Produce events for the client."""
        while True:
            message = await self.producer()
            await websocket.send(message)  # Raises connection closed and breaks from loop

    async def consumer_handler(self, websocket, path):
        """Consume messages from the client."""
        async for message in websocket:
            await self.consumer(message)  # Terminates when the client disconnects

    async def handler(self, websocket, path):
        """Handle client connections."""
        LOGGER.debug(f"Client connected\n\tWebSocket: {websocket}\n\tPath: {path}")

        # Send the initial message containing the hosts network info
        self.send_message(get_ifaces(), "ifaces")

        consumer_task = asyncio.ensure_future(self.consumer_handler(websocket, path))
        producer_task = asyncio.ensure_future(self.producer_handler(websocket, path))
        _done, pending = await asyncio.wait(
            [consumer_task, producer_task],
            return_when=asyncio.FIRST_COMPLETED,
        )

        # Done, cancel any pending tasks
        for task in pending:
            task.cancel()

    def run(self):
        """Run the server."""
        self._server = websockets.serve(
            self.handler,
            self._config.websocket.host,
            self._config.websocket.port
        )

        # Start listening
        asyncio.get_event_loop().run_until_complete(self._server)
        LOGGER.info(f"Server listening on {self._config.websocket.host}:{self._config.websocket.port}")
        asyncio.get_event_loop().run_forever()


PyNmapServer = PyNmapServerSingleton()
