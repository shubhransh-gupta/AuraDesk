import SwiftUI
import AppKit

@main
struct AuraDeskApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var store = WallpaperStore.shared
    @ObservedObject var desktop = DesktopWallpaperController.shared
    @ObservedObject var screenSaver = ScreenSaverController.shared
    @ObservedObject var energyEngine = EnergyEngine.shared

    var body: some Scene {
        Window("AuraDesk Pro — 4K Live Wallpaper, Screen Saver & Lock Screen", id: "main-window") {
            ContentView()
                .frame(minWidth: 960, minHeight: 620)
        }
        .defaultSize(width: 1160, height: 760)

        MenuBarExtra("AuraDesk", systemImage: "moon.stars.fill") {
            MenuBarQuickMenu()
        }
    }
}

struct MenuBarQuickMenu: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var store = WallpaperStore.shared
    @ObservedObject var desktop = DesktopWallpaperController.shared
    @ObservedObject var screenSaver = ScreenSaverController.shared
    @ObservedObject var energyEngine = EnergyEngine.shared

    var body: some View {
        Button("Open AuraDesk Studio...") {
            store.isStudioWindowOpen = true
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "main-window")
        }
        .keyboardShortcut("o", modifiers: [.command])

        Divider()

        // Live Playback Controls
        if desktop.currentVideoURL != nil {
            if desktop.isPausedForPowerSavings {
                Text("⚡ Paused for Power Savings")
                    .foregroundStyle(.secondary)
            }

            Button(desktop.isPlaying && !desktop.isPausedForPowerSavings ? "Pause Desktop Video" : "Resume Desktop Video") {
                desktop.togglePlayPause()
            }

            Button("Stop Desktop Wallpaper") {
                desktop.stop()
                store.activeDesktopID = nil
            }
        } else {
            Text("Desktop Wallpaper: Inactive")
                .foregroundStyle(.secondary)
        }

        Toggle("Mute Audio", isOn: $store.isMuted)

        if let item = store.items.first(where: { $0.id == (store.activeScreenSaverID ?? store.activeDesktopID) }) ?? store.items.first {
            Button("Start 4K Screen Saver Now") {
                screenSaver.startScreenSaver(with: item.fileURL)
            }
        }

        if let item = store.items.first(where: { $0.id == (store.activeDesktopID ?? store.activeLockScreenID) }) ?? store.items.first {
            Button("Apply to Lock Screen Now") {
                Task { await store.setLockScreenAndAerialScreenSaver(item: item) }
            }
        }

        Divider()

        // Power & Energy Section
        Text("⚡ \(energyEngine.energyStatusBadge)")
            .foregroundStyle(.secondary)

        Toggle("Auto-Pause on Battery Power", isOn: $energyEngine.autoPauseOnBattery)
        Toggle("Auto-Pause on Low Power Mode", isOn: $energyEngine.autoPauseOnLowPowerMode)
        Toggle("Eco 30fps Frame Rate on Battery", isOn: $energyEngine.ecoFrameRateOnBattery)

        Divider()

        // Background Application Mode
        Toggle("Run in Menu Bar Only (Hide from Dock)", isOn: $store.runInBackgroundMenuBarOnly)

        if !store.items.isEmpty {
            Divider()
            Menu("Quick Switch Video") {
                ForEach(store.items) { item in
                    Button {
                        store.setDesktopWallpaper(item)
                    } label: {
                        HStack {
                            if store.activeDesktopID == item.id {
                                Image(systemName: "checkmark")
                            }
                            Text(item.title)
                        }
                    }
                }
            }
        }

        Divider()

        Button("Quit AuraDesk") {
            confirmAndQuit()
        }
        .keyboardShortcut("q", modifiers: [.command])
    }

    private func confirmAndQuit() {
        let alert = NSAlert()
        alert.messageText = "Quit AuraDesk Pro?"
        alert.informativeText = "AuraDesk is designed to run in the background from your Menu Bar. Quitting will pause your live desktop wallpaper and screen saver."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Keep Running in Menu Bar")
        alert.addButton(withTitle: "Quit Application")

        let resp = alert.runModal()
        if resp == .alertSecondButtonReturn {
            NSApplication.shared.terminate(nil)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = WallpaperStore.shared

        let bundleURL = Bundle.main.bundleURL
        let iconCandidates = [
            Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
            Bundle.main.url(forResource: "moon-icon", withExtension: "png"),
            bundleURL.appendingPathComponent("Contents/Resources/AppIcon.icns"),
            bundleURL.appendingPathComponent("Contents/Resources/moon-icon.png")
        ].compactMap { $0 }
        for url in iconCandidates {
            if let img = NSImage(contentsOf: url) {
                NSApp.applicationIconImage = img
                break
            }
        }

        // On launch, show window and set regular mode; when window closes, switch to accessory if preferred
        store.isStudioWindowOpen = true
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Observe window closures to switch to menu bar only accessory mode
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                let normalVisible = NSApp.windows.filter {
                    $0.isVisible && !($0 is DesktopWallpaperWindow) && $0.level == .normal
                }
                if normalVisible.isEmpty {
                    WallpaperStore.shared.isStudioWindowOpen = false
                    WallpaperStore.shared.updateAppActivationPolicy()
                }
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        WallpaperStore.shared.isStudioWindowOpen = true
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        return true
    }
}
