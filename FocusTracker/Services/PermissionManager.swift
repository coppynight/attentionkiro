import Foundation
import DeviceActivity
import FamilyControls
import Combine
import UIKit

/// Manages permissions for device activity monitoring
class PermissionManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var deviceActivityPermissionStatus: PermissionStatus = .notDetermined
    @Published var screenTimePermissionStatus: PermissionStatus = .notDetermined
    @Published var isRequestingPermission = false
    
    // MARK: - Types
    
    enum PermissionStatus {
        case notDetermined
        case granted
        case denied
        case restricted
    }
    
    // MARK: - Singleton
    
    static let shared = PermissionManager()
    
    private init() {
        checkCurrentPermissionStatus()
    }
    
    // MARK: - Public Methods
    
    /// Checks current permission status for all required permissions
    func checkCurrentPermissionStatus() {
        checkDeviceActivityPermission()
        checkScreenTimePermission()
    }
    
    /// Requests DeviceActivity permission
    func requestDeviceActivityPermission() async -> Bool {
        await MainActor.run {
            isRequestingPermission = true
        }
        
        defer {
            Task { @MainActor in
                isRequestingPermission = false
            }
        }
        
        do {
            if #available(iOS 16.0, *) {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                await MainActor.run {
                    deviceActivityPermissionStatus = .granted
                }
                print("PermissionManager: DeviceActivity permission granted")
                return true
            } else {
                await MainActor.run {
                    deviceActivityPermissionStatus = .denied
                }
                print("PermissionManager: DeviceActivity requires iOS 16.0 or later")
                return false
            }
        } catch {
            await MainActor.run {
                deviceActivityPermissionStatus = .denied
            }
            print("PermissionManager: DeviceActivity permission denied: \(error)")
            return false
        }
    }
    
    /// Checks if all required permissions are granted
    var hasAllRequiredPermissions: Bool {
        return deviceActivityPermissionStatus == .granted
    }
    
    /// Opens system settings for the app
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Private Methods
    
    private func checkDeviceActivityPermission() {
        let authStatus = AuthorizationCenter.shared.authorizationStatus
        
        switch authStatus {
        case .notDetermined:
            deviceActivityPermissionStatus = .notDetermined
        case .denied:
            deviceActivityPermissionStatus = .denied
        case .approved:
            deviceActivityPermissionStatus = .granted
        @unknown default:
            deviceActivityPermissionStatus = .notDetermined
        }
        
        print("PermissionManager: DeviceActivity permission status: \(deviceActivityPermissionStatus)")
    }
    
    private func checkScreenTimePermission() {
        // Screen Time permission is typically handled through DeviceActivity
        // For now, we'll mirror the DeviceActivity status
        screenTimePermissionStatus = deviceActivityPermissionStatus
    }
}

// MARK: - Extensions

extension PermissionManager.PermissionStatus {
    var localizedDescription: String {
        switch self {
        case .notDetermined:
            return "未确定"
        case .granted:
            return "已授权"
        case .denied:
            return "已拒绝"
        case .restricted:
            return "受限制"
        }
    }
    
    var isGranted: Bool {
        return self == .granted
    }
}