import Foundation

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

class Logger {

    // MARK: - Properties
    private let logFileURL: URL
    private let dateFormatter: DateFormatter
    private let fileHandle: FileHandle?
    private let componentName: String?
    
    // MARK: - Initialization
    init(componentName: String? = nil) {
        self.componentName = componentName
        // Create logs directory if it doesn't exist
        let logsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Logs")
        
        if let logsDir = logsDirectory {
            try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
            logFileURL = logsDir.appendingPathComponent("transcriptions.log")
        } else {
            // Fallback to temporary directory
            logFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("transcriptions.log")
        }
        
        // Set up date formatter
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // Create log file if it doesn't exist
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
        }
        
        // Open file handle for writing
        do {
            fileHandle = try FileHandle(forWritingTo: logFileURL)
            fileHandle?.seekToEndOfFile()
        } catch {
            print("Failed to open log file: \(error)")
            fileHandle = nil
        }
    }
    
    deinit {
        fileHandle?.closeFile()
    }
    
    // MARK: - Public Methods
    func log(_ message: String, level: LogLevel = .info) {
        let timestamp = dateFormatter.string(from: Date())
        let prefix = componentName != nil ? "[\(componentName!)] " : ""
        let logEntry = "[\(timestamp)] [\(level.rawValue)] \(prefix)\(message)\n"
        
        // Write to file
        if let data = logEntry.data(using: .utf8) {
            fileHandle?.write(data)
            fileHandle?.synchronizeFile()
        }
        
        // Also print to console for debugging
        print(logEntry.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    func logTranscription(_ text: String, audioFile: String) {
        let message = "Transcription completed - Audio: \(audioFile), Text: \"\(text)\""
        log(message, level: .info)
    }
    
    func logError(_ error: Error, context: String = "") {
        let message = "\(context.isEmpty ? "" : "\(context): ")\(error.localizedDescription)"
        log(message, level: .error)
    }
    
    // MARK: - Utility Methods
    func getLogContents() -> String? {
        do {
            return try String(contentsOf: logFileURL, encoding: .utf8)
        } catch {
            print("Failed to read log file: \(error)")
            return nil
        }
    }
    
    func clearLogs() {
        do {
            try "".write(to: logFileURL, atomically: true, encoding: .utf8)
            fileHandle?.seekToEndOfFile()
        } catch {
            print("Failed to clear log file: \(error)")
        }
    }
    
    func rotateLogs() {
        // Simple log rotation - keep only last 1000 lines
        guard let contents = getLogContents() else { return }
        
        let lines = contents.components(separatedBy: .newlines)
        if lines.count > 1000 {
            let recentLines = Array(lines.suffix(1000))
            let newContents = recentLines.joined(separator: "\n")
            
            do {
                try newContents.write(to: logFileURL, atomically: true, encoding: .utf8)
                fileHandle?.seekToEndOfFile()
            } catch {
                print("Failed to rotate log file: \(error)")
            }
        }
    }
} 