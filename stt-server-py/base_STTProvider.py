"""
Model factory for different STT providers.
Enables easy swapping between Whisper, Ollama, etc.
"""

import logging
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
import requests
from pathlib import Path


class BaseSTTProvider(ABC):
    """Abstract base class for STT providers."""
    
    @abstractmethod
    def transcribe(self, audio_path: str) -> str:
        """Transcribe audio file."""
        pass
    
    @abstractmethod
    def is_available(self) -> bool:
        """Check if provider is available."""
        pass