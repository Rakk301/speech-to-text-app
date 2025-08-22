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
        self.folderAccessManager = folderAccessManager ?? FolderAccessManager()
        self.settingsManager = settingsManager ?? SettingsManager(folderAccessManager: self.folderAccessManager)
        
        // Listen for settings changes that require server restart
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Notification Setup
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleServerSettingsChanged),
            name: NSNotification.Name("ServerSettingsChanged"),
            object: nil
        )
    }
    
    @objc private func handleServerSettingsChanged() {
        logger.log("[ServerManager] Server settings changed, restarting server...", level: .info)
        restartServerForSettingsChange()
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