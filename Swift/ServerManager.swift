import Foundation

class ServerManager {
    
    // MARK: - Properties
    private let settingsManager: SettingsManager
    private let folderAccessManager: FolderAccessManager
    private let logger = Logger()
    private var serverProcess: Process?
    
    // MARK: - Initialization
    init(settingsManager: SettingsManager? = nil, folderAccessManager: FolderAccessManager? = nil) {
        self.settingsManager = settingsManager ?? SettingsManager()
        self.folderAccessManager = folderAccessManager ?? FolderAccessManager()
    }
    
    // MARK: - Public Methods
    func startServer(completion: @escaping (Bool) -> Void) {
        logger.log("[ServerManager] Starting transcription server...", level: .info)
        
        // Check if we have folder access
        guard folderAccessManager.hasProjectFolderAccess else {
            logger.log("[ServerManager] No project folder access. Please select project folder in settings.", level: .error)
            completion(false)
            return
        }
        
        // Get full paths using folder access
        guard let fullPythonPath = folderAccessManager.getFullPath(for: settingsManager.pythonPath) else {
            logger.log("[ServerManager] Failed to resolve Python path: \(settingsManager.pythonPath)", level: .error)
            completion(false)
            return
        }
        
        guard let fullScriptPath = folderAccessManager.getFullPath(for: settingsManager.scriptPath) else {
            logger.log("[ServerManager] Failed to resolve script path: \(settingsManager.scriptPath)", level: .error)
            completion(false)
            return
        }
        
        logger.log("[ServerManager] Using Python: \(fullPythonPath)", level: .info)
        logger.log("[ServerManager] Using Script: \(fullScriptPath)", level: .info)
        
        // Create process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: fullPythonPath)
        process.arguments = [fullScriptPath, "../Config/settings.yaml", "--host", settingsManager.serverHost, "--port", "\(settingsManager.serverPort)"]
        
        // Set working directory to script's directory
        let scriptDirectory = URL(fileURLWithPath: fullScriptPath).deletingLastPathComponent()
        process.currentDirectoryURL = scriptDirectory
        
        // Set up pipes for monitoring
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Monitor output for server startup
        let expectedServerMessage = "Transcription server started on \(settingsManager.getServerURL())"
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.count > 0, let outputString = String(data: data, encoding: .utf8) {
                self?.logger.log("[ServerManager] Server stdout: \(outputString.trimmingCharacters(in: .whitespacesAndNewlines))", level: .debug)
                
                // Check if server is ready - look for server start message or listen message
                if outputString.contains(expectedServerMessage) || 
                   outputString.contains("Uvicorn running on") ||
                   outputString.contains("Application startup complete") {
                    DispatchQueue.main.async {
                        completion(true)
                    }
                }
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.count > 0, let errorString = String(data: data, encoding: .utf8) {
                self?.logger.log("[ServerManager] Server stderr: \(errorString.trimmingCharacters(in: .whitespacesAndNewlines))", level: .warning)
            }
        }
        
        // Start the process (inherits environment automatically)
        do {
            try process.run()
            serverProcess = process
            logger.log("[ServerManager] Server process started successfully", level: .info)
        } catch {
            logger.logError(error, context: "[ServerManager] Failed to start server")
            completion(false)
        }
    }
    
    func stopServer() {
        serverProcess?.terminate()
        serverProcess = nil
        logger.log("[ServerManager] Server stopped", level: .info)
    }
} 