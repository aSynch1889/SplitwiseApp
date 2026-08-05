import Foundation
import CloudKit
import CoreData
import Observation

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
                accountStatusText = "iCloud Sync Off"
                lastErrorMessage = nil
            }
        }
    }

    public var accountStatusText: String = "Checking…"
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
            accountStatusText = "iCloud Sync Off"
            return
        }

        CKContainer(identifier: Self.iCloudContainerID).accountStatus { status, error in
            Task { @MainActor in
                if let error {
                    self.accountStatusText = "iCloud Unavailable"
                    self.lastErrorMessage = error.localizedDescription
                    return
                }
                switch status {
                case .available:
                    self.accountStatusText = self.isCloudKitStoreActive
                        ? "iCloud Ready"
                        : "Signed In — Restart to Sync"
                    self.lastErrorMessage = nil
                case .noAccount:
                    self.accountStatusText = "Sign in to iCloud in Settings"
                case .restricted:
                    self.accountStatusText = "iCloud Restricted"
                case .couldNotDetermine:
                    self.accountStatusText = "Could Not Determine iCloud Status"
                case .temporarilyUnavailable:
                    self.accountStatusText = "iCloud Temporarily Unavailable"
                @unknown default:
                    self.accountStatusText = "Unknown iCloud Status"
                }
            }
        }
    }

    public var statusDetail: String {
        if let lastErrorMessage, !lastErrorMessage.isEmpty {
            return lastErrorMessage
        }
        if isSyncing {
            return "Syncing with iCloud…"
        }
        if let lastSyncDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return "Last sync \(formatter.localizedString(for: lastSyncDate, relativeTo: Date()))"
        }
        if isCloudKitStoreActive {
            return "Private CloudKit database · same Apple ID devices"
        }
        return "Local-only store (CloudKit not active in this session)"
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
