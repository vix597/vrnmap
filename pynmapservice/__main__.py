"""Main module for pynmapservice."""
import os
import sys
import argparse

from .server import PyNmapServer
from .config import PyNmapServiceConfig
from .utils import is_user_admin, AdminStateUnknownError, setup_logging


def main():
    """Entry point."""
    parser = argparse.ArgumentParser("PyNmapService", description="A WebSocket controlled Nmap service.")
    parser.add_argument(
        "--bind-ip", help="IP to bind to.")
    parser.add_argument(
        "--bind-port", help="Port to bind to.")
    parser.add_argument(
        "--log-level", help="Log level for the logger", choices=["info", "warning", "critical", "debug", "error"])
    parser.add_argument(
        "-c", "--config-file", help="Path to the config file", default="pynmapservice.cfg.json")
    parser.add_argument(
        "-l", "--log-file", help="Path to a log file for the service", default="pynmapservice.log")
    args = parser.parse_args()

    if not os.path.exists(args.config_file):
        PyNmapServiceConfig.save(args.config_file)
    else:
        PyNmapServiceConfig.load(args.config_file)

    config = PyNmapServiceConfig.get()
    save_config = False
    if args.bind_ip:
        config.websocket.host = args.bind_ip
        save_config = True
    if args.bind_port:
        config.websocket.port = args.bind_port
        save_config = True
    if args.log_level:
        config.log_level = args.log_level
        save_config = True

    if save_config:
        PyNmapServiceConfig.save()

    # Setup logging
    setup_logging(args.log_file, config.log_level)

    # Start the server
    PyNmapServer.run()


if __name__ == "__main__":
    try:
        if not is_user_admin():
            sys.exit(1)
    except (SystemExit, AdminStateUnknownError):
        print("PyNmapService must be run as an administrator.")
        sys.exit(1)

    main()
