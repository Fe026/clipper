import Foundation
import ServiceManagement
import OSLog
import Combine

@MainActor
class LoginItemService: ObservableObject {
    static let shared = LoginItemService()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "clipper", category: "LoginItemService")
    
    @Published var isEnabled: Bool {
        didSet {
            updateLoginItem(enabled: isEnabled)
        }
    }
    
    private init() {
        let status = SMAppService.mainApp.status
        self.isEnabled = (status == .enabled)
        logger.debug("Initial login item status: \(status.rawValue)")
    }
    
    private func updateLoginItem(enabled: Bool) {
        let service = SMAppService.mainApp
        
        if enabled {
            if service.status == .enabled { return }
            do {
                try service.register()
                logger.info("Successfully registered main app as login item.")
            } catch {
                logger.error("Failed to register login item: \(error.localizedDescription)")
                Task { @MainActor in
                    self.isEnabled = false
                }
            }
        } else {
            if service.status != .enabled { return }
            do {
                try service.unregister()
                logger.info("Successfully unregistered main app as login item.")
            } catch {
                logger.error("Failed to unregister login item: \(error.localizedDescription)")
                Task { @MainActor in
                    self.isEnabled = true
                }
            }
        }
    }
}
