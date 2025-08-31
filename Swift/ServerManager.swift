import Foundation
import Darwin

class ServerManager {
    
    // MARK: - Properties
    private let settingsManager: SettingsManager
    private let folderAccessManager: FolderAccessManager
    private let logger = Logger()
    private var serverProcess: Process?
    private var isRestarting = false
    
    // MARK: - Initialization
    init(settingsManager: SettingsManager? = nil, folderAccessManager: FolderAccessManager? = nil) {
        self.settingsManager = settingsManager ?? SettingsManager()
        self.folderAccessManager = folderAccessManager ?? FolderAccessManager()
        
        // Listen for settings changes that require server restart
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWhisperSettingsChanged),
            name: .whisperSettingsChanged,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleServerSettingsChanged),
            name: .serverSettingsChanged,
            object: nil
        )
    }
    
    // MARK: - Public Methods
    func startServer(completion: @escaping (Bool) -> Void) {
        logger.log("[ServerManager] Starting transcription server...", level: .info)
        
        // Determine which port to use: prefer configured non-zero if available; otherwise pick a free port
        let desiredPort = self.settingsManager.serverPort
        if desiredPort > 0 {
            if self.isPortAvailable(desiredPort) {
                self.logger.log("[ServerManager] Using configured port: \(desiredPort)", level: .info)
            } else if let freePort = self.findAvailablePort() {
                self.settingsManager.serverPort = freePort
                self.logger.log("[ServerManager] Configured port \(desiredPort) unavailable; selected free port: \(freePort)", level: .warning)
            } else {
                self.logger.log("[ServerManager] Failed to find a free port", level: .error)
                completion(false)
                return
            }
        } else {
            if let freePort = self.findAvailablePort() {
                self.settingsManager.serverPort = freePort
                self.logger.log("[ServerManager] Selected free port: \(freePort)", level: .info)
            } else {
                self.logger.log("[ServerManager] Failed to find a free port", level: .error)
                completion(false)
                return
            }
        }

        self.launchServerProcess(completion: completion)
    }

    private func launchServerProcess(completion: @escaping (Bool) -> Void) {
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
        
        // Ensure PATH includes common locations for Homebrew-installed tools like ffmpeg
        var env = ProcessInfo.processInfo.environment
        let extraBins = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin"]
        let currentPath = env["PATH"] ?? ""
        let appended = extraBins + currentPath.split(separator: ":").map(String.init)
        // Deduplicate while preserving order
        var seen = Set<String>()
        let newPath = appended.compactMap { path in
            if seen.contains(path) { return nil }
            seen.insert(path)
            return path
        }.joined(separator: ":")
        env["PATH"] = newPath
        process.environment = env
        
        // Set working directory to script's directory
        let scriptDirectory = URL(fileURLWithPath: fullScriptPath).deletingLastPathComponent()
        process.currentDirectoryURL = scriptDirectory
        
        // Set up pipes for monitoring
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Monitor output for server startup
        let expectedServerMessage = "Transcription server started on"
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.count > 0, let outputString = String(data: data, encoding: .utf8) {
                self?.logger.log("[ServerManager] Server stdout: \(outputString.trimmingCharacters(in: .whitespacesAndNewlines))", level: .debug)
                
                // Check if server is ready - look for server start message or listen message
                if outputString.contains(expectedServerMessage) ||
                   outputString.contains("Uvicorn running on") ||
                   outputString.contains("Application startup complete") {
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
            completion(true)
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopServer()
    }

    @objc private func handleServerSettingsChanged() {
        logger.log("[ServerManager] Server settings changed, restarting server...", level: .info)
        restartServerForSettingsChange()
    }
    
    @objc private func handleWhisperSettingsChanged() {
        logger.log("[ServerManager] Whisper settings changed, attempting to reload model via API...", level: .info)
        reloadWhisperModelViaAPI()
    }
    
    private func restartServerForSettingsChange() {
        // Prevent multiple simultaneous restarts
        guard !isRestarting else {
            logger.log("[ServerManager] Server restart already in progress, skipping...", level: .warning)
            return
        }
        
        isRestarting = true
        
        // Stop current server
        stopServer()
        
        // Wait a moment for cleanup, then restart
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.startServer { success in
                DispatchQueue.main.async {
                    self?.isRestarting = false
                    if success {
                        self?.logger.log("[ServerManager] Server restarted successfully after settings change", level: .info)
                    } else {
                        self?.logger.log("[ServerManager] Failed to restart server after settings change", level: .error)
                    }
                }
            }
        }
    }
    
    private func reloadWhisperModelViaAPI() {
        // First check if the server supports the reload_model endpoint
        checkServerCapabilities { [weak self] supportsReload in
            if supportsReload {
                self?.performModelReload()
            } else {
                self?.logger.log("[ServerManager] Server doesn't support model reload, falling back to restart", level: .warning)
                self?.restartServerForSettingsChange()
            }
        }
    }
    
    private func checkServerCapabilities(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(settingsManager.getServerURL())/providers") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                self.logger.log("[ServerManager] Failed to check server capabilities: \(error)", level: .error)
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Check if the response contains the reload_model endpoint info
                if let data = data,
                   let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let providers = responseDict["providers"] as? [String: Any],
                   let whisper = providers["whisper"] as? [String: Any] {
                    // If we get a valid response, assume the server supports reload
                    completion(true)
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }.resume()
    }
    
    private func performModelReload() {
        guard let url = URL(string: "\(settingsManager.getServerURL())/reload_model") else {
            logger.log("[ServerManager] Failed to create reload_model URL", level: .error)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Send the new configuration
        let config: [String: Any] = [
            "model": settingsManager.whisperModel,
            "language": settingsManager.whisperLanguage,
            "task": settingsManager.whisperTask,
            "temperature": settingsManager.whisperTemperature
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: config)
        } catch {
            logger.log("[ServerManager] Failed to serialize model config: \(error)", level: .error)
            return
        }
        
        logger.log("[ServerManager] Sending model reload request with config: \(config)", level: .info)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.log("[ServerManager] Failed to reload model via API: \(error)", level: .error)
                    // Fallback to server restart if API call fails
                    self?.logger.log("[ServerManager] Falling back to server restart...", level: .warning)
                    self?.restartServerForSettingsChange()
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        self?.logger.log("[ServerManager] Whisper model reloaded successfully via API", level: .info)
                        
                        // Parse response to get updated config
                        if let data = data,
                           let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let updatedConfig = responseDict["config"] as? [String: Any] {
                            self?.logger.log("[ServerManager] Model updated with config: \(updatedConfig)", level: .info)
                            
                            // Post notification for successful model reload
                            NotificationCenter.default.post(
                                name: .whisperModelReloaded,
                                object: self,
                                userInfo: ["config": updatedConfig]
                            )
                        }
                    } else {
                        self?.logger.log("[ServerManager] Failed to reload model via API: HTTP \(httpResponse.statusCode)", level: .error)
                        // Fallback to server restart if API call fails
                        self?.logger.log("[ServerManager] Falling back to server restart...", level: .warning)
                        self?.restartServerForSettingsChange()
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Private Methods
    private func isPortAvailable(_ port: Int) -> Bool {
        let sock = socket(AF_INET, SOCK_STREAM, 0)
        if sock < 0 { return false }
        defer { close(sock) }
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(UInt16(port)).bigEndian
        addr.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))
        let bindResult = withUnsafePointer(to: &addr) { ptr -> Int32 in
            let sockAddrPtr = UnsafeRawPointer(ptr).assumingMemoryBound(to: sockaddr.self)
            return bind(sock, sockAddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
        }
        return bindResult == 0
    }
    private func findAvailablePort() -> Int? {
        let sock = socket(AF_INET, SOCK_STREAM, 0)
        if sock < 0 { return nil }
        defer { close(sock) }
        
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(0).bigEndian // 0 lets the OS pick a free port
        addr.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))
        
        let bindResult = withUnsafePointer(to: &addr) { ptr -> Int32 in
            let sockAddrPtr = UnsafeRawPointer(ptr).assumingMemoryBound(to: sockaddr.self)
            return bind(sock, sockAddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
        }
        if bindResult != 0 { return nil }
        
        // Get assigned port
        var len = socklen_t(MemoryLayout<sockaddr_in>.size)
        var getsockAddr = sockaddr_in()
        let nameResult = withUnsafeMutablePointer(to: &getsockAddr) { ptr -> Int32 in
            let sockAddrPtr = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: sockaddr.self)
            return getsockname(sock, sockAddrPtr, &len)
        }
        if nameResult != 0 { return nil }
        
        let port = Int(UInt16(bigEndian: getsockAddr.sin_port))
        return port
    }
    private func checkServerHealth(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(settingsManager.getServerURL())/health") else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 2.0
        URLSession.shared.dataTask(with: request) { _, response, _ in
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
        }.resume()
    }
} 