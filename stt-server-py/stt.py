from typing import Dict, Any
from base_STTProvider import BaseSTTProvider
from whisper_STTProvider import WhisperProvider


class STT:
    """Factory for creating STT providers."""
    
    @staticmethod
    def create_provider(provider_type: str, config: Dict[str, Any]) -> BaseSTTProvider:
        """Create STT provider based on type."""
        if provider_type == "whisper":
            return WhisperProvider(config)
        else:
            raise ValueError(f"Unknown STT provider: {provider_type}")
