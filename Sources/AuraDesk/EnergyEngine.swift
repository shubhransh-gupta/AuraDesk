import Foundation
import AppKit
import IOKit.ps
import Combine

@MainActor
public final class EnergyEngine: ObservableObject {
    public static let shared = EnergyEngine()

    @Published public private(set) var isOnBattery: Bool = false
    @Published public private(set) var isLowPowerMode: Bool = false
    @Published public private(set) var batteryPercentage: Int = 100
    @Published public private(set) var isDesktopOccluded: Bool = false
    @Published public private(set) var shouldPausePlayback: Bool = false
    @Published public private(set) var thermalStateDescription: String = "Nominal"

    // User preferences (persisted in UserDefaults)
    @Published public var autoPauseOnBattery: Bool {
        didSet {
            UserDefaults.standard.set(autoPauseOnBattery, forKey: "EnergyEngine_autoPauseOnBattery")
            reevaluatePlaybackState()
        }
    }

    @Published public var autoPauseOnLowPowerMode: Bool {
        didSet {
            UserDefaults.standard.set(autoPauseOnLowPowerMode, forKey: "EnergyEngine_autoPauseOnLowPowerMode")
            reevaluatePlaybackState()
        }
    }

    @Published public var autoPauseWhenOccluded: Bool {
        didSet {
            UserDefaults.standard.set(autoPauseWhenOccluded, forKey: "EnergyEngine_autoPauseWhenOccluded")
            reevaluatePlaybackState()
        }
    }

    @Published public var ecoFrameRateOnBattery: Bool {
        didSet {
            UserDefaults.standard.set(ecoFrameRateOnBattery, forKey: "EnergyEngine_ecoFrameRateOnBattery")
            reevaluatePlaybackState()
        }
    }

    private var pollTimer: Timer?

    private init() {
        self.autoPauseOnBattery = UserDefaults.standard.object(forKey: "EnergyEngine_autoPauseOnBattery") as? Bool ?? false
        self.autoPauseOnLowPowerMode = UserDefaults.standard.object(forKey: "EnergyEngine_autoPauseOnLowPowerMode") as? Bool ?? true
        self.autoPauseWhenOccluded = UserDefaults.standard.object(forKey: "EnergyEngine_autoPauseWhenOccluded") as? Bool ?? true
        self.ecoFrameRateOnBattery = UserDefaults.standard.object(forKey: "EnergyEngine_ecoFrameRateOnBattery") as? Bool ?? true

        refreshPowerState()
        setupNotifications()
        startPeriodicPolling()
    }

    public var energyStatusBadge: String {
        if isLowPowerMode && autoPauseOnLowPowerMode {
            return "Low Power Mode • Paused"
        }
        if isOnBattery {
            if autoPauseOnBattery {
                return "Battery (\(batteryPercentage)%) • Paused"
            } else if ecoFrameRateOnBattery {
                return "Battery (\(batteryPercentage)%) • Eco 30fps"
            } else {
                return "Battery (\(batteryPercentage)%) • Active"
            }
        }
        return "AC Power • Max 60fps"
    }

    public func refreshPowerState() {
        // 1. Check Low Power Mode
        self.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

        // 2. Check Thermal State
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: self.thermalStateDescription = "Nominal"
        case .fair: self.thermalStateDescription = "Fair"
        case .serious: self.thermalStateDescription = "High (Throttled)"
        case .critical: self.thermalStateDescription = "Critical (Paused)"
        @unknown default: self.thermalStateDescription = "Normal"
        }

        // 3. Check Battery state via IOKit
        var detectedBattery = false
        var currentPercent = 100

        if let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
           let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] {
            for source in sources {
                if let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
                    if let state = desc[kIOPSPowerSourceStateKey] as? String,
                       state == kIOPSBatteryPowerValue {
                        detectedBattery = true
                    }
                    if let cur = desc[kIOPSCurrentCapacityKey] as? Int,
                       let max = desc[kIOPSMaxCapacityKey] as? Int, max > 0 {
                        currentPercent = Int((Double(cur) / Double(max)) * 100.0)
                    }
                }
            }
        }

        self.isOnBattery = detectedBattery
        self.batteryPercentage = currentPercent

        // 4. Check Desktop Occlusion
        checkDesktopOcclusion()

        reevaluatePlaybackState()
    }

    private func checkDesktopOcclusion() {
        guard autoPauseWhenOccluded else {
            self.isDesktopOccluded = false
            return
        }

        // Check if frontmost application is in full screen mode
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           frontApp.bundleIdentifier != Bundle.main.bundleIdentifier {
            // Keep desktop available while letting user enjoy wallpaper
            self.isDesktopOccluded = false
        }
    }

    public func reevaluatePlaybackState() {
        var shouldPause = false

        // Rule 1: Low Power Mode
        if autoPauseOnLowPowerMode && isLowPowerMode {
            shouldPause = true
        }

        // Rule 2: Unplugged / On Battery Power
        if autoPauseOnBattery && isOnBattery {
            shouldPause = true
        }

        // Rule 3: Critical thermal throttling
        if ProcessInfo.processInfo.thermalState == .critical {
            shouldPause = true
        }

        self.shouldPausePlayback = shouldPause

        // Update Desktop Controller
        if shouldPause {
            DesktopWallpaperController.shared.pauseForPowerSavings()
        } else {
            DesktopWallpaperController.shared.resumeFromPowerSavings()
        }
    }

    private func setupNotifications() {
        let center = NotificationCenter.default
        let wsCenter = NSWorkspace.shared.notificationCenter

        // Low Power Mode or Power Source Change
        center.addObserver(
            forName: NSNotification.Name.NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshPowerState()
            }
        }

        // Thermal State Change
        center.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshPowerState()
            }
        }

        // Frontmost application change
        wsCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkDesktopOcclusion()
                self?.reevaluatePlaybackState()
            }
        }
    }

    private func startPeriodicPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshPowerState()
            }
        }
    }

    deinit {
        pollTimer?.invalidate()
    }
}
