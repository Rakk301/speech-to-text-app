import Foundation
import AppKit

class FolderAccessManager: ObservableObject {
    
    // MARK: - Properties
    @Published var hasProjectFolderAccess = false
    @Published var projectFolderPath: String = ""
    
    private let logger = Logger()
    private let bookmarkKey = "ProjectFolderBookmark"
    
    // MARK: - Initialization
    init() {
        loadSavedBookmark()
    }
    
    // MARK: - Public Methods
    func requestProjectFolderAccess() {
        let panel = NSOpenPanel()
        panel.title = "Select Your Speech-to-Text Project Folder"
        panel.message = "Choose the folder containing your Python transcription server"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        
        // Try to start in user's Documents folder
        panel.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        
        if panel.runModal() == .OK, let selectedURL = panel.url {
            grantAccessToFolder(selectedURL)
        }
    }
    
    func getProjectFolderURL() -> URL? {
        guard hasProjectFolderAccess else { return nil }
        return URL(fileURLWithPath: projectFolderPath)
    }
    
    func getFullPath(for relativePath: String) -> String? {
        guard let projectURL = getProjectFolderURL() else { return nil }
        return projectURL.appendingPathComponent(relativePath).path
    }
    
    func validatePythonPaths(pythonPath: String, scriptPath: String) -> (pythonExists: Bool, scriptExists: Bool) {
        guard let projectURL = getProjectFolderURL() else {
            return (false, false)
        }
        
        let fullPythonPath = projectURL.appendingPathComponent(pythonPath).path
        let fullScriptPath = projectURL.appendingPathComponent(scriptPath).path
        
        return (
            FileManager.default.fileExists(atPath: fullPythonPath),
            FileManager.default.fileExists(atPath: fullScriptPath)
        )
    }
    
    func revokeAccess() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        hasProjectFolderAccess = false
        projectFolderPath = ""
        logger.log("Revoked project folder access", level: .info)
    }
    
    // MARK: - Private Methods
    private func grantAccessToFolder(_ url: URL) {
        do {
            // Create security-scoped bookmark
            let bookmarkData = try url.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
            // Save bookmark for future app launches
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
            
            // Update state
            hasProjectFolderAccess = true
            projectFolderPath = url.path
            
            logger.log("Granted access to project folder: \(url.path)", level: .info)
            
        } catch {
            logger.logError(error, context: "Failed to create security-scoped bookmark")
        }
    }
    
    private func loadSavedBookmark() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            logger.log("No saved project folder bookmark found", level: .debug)
            return
        }
        
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                logger.log("Project folder bookmark is stale, removing", level: .warning)
                UserDefaults.standard.removeObject(forKey: bookmarkKey)
                return
            }
            
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                logger.log("Failed to start accessing security-scoped resource", level: .error)
                return
            }
            
            hasProjectFolderAccess = true
            projectFolderPath = url.path
            
            logger.log("Restored access to project folder: \(url.path)", level: .info)
            
        } catch {
            logger.logError(error, context: "Failed to resolve security-scoped bookmark")
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
        }
    }
}