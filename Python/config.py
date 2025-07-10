"""
Configuration management for speech-to-text application.
Handles loading, validation, and access to application settings.
"""

import yaml
import logging
from pathlib import Path
from typing import Dict, Any, Optional


class Config:
    """Configuration manager for the speech-to-text application."""
    
    def __init__(self, config_path: str = "Config/settings.yaml"):
        """
        Initialize configuration manager.
        
        Args:
            config_path: Path to configuration file
        """
        self.logger = logging.getLogger(__name__)
        self.config_path = Path(config_path)
        self.config = self._load_config()
        self._validate_config()
    
    def _load_config(self) -> Dict[str, Any]:
        """Load configuration from YAML file."""
        try:
            if not self.config_path.exists():
                self.logger.warning(f"Config file not found: {self.config_path}")
                return None
            
            with open(self.config_path, 'r') as f:
                config = yaml.safe_load(f)
            
            self.logger.info(f"Configuration loaded from: {self.config_path}")
            return config
            
        except Exception as e:
            self.logger.error(f"Failed to load configuration: {e}")
            return None
        
