"""Handles service configuration."""
from typing import Optional

from cincoconfig import Schema, Config, ApplicationModeField, PortField, HostnameField, IntField, LogLevelField


class ConfigPathNotSet(Exception):
    """Thrown if the config path hasn't been set on call to save/load."""


class PyNmapServiceConfigSingleton:
    """Uses cincoconfig to create/parse/validate the config file."""

    _instance = None

    def __new__(cls):
        """Create or get an instance of the singleton object."""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.setup()
        return cls._instance

    def setup(self):
        """Set up the config schema."""
        self._path = None
        self._schema = Schema()
        self._schema.version = IntField(default=1, required=True)
        self._schema.mode = ApplicationModeField(default="production", required=True)
        self._schema.log_level = LogLevelField(default="info", required=True)
        self._schema.websocket.host = HostnameField(default="127.0.0.1", allow_ipv4=True, required=True)
        self._schema.websocket.port = PortField(default=42069, required=True)
        self._config = self._schema()  # Compile the schema

    def get(self) -> Config:
        """
        Get the config.

        :returns: The :class:`cincoconfig.Config` object
        """
        return self._config

    def save(self, path: Optional[str] = None):
        """
        Save the config to disk at the path provided.

        :param path: Path to save the config file to
        :raises ConfigPathNotSet: If the config path hasn't been set by this
            method or a call to load()
        """
        self._path = path or self._path
        if not self._path:
            raise ConfigPathNotSet("Config path not set.")
        self._config.save(self._path, format="json")

    def load(self, path: Optional[str] = None):
        """
        Load the config from the provided path on disk.

        :param path: The path on disk to the JSON formatted config file.
        :raises ConfigPathNotSet: If the config path hasn't been set by this
            method or a call to save().
        """
        self._path = path or self._path
        if not self._path:
            raise ConfigPathNotSet("Config path not set.")
        self._config.load(self._path, format="json")


PyNmapServiceConfig = PyNmapServiceConfigSingleton()
