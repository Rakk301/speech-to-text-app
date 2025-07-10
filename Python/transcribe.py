"""
Main transcription script for speech-to-text application.
Orchestrates Whisper STT → LLM processing pipeline.
"""

import argparse
import sys
import logging
from pathlib import Path
from typing import Optional

from whisper_wrapper import WhisperWrapper
from llm_processor import LLMProcessor
from config import Config


def setup_logging() -> None:
    """Setup logging configuration."""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )


def transcribe_audio(audio_path: str, config: Config) -> str:
    """
    Transcribe audio file using Whisper and post-process with LLM.
    
    Args:
        audio_path: Path to audio file
        config: Configuration object
        
    Returns:
        Processed transcription text
    """
    logger = logging.getLogger(__name__)
    
    try:
        # Initialize Whisper wrapper
        whisper = WhisperWrapper(config.whisper)
        
        # Transcribe audio
        raw_transcription = whisper.transcribe(audio_path)
        
        # Post-process with LLM
        llm = LLMProcessor(config.llm)
        logger.info("Post-processing with LLM")
        processed_text = llm.process(raw_transcription)
        logger.info(f"Processed text: {processed_text}")
        
        return processed_text
        
    except Exception as e:
        logger.error(f"Transcription failed: {e}")
        raise


def main():
    """Main entry point for transcription script."""
    parser = argparse.ArgumentParser(description="Transcribe audio file")
    parser.add_argument("audio_path", help="Path to audio file")
    parser.add_argument("--config", default="Config/settings.yaml", 
                       help="Path to configuration file")
    parser.add_argument("--verbose", "-v", action="store_true", 
                       help="Enable verbose logging")
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    setup_logging()
    logger = logging.getLogger(__name__)
    
    try:
        # Load configuration
        config = Config(args.config)
        logger.info("Configuration loaded successfully")
        
        # Validate audio file
        audio_path = Path(args.audio_path)
        if not audio_path.exists():
            logger.error(f"Audio file not found: {audio_path}")
            sys.exit(1)
        
        # Transcribe audio
        result = transcribe_audio(str(audio_path), config)
        
        # Output to stdout for Swift consumption
        print(result, end="")
        
    except Exception as e:
        logger.error(f"Transcription failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main() 