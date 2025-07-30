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
    
    def _load_config(self) -> Dict[str, Any]:
        """Load configuration from YAML file."""
        if not self.config_path.exists():
            raise FileNotFoundError(f"Config file not found: {self.config_path}")
        
        try:
            with open(self.config_path, 'r') as f:
                config = yaml.safe_load(f)
            
            self.logger.info(f"Configuration loaded from: {self.config_path}")
            return config
            
        except Exception as e:
            raise Exception(f"Failed to load configuration: {e}")
    
    @property
    def whisper(self) -> Dict[str, Any]:
        """Get Whisper configuration."""
        return self.config.get("whisper", {})
    
    @property
    def llm(self) -> Dict[str, Any]:
        """Get LLM configuration."""
        return self.config.get("llm", {})
    
    @property
    def audio(self) -> Dict[str, Any]:
        """Get audio configuration."""
        return self.config.get("audio", {})
    
    @property
    def stt(self) -> Dict[str, Any]:
        """Get STT configuration."""
        return self.config.get("stt", {})
        
