import Foundation

class ServerManager {
    
    // MARK: - Properties
    private let projectPath: String
    private let uvPath: String
    private var serverProcess: Process?
    
    // MARK: - Initialization
    init() {
        projectPath = "/Users/rakhshaanhussain/Personal Projects/Speech To Text App"
        uvPath = "/opt/homebrew/bin/uv"
    }
    
    // MARK: - Public Methods
    func startServer(completion: @escaping (Bool) -> Void) {
        print("[ServerManager] Starting transcription server...")
        
        // Check if uv exists
        guard FileManager.default.fileExists(atPath: uvPath) else {
            print("[ServerManager] uv not found at: \(uvPath)")
            completion(false)
            return
        }
        
        // Check if server script exists
        let serverScriptPath = projectPath + "/Python/transcription_server.py"
        guard FileManager.default.fileExists(atPath: serverScriptPath) else {
            print("[ServerManager] Server script not found at: \(serverScriptPath)")
            completion(false)
            return
        }
        
        // Create process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: uvPath)
        process.arguments = ["run", "python", "transcription_server.py"]
        
        // Set working directory
        let pythonDirectory = URL(fileURLWithPath: projectPath + "/Python")
        process.currentDirectoryURL = pythonDirectory
        
        // Set up pipes for monitoring
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Monitor output for server startup
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.count > 0, let outputString = String(data: data, encoding: .utf8) {
                print("[Server stdout] \(outputString)", terminator: "")
                
                // Check if server is ready
                if outputString.contains("Transcription server started on http://localhost:8080") {
                    DispatchQueue.main.async {
                        completion(true)
                    }
                }
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.count > 0, let errorString = String(data: data, encoding: .utf8) {
                print("[Server stderr] \(errorString)", terminator: "")
            }
        }
        
        // Set up environment
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        process.environment = environment
        
        // Start the process
        do {
            try process.run()
            serverProcess = process
            print("[ServerManager] Server process started")
        } catch {
            print("[ServerManager] Failed to start server: \(error)")
            completion(false)
        }
    }
    
    func stopServer() {
        serverProcess?.terminate()
        serverProcess = nil
        print("[ServerManager] Server stopped")
    }
} 