"""
Whisper wrapper for speech-to-text processing.
Handles audio preprocessing and Whisper model integration.
"""

import logging
import whisper
from typing import Dict, Any
from pathlib import Path


class WhisperWrapper:
    """Wrapper for Whisper speech-to-text model."""
    
    def __init__(self, config: Dict[str, Any]):
        """
        Initialize Whisper wrapper.
        
        Args:
            config: Whisper configuration dictionary
        """
        self.logger = logging.getLogger(__name__)
        self.config = config
        self.model = None
        self._load_model()
    
    def _load_model(self) -> None:
        """Load Whisper model based on configuration."""
        try:
            model_name = self.config.get("model", "base")
            self.logger.info(f"Loading Whisper model: {model_name}")
            
            self.model = whisper.load_model(model_name)
            
            self.logger.info(f"Whisper model loaded successfully")
            
        except Exception as e:
            self.logger.error(f"Failed to load Whisper model: {e}")
            raise
    
    def transcribe(self, audio_path: str) -> str:
        """
        Transcribe audio file using Whisper.
        
        Args:
            audio_path: Path to audio file
            
        Returns:
            Transcribed text
        """
        try:
            self.logger.info(f"Transcribing audio: {audio_path}")
            
            # Validate audio file
            if not Path(audio_path).exists():
                raise FileNotFoundError(f"Audio file not found: {audio_path}")
            
            # Transcribe with Whisper
            result = self.model.transcribe(
                audio_path,
                language=self.config.get("language", "en"),
                task=self.config.get("task", "transcribe"),
                temperature=self.config.get("temperature", 0.0),
                fp16=False  # Disable for better compatibility
            )
            transcription = result["text"].strip()
            self.logger.info(f"Transcription: {transcription}")
            self.logger.info(f"Transcription completed: {len(transcription)} characters")
            
            return transcription
            
        except Exception as e:
            self.logger.error(f"Transcription failed: {e}")
            raise
