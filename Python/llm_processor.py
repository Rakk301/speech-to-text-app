"""
LLM processor for post-processing transcriptions.
Uses Ollama for local LLM processing and text cleanup.
"""

import logging
import requests
import json
from typing import Dict, Any, Optional


class LLMProcessor:
    """Processor for LLM-based text post-processing."""
    
    def __init__(self, config: Dict[str, Any]):
        """
        Initialize LLM processor.
        
        Args:
            config: LLM configuration dictionary
        """
        self.logger = logging.getLogger(__name__)
        self.config = config
        self.base_url = "http://localhost:11434"  # Ollama default
        self.model = config.get("model", "llama2")
        self.temperature = config.get("temperature", 0.1)
        self.max_tokens = config.get("max_tokens", 100)
        
        # Default prompt for text cleanup
        self.default_prompt = """
        Please clean up and improve the following transcription. 
        Fix grammar, punctuation, and formatting while preserving the original meaning.
        Make it more readable and professional.
        
        Transcription: {text}
        
        Improved text:"""
    
    def _check_ollama_connection(self) -> bool:
        """Check if Ollama is running and accessible."""
        try:
            response = requests.get(f"{self.base_url}/api/tags", timeout=5)
            return response.status_code == 200
        except Exception as e:
            self.logger.warning(f"Ollama connection failed: {e}")
            return False
    
    def _generate_prompt(self, text: str) -> str:
        """Generate prompt for LLM processing."""
        # Use custom prompt from config if available
        custom_prompt = self.config.get("prompt", self.default_prompt)
        return custom_prompt.format(text=text)
    
    def process(self, text: str) -> str:
        """
        Process text using LLM for cleanup and improvement.
        
        Args:
            text: Raw transcription text
            
        Returns:
            Processed and improved text
        """
        try:
            # Check if LLM processing is enabled
            if not self.config.get("enabled", True):
                self.logger.info("LLM processing disabled, returning original text")
                return text
            
            # Check Ollama connection
            if not self._check_ollama_connection():
                self.logger.warning("Ollama not available, returning original text")
                return text
            
            # Generate prompt
            prompt = self._generate_prompt(text)
            
            # Call Ollama API
            self.logger.info(f"Processing text with LLM model: {self.model}")
            
            payload = {
                "model": self.model,
                "prompt": prompt,
                "stream": False,
                "options": {
                    "temperature": self.temperature,
                    "num_predict": self.max_tokens
                }
            }
            
            response = requests.post(
                f"{self.base_url}/api/generate",
                json=payload,
                timeout=30
            )
            
            if response.status_code != 200:
                raise Exception(f"Ollama API error: {response.status_code}")
            
            result = response.json()
            processed_text = result.get("response", "").strip()
            
            if not processed_text:
                self.logger.warning("LLM returned empty response, using original text")
                return text
            
            self.logger.info(f"LLM processing completed: {len(processed_text)} characters")
            return processed_text
            
        except Exception as e:
            self.logger.error(f"LLM processing failed: {e}")
            # Return original text on failure
            return text
    
    def get_model_info(self) -> Dict[str, Any]:
        """Get information about available LLM models."""
        try:
            response = requests.get(f"{self.base_url}/api/tags", timeout=5)
            if response.status_code == 200:
                models = response.json().get("models", [])
                return {
                    "available_models": [model["name"] for model in models],
                    "current_model": self.model,
                    "connection": "available"
                }
            else:
                return {"connection": "error", "status_code": response.status_code}
        except Exception as e:
            return {"connection": "unavailable", "error": str(e)} 