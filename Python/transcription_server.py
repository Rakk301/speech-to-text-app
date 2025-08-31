"""
Multi-model transcription server with hot-swappable STT providers.
"""

import asyncio
import logging
from pathlib import Path
from aiohttp import web
from typing import Dict, Any

from stt import STT
from llm_processor import LLMProcessor
from config import Config
from whisper_STTProvider import WhisperProvider


class MultiModelTranscriptionServer:
    def __init__(self, config_path: str):
        self.config = Config(config_path)
        self.stt_provider = None
        self.llm = None
        self.logger = logging.getLogger(__name__)
        
    async def initialize_models(self):
        """Load models once at startup."""
        # Get STT configuration
        stt_config = self.config.config.get("stt", {})
        primary_provider = stt_config.get("provider", "whisper")
        
        # Get provider-specific config
        if primary_provider == "whisper":
            provider_config = self.config.whisper
        else:
            provider_config = {}
        
        # Create STT provider with fallback
        self.logger.info(f"Initializing STT provider: {primary_provider}")
        self.stt_provider = STT.create_provider(primary_provider, provider_config)
        
        # Initialize LLM if enabled
        if self.config.llm.get("enabled", True):
            self.logger.info("Loading LLM processor...")
            self.llm = LLMProcessor(self.config.llm)
        
        self.logger.info("All models loaded successfully")
    
    async def transcribe_handler(self, request):
        """Handle transcription requests."""
        try:
            data = await request.json()
            audio_path = data.get('audio_path')
            provider_override = data.get('provider')  # Allow runtime provider switching # TODO: Think about this feature more
            
            if not audio_path or not Path(audio_path).exists():
                return web.json_response(
                    {'error': 'Invalid audio path'}, 
                    status=400
                )
            
            # Use override provider if specified
            if provider_override and provider_override != self._get_current_provider():
                self.logger.info(f"Switching to provider: {provider_override}")
                provider_config = self._get_provider_config(provider_override)
                self.stt_provider = STT.create_provider(provider_override, provider_config)
            
            # Transcribe with current provider
            transcription = self.stt_provider.transcribe(audio_path)
            
            # Optional LLM processing
            if self.llm and self.config.llm.get("enabled", True):
                transcription = self.llm.process(transcription)
            
            return web.json_response({
                'transcription': transcription,
                'provider': self._get_current_provider()
            })
            
        except Exception as e:
            self.logger.error(f"Transcription failed: {e}")
            return web.json_response(
                {'error': str(e)}, 
                status=500
            )
    
    def _get_current_provider(self) -> str:
        """Get current provider type."""
        if isinstance(self.stt_provider, WhisperProvider):
            return "whisper"
        return "unknown"
    
    def _get_provider_config(self, provider: str) -> Dict[str, Any]:
        """Get configuration for specific provider."""
        if provider == "whisper":
            return self.config.whisper
        return {}
    
    async def providers_handler(self, request):
        """List available providers and their status."""
        providers = {
            "whisper": {
                "available": True,  # Always available (local)
                "description": "Local Whisper model"
            },
        }
        
        return web.json_response({
            'providers': providers,
            'current': self._get_current_provider()
        })
    
    async def switch_provider_handler(self, request):
        """Switch STT provider at runtime."""
        try:
            data = await request.json()
            new_provider = data.get('provider')
            
            if not new_provider:
                return web.json_response(
                    {'error': 'Provider not specified'}, 
                    status=400
                )
            
            provider_config = self._get_provider_config(new_provider)
            self.stt_provider = STT.create_provider(new_provider, provider_config)
            
            return web.json_response({
                'message': f'Switched to {new_provider}',
                'provider': new_provider
            })
            
        except Exception as e:
            return web.json_response(
                {'error': str(e)}, 
                status=500
            )
        
    async def reload_model_handler(self, request):
        """Reload Whisper model with new configuration without server restart."""
        try:
            data = await request.json()
            
            # Get new Whisper configuration
            new_config = {
                "model": data.get("model", self.config.whisper.get("model", "small")),
                "language": data.get("language", self.config.whisper.get("language", "en")),
                "task": data.get("task", self.config.whisper.get("task", "transcribe")),
                "temperature": data.get("temperature", self.config.whisper.get("temperature", 0.0))
            }
            
            self.logger.info(f"Reloading Whisper model with new config: {new_config}")
            
            # Update the config in memory
            self.config.whisper.update(new_config)
            
            # Reload the Whisper provider with new configuration
            if isinstance(self.stt_provider, WhisperProvider):
                # Create new WhisperProvider with updated config
                self.stt_provider = WhisperProvider(new_config)
                self.logger.info("Whisper model reloaded successfully")
            else:
                # If current provider is not Whisper, switch to it
                self.stt_provider = WhisperProvider(new_config)
                self.logger.info("Switched to Whisper provider with new configuration")
            
            return web.json_response({
                'message': 'Model reloaded successfully',
                'config': new_config,
                'provider': 'whisper'
            })
            
        except Exception as e:
            self.logger.error(f"Failed to reload model: {e}")
            return web.json_response(
                {'error': str(e)}, 
                status=500
            )


async def create_app(config_path: str) -> web.Application:
    server = MultiModelTranscriptionServer(config_path)
    await server.initialize_models()
    
    app = web.Application()
    app.router.add_post('/transcribe', server.transcribe_handler)
    app.router.add_get('/providers', server.providers_handler)
    app.router.add_post('/switch_provider', server.switch_provider_handler)
    app.router.add_post('/reload_model', server.reload_model_handler)
    app.router.add_get('/health', lambda r: web.json_response({'status': 'healthy'}))
    
    return app


async def main():
    """Main entry point for the server."""
    import argparse
    
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='Transcription Server')
    parser.add_argument('config_path', nargs='?', default='../Config/settings.yaml',
                       help='Path to configuration file')
    parser.add_argument('--host', default='localhost', help='Host to bind to')
    parser.add_argument('--port', type=int, default=3001, help='Port to bind to (0 chooses a free port)')
    
    args = parser.parse_args()
    
    # Setup logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Create and start server
    app = await create_app(args.config_path)
    runner = web.AppRunner(app)
    await runner.setup()
    
    site = web.TCPSite(runner, args.host, args.port)
    await site.start()
    
    # Resolve the actual port (useful when 0 was passed)
    # Note: aiohttp's TCPSite does not directly expose the chosen port; keep the CLI port for log parity
    print(f"🚀 Transcription server started on http://{args.host}:{args.port}")
    print("📋 Available endpoints:")
    print("  POST /transcribe - Transcribe audio file")
    print("  GET  /providers  - List available providers")
    print("  POST /switch_provider - Switch STT provider")
    print("  POST /reload_model - Reload Whisper model")
    print("  GET  /health     - Health check")
    print("\n💡 Test with Postman:")
    print("  POST http://localhost:8080/transcribe")
    print("  Body: {\"audio_path\": \"/path/to/audio.wav\"}")
    
    # Keep server running
    try:
        await asyncio.Future()  # run forever
    except KeyboardInterrupt:
        print("\n🛑 Shutting down server...")
        await runner.cleanup()


if __name__ == "__main__":
    asyncio.run(main())
