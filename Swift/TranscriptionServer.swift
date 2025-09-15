import Foundation
import Darwin

class TranscriptionServer {

    // MARK: - Properties
    private let settingsManager: SettingsManager
    private let logger = Logger(componentName: "TranscriptionServer")
    private var serverProcess: Process?
    private var isRestarting = false

    // MARK: - Initialization
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        
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
        logger.log("Starting transcription server...", level: .info)
        
        // Determine which port to use: prefer configured non-zero if available; otherwise pick a free port
        let desiredPort = self.settingsManager.serverPort
        if desiredPort > 0 {
            if self.isPortAvailable(desiredPort) {
                self.logger.log("Using configured port: \(desiredPort)", level: .info)
            } else if let freePort = self.findAvailablePort() {
                self.settingsManager.serverPort = freePort
                self.logger.log("Configured port \(desiredPort) unavailable; selected free port: \(freePort)", level: .warning)
            } else {
                self.logger.log("Failed to find a free port", level: .error)
                completion(false)
                return
            }
        } else {
            if let freePort = self.findAvailablePort() {
                self.settingsManager.serverPort = freePort
                self.logger.log("Selected free port: \(freePort)", level: .info)
            } else {
                self.logger.log("Failed to find a free port", level: .error)
                completion(false)
                return
            }
        }

        self.launchServerProcess(completion: completion)
    }

    private func launchServerProcess(completion: @escaping (Bool) -> Void) {
        // Get bundle resources URL - stt-server-py is copied as a subdirectory
        guard let bundleResources = Bundle.main.resourceURL else {
            logger.log("Failed to get bundle resources URL", level: .error)
            completion(false)
            return
        }

        // Python server is in stt-server-py subdirectory within Resources
        let pythonProjectDir = bundleResources.appendingPathComponent("stt-server-py")
        let scriptPath = pythonProjectDir.appendingPathComponent("transcription_server.py")
        
        // Use settings file from Application Support
        let settingsPath = settingsManager.configFileURL

        logger.log("Using uv run with project: \(pythonProjectDir.path)", level: .info)
        logger.log("Script: \(scriptPath.path)", level: .info)
        logger.log("Settings: \(settingsPath.path)", level: .info)
        
        let uvPath = settingsManager.uvPath

        // Check if the specified path exists
        if !FileManager.default.fileExists(atPath: uvPath) {
            logger.log("uv executable not found at: \(uvPath)", level: .error)
            completion(false)
            return
        }
        logger.log("uv path verified successfully", level: .info)

        // Create process using the specified uv path
        let process = Process()
        
        process.executableURL = URL(fileURLWithPath: uvPath)
        process.arguments = [
            "run",
            "--project", pythonProjectDir.path,
            "python", scriptPath.lastPathComponent,  // Use just the filename since we're in the project directory
            settingsPath.path,
            "--host", settingsManager.serverHost,
            "--port", "\(settingsManager.serverPort)"
        ]

        // Ensure PATH includes common locations for Homebrew-installed tools like ffmpeg and uv
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

        // Set working directory to Python project directory
        process.currentDirectoryURL = pythonProjectDir
        
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
                self?.logger.log("Server stdout: \(outputString.trimmingCharacters(in: .whitespacesAndNewlines))", level: .debug)
                
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
                self?.logger.log("Server stderr: \(errorString.trimmingCharacters(in: .whitespacesAndNewlines))", level: .warning)
            }
        }
        
        // Start the process (inherits environment automatically)
        do {
            try process.run()
            serverProcess = process
            logger.log("Server process started successfully", level: .info)
            completion(true)
        } catch {
            logger.logError(error, context: "Failed to start server")
            completion(false)
        }
    }
    
    func stopServer() {
        serverProcess?.terminate()
        serverProcess = nil
        logger.log("Server stopped", level: .info)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopServer()
    }

    @objc private func handleServerSettingsChanged() {
        logger.log("Server settings changed, restarting server...", level: .info)
        restartServerForSettingsChange()
    }
    
    @objc private func handleWhisperSettingsChanged() {
        logger.log("Whisper settings changed, attempting to reload model via API...", level: .info)
        reloadWhisperModelViaAPI()
    }
    
    private func restartServerForSettingsChange() {
        // Prevent multiple simultaneous restarts
        guard !isRestarting else {
            logger.log("Server restart already in progress, skipping...", level: .warning)
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
                        self?.logger.log("Server restarted successfully after settings change", level: .info)
                    } else {
                        self?.logger.log("Failed to restart server after settings change", level: .error)
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
                self?.logger.log("Server doesn't support model reload, falling back to restart", level: .warning)
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
                self.logger.log("Failed to check server capabilities: \(error)", level: .error)
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Check if the response contains the reload_model endpoint info
                if let data = data,
                   let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let providers = responseDict["providers"] as? [String: Any],
                   let _ = providers["whisper"] as? [String: Any] {
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
            logger.log("Failed to create reload_model URL", level: .error)
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
            logger.log("Failed to serialize model config: \(error)", level: .error)
            return
        }
        
        logger.log("Sending model reload request with config: \(config)", level: .info)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.log("Failed to reload model via API: \(error)", level: .error)
                    // Fallback to server restart if API call fails
                    self?.logger.log("Falling back to server restart...", level: .warning)
                    self?.restartServerForSettingsChange()
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        self?.logger.log("Whisper model reloaded successfully via API", level: .info)
                        
                        // Parse response to get updated config
                        if let data = data,
                           let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let updatedConfig = responseDict["config"] as? [String: Any] {
                            self?.logger.log("Model updated with config: \(updatedConfig)", level: .info)
                            
                            // Post notification for successful model reload
                            NotificationCenter.default.post(
                                name: .whisperModelReloaded,
                                object: self,
                                userInfo: ["config": updatedConfig]
                            )
                        }
                    } else {
                        self?.logger.log("Failed to reload model via API: HTTP \(httpResponse.statusCode)", level: .error)
                        // Fallback to server restart if API call fails
                        self?.logger.log("Falling back to server restart...", level: .warning)
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
        logger.log("Attempting to find available port...", level: .debug)
        
        let sock = socket(AF_INET, SOCK_STREAM, 0)
        if sock < 0 { 
            logger.log("Failed to create socket, errno: \(errno)", level: .error)
            return nil 
        }
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
        if bindResult != 0 { 
            logger.log("Failed to bind socket, errno: \(errno)", level: .error)
            return nil 
        }
        
        // Get assigned port
        var len = socklen_t(MemoryLayout<sockaddr_in>.size)
        var getsockAddr = sockaddr_in()
        let nameResult = withUnsafeMutablePointer(to: &getsockAddr) { ptr -> Int32 in
            let sockAddrPtr = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: sockaddr.self)
            return getsockname(sock, sockAddrPtr, &len)
        }
        if nameResult != 0 { 
            logger.log("Failed to get socket name, errno: \(errno)", level: .error)
            return nil 
        }
        
        let port = Int(UInt16(bigEndian: getsockAddr.sin_port))
        logger.log("Found available port: \(port)", level: .debug)
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