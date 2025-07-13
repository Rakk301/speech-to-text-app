import Foundation

enum PythonBridgeError: Error, LocalizedError {
    case processFailed
    case invalidOutput
    case scriptNotFound
    case executionTimeout
    
    var errorDescription: String? {
        switch self {
        case .processFailed:
            return "Python script execution failed"
        case .invalidOutput:
            return "Invalid output from Python script"
        case .scriptNotFound:
            return "Python transcribe script not found"
        case .executionTimeout:
            return "Python script execution timed out"
        }
    }
}

class PythonBridge {
    
    // MARK: - Properties
    private let pythonScriptPath: String
    private let timeoutInterval: TimeInterval = 30.0
    
    // MARK: - Initialization
    init() {
        // Get the path to the Python script
        if let bundlePath = Bundle.main.resourcePath {
            pythonScriptPath = bundlePath + "/Python/transcribe.py"
        } else {
            // Fallback to current directory
            pythonScriptPath = "./Python/transcribe.py"
        }
    }
    
    // MARK: - Public Methods
    func transcribeAudio(_ audioFileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        // Check if Python script exists
        guard FileManager.default.fileExists(atPath: pythonScriptPath) else {
            completion(.failure(PythonBridgeError.scriptNotFound))
            return
        }
        
        // Create process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [pythonScriptPath, audioFileURL.path]
        
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