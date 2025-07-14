#!/usr/bin/env python3
"""
Simple test script for PythonBridge communication.
Reads config and outputs basic information to verify the bridge works.
"""

import argparse
import sys
import json
from pathlib import Path

try:
    from config import Config
    CONFIG_AVAILABLE = True
except ImportError:
    CONFIG_AVAILABLE = False


def test_config_loading(config_path: str) -> dict:
    """Test loading the configuration file."""
    result = {
        "success": False,
        "config_loaded": False,
        "config_data": None,
        "error": None
    }
    
    try:
        if CONFIG_AVAILABLE:
            config = Config(config_path)
            result["config_loaded"] = True
            result["config_data"] = config.config
            result["success"] = True
        else:
            # Fallback: read config file directly
            config_file = Path(config_path)
            if config_file.exists():
                import yaml
                with open(config_file, 'r') as f:
                    result["config_data"] = yaml.safe_load(f)
                result["config_loaded"] = True
                result["success"] = True
            else:
                result["error"] = f"Config file not found: {config_path}"
    except Exception as e:
        result["error"] = str(e)
    
    return result


def test_file_access(file_path: str) -> dict:
    """Test if we can access a file."""
    result = {
        "success": False,
        "file_exists": False,
        "file_size": 0,
        "error": None
    }
    
    try:
        file_path_obj = Path(file_path)
        result["file_exists"] = file_path_obj.exists()
        if result["file_exists"]:
            result["file_size"] = file_path_obj.stat().st_size
            result["success"] = True
        else:
            result["error"] = f"File not found: {file_path}"
    except Exception as e:
        result["error"] = str(e)
    
    return result


def main():
    """Main entry point for test script."""
    parser = argparse.ArgumentParser(description="Test PythonBridge communication")
    parser.add_argument("test_file", help="Path to a test file (e.g., audio file)")
    parser.add_argument("--config", default="Config/settings.yaml", 
                       help="Path to configuration file")
    
    args = parser.parse_args()
    
    # Test results
    results = {
        "python_version": sys.version,
        "working_directory": str(Path.cwd()),
        "config_test": test_config_loading(args.config),
        "file_test": test_file_access(args.test_file),
        "dependencies": {
            "config_module": CONFIG_AVAILABLE,
            "yaml_available": False,
            "numpy_available": False,
            "whisper_available": False
        }
    }
    
    # Test additional dependencies
    try:
        import yaml
        results["dependencies"]["yaml_available"] = True
    except ImportError:
        pass
    
    try:
        import numpy
        results["dependencies"]["numpy_available"] = True
    except ImportError:
        pass
    
    try:
        import whisper
        results["dependencies"]["whisper_available"] = True
    except ImportError:
        pass
    
    # Output results as JSON for Swift consumption
    print(json.dumps(results, indent=2), end="")


if __name__ == "__main__":
    main() 