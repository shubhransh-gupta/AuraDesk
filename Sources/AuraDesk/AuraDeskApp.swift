import SwiftUI
import AppKit

@main
struct AuraDeskApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var store = WallpaperStore.shared
    @ObservedObject var desktop = DesktopWallpaperController.shared
    @ObservedObject var screenSaver = ScreenSaverController.shared

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

    var body: some View {
        Button("Open AuraDesk Studio...") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "main-window")
        }
        .keyboardShortcut("o", modifiers: [.command])

        Divider()

        if desktop.currentVideoURL != nil {
            Button(desktop.isPlaying ? "Pause Desktop Video" : "Resume Desktop Video") {
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
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: [.command])
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
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
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
