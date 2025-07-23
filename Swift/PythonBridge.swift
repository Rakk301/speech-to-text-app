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
            return "Python script not found"
        case .executionTimeout:
            return "Python script execution timed out"
        case .pythonNotFound:
            return "uv not found on system"
        }
    }
}

class PythonBridge {
    
    // MARK: - Properties
    private let projectPath: String
    private let uvPath: String
    private let timeoutInterval: TimeInterval = 60.0
    
    // MARK: - Initialization
    init() {
        // Hardcode the project path for now - this is exactly like your terminal
        projectPath = "/Users/rakhshaanhussain/Personal Projects/Speech To Text App"
        uvPath = "/opt/homebrew/bin/uv"
        
        print("[PythonBridge] Project path: \(projectPath)")
        print("[PythonBridge] uv path: \(uvPath)")
    }
    
    // MARK: - Public Methods
    func transcribeAudio(_ audioFileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        print("[PythonBridge] Starting transcription for: \(audioFileURL.path)")
        
        // Check if uv exists
        guard FileManager.default.fileExists(atPath: uvPath) else {
            print("[PythonBridge] uv not found at: \(uvPath)")
            completion(.failure(PythonBridgeError.pythonNotFound))
            return
        }
        
        // Check if Python script exists
        let pythonScriptPath = projectPath + "/Python/transcribe.py"
        guard FileManager.default.fileExists(atPath: pythonScriptPath) else {
            print("[PythonBridge] Python script not found at: \(pythonScriptPath)")
            completion(.failure(PythonBridgeError.scriptNotFound))
            return
        }
        
        print("[PythonBridge] Both uv and Python script found, starting transcription...")
        
        // Create process - exactly like your terminal command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: uvPath)
        
        // Set up command arguments - exactly like your terminal
        process.arguments = [
            "run",
            "transcribe.py",
            audioFileURL.path,
            "--config", "../Config/settings.yaml"
        ]
        
        // Set working directory to Python directory - exactly like your terminal
        let pythonDirectory = URL(fileURLWithPath: projectPath + "/Python")
        process.currentDirectoryURL = pythonDirectory
        
        print("[PythonBridge] Working directory: \(pythonDirectory.path)")
        print("[PythonBridge] Command: \(uvPath) \(process.arguments?.joined(separator: " ") ?? "")")
        
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
                
                // Print stdout in real-time
                if let outputString = String(data: data, encoding: .utf8) {
                    print("[Python stdout] \(outputString)", terminator: "")
                }
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.count > 0 {
                errorData.append(data)
                
                // Print stderr in real-time
                if let errorString = String(data: data, encoding: .utf8) {
                    print("[Python stderr] \(errorString)", terminator: "")
                }
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
                        print("[PythonBridge] Transcription successful: \(trimmedOutput)")
                        completion(.success(trimmedOutput))
                    } else {
                        print("[PythonBridge] Empty transcription output")
                        completion(.failure(PythonBridgeError.invalidOutput))
                    }
                } else {
                    print("[PythonBridge] Failed to decode transcription output")
                    completion(.failure(PythonBridgeError.invalidOutput))
                }
            } else {
                // Error - log error output with better formatting
                print("[PythonBridge] Process failed with exit code: \(process.terminationStatus)")
                
                if let errorString = String(data: errorData as Data, encoding: .utf8) {
                    print("[PythonBridge] Final stderr output:")
                    print(errorString)
                }
                
                if let outputString = String(data: outputData as Data, encoding: .utf8) {
                    print("[PythonBridge] Final stdout output:")
                    print(outputString)
                }
                
                // Create a more descriptive error
                let errorMessage = "Python script failed with exit code \(process.terminationStatus). Check console for details."
                completion(.failure(PythonBridgeError.processFailed))
            }
        }
        
        // Set up environment with proper PATH
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        process.environment = environment
        
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
            print("[PythonBridge] Failed to start process: \(error)")
            completion(.failure(error))
        }
    }
} 