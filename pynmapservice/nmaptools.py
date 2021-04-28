"""Contains several python-nmap helpers."""
import logging
import threading
from typing import List

import nmap

LOGGER = logging.getLogger(__name__)


class NmapThreadPoolSingleton:
    """Run the nmap command in their own thread."""

    _threads: List[threading.Thread] = []
    _lock = threading.Lock()
    _instance = None
    _exit = False

    def __new__(cls):
        """Create or get an instance of the singleton object."""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __del__(self):
        """Set exit so the threads can quit early."""
        self._exit = True

    def _run_cmd(self, server, hosts: str, arguments: str, action: str):
        """Run the nmap command in a worker thread."""
        with self._lock:
            thread = threading.Thread(target=self._do_work, args=[server, hosts, arguments, action])
            self._threads.append(thread)
        thread.start()

    def _do_work(self, server, hosts: str, arguments: str, action: str):
        """Do the work in a thread."""
        nm = nmap.PortScannerYield()
        for host, result in nm.scan(hosts=hosts, arguments=arguments):
            LOGGER.debug(f"Scan result for {host}: {result}")
            server.send_message({"host": host, "scan_result": result}, action)

            if self._exit:
                LOGGER.warning("exiting early from nmap scan thread.")
                break

        with self._lock:
            self._threads.remove(threading.current_thread())

        LOGGER.info(f"Completed {action} action.")

    def discover_hosts(self, server, cidr: str):
        """Use nmap to do a ping sweep on the provided CIDR range."""
        LOGGER.info(f"Discover hosts in CIDR {cidr}")
        self._run_cmd(server, cidr, "-n -sn", "discover")


NmapThreadPool = NmapThreadPoolSingleton()
