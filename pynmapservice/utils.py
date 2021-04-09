"""Helpful utility methods."""
import os
import sys
import ctypes
import logging
from typing import List, Dict, Tuple
from logging.handlers import RotatingFileHandler

import nmap
import coloredlogs


class AdminStateUnknownError(Exception):
    """Cannot determine whether the user is an admin."""


def is_user_admin() -> bool:
    """Return True if user has admin privileges.

    Raises:
        AdminStateUnknownError if user privileges cannot be determined.
    """
    try:
        return os.getuid() == 0  # type: ignore
    except AttributeError:  # pragma: no cover
        pass
    try:
        return ctypes.windll.shell32.IsUserAnAdmin() == 1
    except AttributeError as ex:
        raise AdminStateUnknownError from ex


def get_ifaces() -> List[Dict]:
    """Get network interface list."""
    if sys.platform == "win32":
        from scapy.all import get_windows_if_list
        return get_windows_if_list()

    from scapy.all import get_if_list
    return get_if_list()


def setup_logging(path: str, level: str):
    """
    Set up a rotating file logger that also logs to stdout.

    :param path: Path to the log file
    :param level: The log level
    """
    level = level.upper()

    # Setup root logger
    fmt = "%(asctime)s [%(levelname)s][%(name)s] %(message)s"
    formatter = logging.Formatter(fmt)
    root = logging.getLogger()
    root.setLevel(level)

    # Setup rotating file logger
    file_handler = RotatingFileHandler(path, maxBytes=1024**2, backupCount=10)  # Max: 10, 1MB files
    file_handler.setFormatter(formatter)
    root.addHandler(file_handler)

    # Colorize stdout logs
    coloredlogs.install(level=level, fmt=fmt)


async def discover_hosts(cidr: str) -> List[Tuple[str, str]]:
    """Use nmap to do a ping sweep on the provided CIDR range."""
    nm = nmap.PortScanner()
    nm.scan(hosts=cidr, arguments='-n -sn')
    return [(x, nm[x]['status']['state']) for x in nm.all_hosts()]
