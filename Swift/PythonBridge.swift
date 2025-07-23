import Foundation

enum PythonBridgeError: Error, LocalizedError {
    case processFailed
    case invalidOutput
    case scriptNotFound
    case executionTimeout
    case pythonNotFound
    
    var errorDescription: String? {
        switch self {
        case .processFailed:
            return "Python script execution failed"
        case .invalidOutput:
            return "Invalid output from Python script"
        case .scriptNotFound:
            return "Python script not found in app bundle"
        case .executionTimeout:
            return "Python script execution timed out"
        case .pythonNotFound:
            return "uv not found in app bundle"
        }
    }
}

class PythonBridge {
    
    // MARK: - Properties
    private let pythonScriptPath: String
    private let uvPath: String
    private let timeoutInterval: TimeInterval = 60.0 // Increased timeout for ML processing
    
    // MARK: - Initialization
    init() {
        // Get the app bundle path
        guard let bundlePath = Bundle.main.bundlePath else {
            fatalError("Could not get app bundle path")
        }
        
        // Always use bundled Python environment
        let appBundle = bundlePath
        pythonScriptPath = appBundle + "/Contents/Resources/Python/transcribe.py"
        // Use system uv to run Python scripts with dependencies
        uvPath = "/opt/homebrew/bin/uv"
    }
    
    // MARK: - Public Methods
    func transcribeAudio(_ audioFileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        // Check if Python script exists
        guard FileManager.default.fileExists(atPath: pythonScriptPath) else {
            completion(.failure(PythonBridgeError.scriptNotFound))
            return
        }
        
        // Check if uv exists
        guard FileManager.default.fileExists(atPath: uvPath) else {
            completion(.failure(PythonBridgeError.pythonNotFound))
            return
        }
        
        // Create process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: uvPath)
        
        // Get the app bundle path for resources
        guard let bundlePath = Bundle.main.bundlePath else {
            completion(.failure(PythonBridgeError.scriptNotFound))
            return
        }
        let appBundle = bundlePath
        
        // Set up uv command to run the Python script
        process.arguments = [
            "run", 
            "transcribe.py", 
            audioFileURL.path,
            "--config", "../Config/settings.yaml"
        ]
        
        // Set working directory to Python directory for uv to find pyproject.toml
        process.currentDirectoryURL = URL(fileURLWithPath: appBundle + "/Contents/Resources/Python")
        
        // Set up pipes for communication
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Set up output handling
        let outputData = NSMutableData()
        let errorData = NSMutableData()
        
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.count > 0 {
                outputData.append(data)
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.count > 0 {
                errorData.append(data)
            }
        }
        
        // Set up completion handling
        process.terminationHandler = { process in
            // Clean up file handles
            outputPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
            
            // Check termination status
            if process.terminationStatus == 0 {
                // Success - extract transcribed text
                if let outputString = String(data: outputData as Data, encoding: .utf8) {
                    let trimmedOutput = outputString.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedOutput.isEmpty {
                        completion(.success(trimmedOutput))
                    } else {
                        completion(.failure(PythonBridgeError.invalidOutput))
                    }
                } else {
                    completion(.failure(PythonBridgeError.invalidOutput))
                }
            } else {
                // Error - log error output
                if let errorString = String(data: errorData as Data, encoding: .utf8) {
                    print("Python script error: \(errorString)")
                }
                completion(.failure(PythonBridgeError.processFailed))
            }
        }
        
        // Start the process
        do {
            try process.run()
            
            // Set up timeout
            DispatchQueue.global().asyncAfter(deadline: .now() + timeoutInterval) {
                if process.isRunning {
                    process.terminate()
                    completion(.failure(PythonBridgeError.executionTimeout))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Private Methods
    private func cleanupTemporaryFile(_ url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Failed to cleanup temporary file: \(error)")
        }
    }
} 