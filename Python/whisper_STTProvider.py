"""
Whisper wrapper for speech-to-text processing.
Handles audio preprocessing and Whisper model integration.
"""

import logging
import whisper
from typing import Dict, Any
from pathlib import Path
from base_STTProvider import BaseSTTProvider

class WhisperProvider(BaseSTTProvider):
    """Whisper STT provider."""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.model = None
        self.logger = logging.getLogger(__name__)
        self._load_model()
    
    def _load_model(self):
        """Load Whisper model."""
        try:
            model_name = self.config.get("model", "small")
            self.logger.info(f"Loading Whisper model: {model_name}")
            
            self.model = whisper.load_model(model_name)
            
            self.logger.info(f"Whisper model loaded successfully")
            
        except Exception as e:
            self.logger.error(f"Failed to load Whisper model: {e}")
            raise
        
    
    def transcribe(self, audio_path: str) -> str:
        """Transcribe with Whisper."""
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

    
    def is_available(self) -> bool:
        """Whisper is always available (local)."""
        return True if self.model else False