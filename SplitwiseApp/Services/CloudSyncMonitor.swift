import Foundation
import CloudKit
import CoreData
import Observation

public enum ICloudAccountStatus: Equatable {
    case checking
    case syncOff
    case unavailable
    case ready
    case signedInRestartRequired
    case noAccount
    case restricted
    case couldNotDetermine
    case temporarilyUnavailable
    case unknown
}

public enum SyncStatusDetail: Equatable {
    case none
    case error(String)
    case syncing
    case lastSync(Date)
    case privateCloudKit
    case localOnly
}

/// Observes CloudKit account + NSPersistentCloudKitContainer sync events for SwiftData stores.
@MainActor
@Observable
public final class CloudSyncMonitor {
    public static let shared = CloudSyncMonitor()

    public static let iCloudContainerID = "iCloud.app.billnest.ios"
    public static let iCloudEnabledKey = "app_icloud_sync_enabled"

    public var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.iCloudEnabledKey)
            if isEnabled {
                refreshAccountStatus()
            } else {
                accountStatus = .syncOff
                lastErrorMessage = nil
            }
        }
    }

    public private(set) var accountStatus: ICloudAccountStatus = .checking
    public var isSyncing: Bool = false
    public var lastSyncDate: Date?
    public var lastErrorMessage: String?
    /// True when the running ModelContainer was opened with CloudKit.
    public var isCloudKitStoreActive: Bool = false
    public var needsRestartToApply: Bool = false

    private var eventObserver: NSObjectProtocol?

    private init() {
        // Default ON for multi-device continuity; user can turn off (takes effect after relaunch).
        if UserDefaults.standard.object(forKey: Self.iCloudEnabledKey) == nil {
            UserDefaults.standard.set(true, forKey: Self.iCloudEnabledKey)
        }
        self.isEnabled = UserDefaults.standard.bool(forKey: Self.iCloudEnabledKey)
    }

    public var accountStatusLocalizationKey: String {
        switch accountStatus {
        case .checking:
            return "Checking…"
        case .syncOff:
            return "iCloud Sync Off"
        case .unavailable:
            return "iCloud Unavailable"
        case .ready:
            return "iCloud Ready"
        case .signedInRestartRequired:
            return "Signed In — Restart to Sync"
        case .noAccount:
            return "Sign in to iCloud in Settings"
        case .restricted:
            return "iCloud Restricted"
        case .couldNotDetermine:
            return "Could Not Determine iCloud Status"
        case .temporarilyUnavailable:
            return "iCloud Temporarily Unavailable"
        case .unknown:
            return "Unknown iCloud Status"
        }
    }

    public var syncStatusDetail: SyncStatusDetail {
        if let lastErrorMessage, !lastErrorMessage.isEmpty {
            return .error(lastErrorMessage)
        }
        if isSyncing {
            return .syncing
        }
        if let lastSyncDate {
            return .lastSync(lastSyncDate)
        }
        if isCloudKitStoreActive {
            return .privateCloudKit
        }
        return .localOnly
    }

    public func startMonitoring() {
        refreshAccountStatus()
        guard eventObserver == nil else { return }

        eventObserver = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleCloudKitEvent(notification)
            }
        }
    }

    public func stopMonitoring() {
        if let eventObserver {
            NotificationCenter.default.removeObserver(eventObserver)
            self.eventObserver = nil
        }
    }

    public func refreshAccountStatus() {
        guard isEnabled else {
            accountStatus = .syncOff
            return
        }

        accountStatus = .checking

        CKContainer(identifier: Self.iCloudContainerID).accountStatus { status, error in
            Task { @MainActor in
                if let error {
                    self.accountStatus = .unavailable
                    self.lastErrorMessage = error.localizedDescription
                    return
                }
                switch status {
                case .available:
                    self.accountStatus = self.isCloudKitStoreActive ? .ready : .signedInRestartRequired
                    self.lastErrorMessage = nil
                case .noAccount:
                    self.accountStatus = .noAccount
                case .restricted:
                    self.accountStatus = .restricted
                case .couldNotDetermine:
                    self.accountStatus = .couldNotDetermine
                case .temporarilyUnavailable:
                    self.accountStatus = .temporarilyUnavailable
                @unknown default:
                    self.accountStatus = .unknown
                }
            }
        }
    }

    private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else { return }

        switch event.type {
        case .setup:
            isSyncing = event.endDate == nil
        case .import, .export:
            isSyncing = event.endDate == nil
            if let end = event.endDate {
                lastSyncDate = end
                isSyncing = false
            }
        @unknown default:
            break
        }

        if let error = event.error {
            lastErrorMessage = error.localizedDescription
        } else if event.endDate != nil {
            lastErrorMessage = nil
        }
    }
}
