import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct ContentView: View {
    @ObservedObject var store = WallpaperStore.shared
    @ObservedObject var catalog = CloudCatalogService.shared
    @ObservedObject var desktop = DesktopWallpaperController.shared
    @ObservedObject var lockScreen = LockScreenManager.shared
    @ObservedObject var screenSaver = ScreenSaverController.shared

    public enum SidebarSection: String, CaseIterable, Identifiable {
        case discover4K = "Discover 4K Catalog"
        case myLibrary = "My Downloaded Library"
        case lockScreen = "Lock Screen & Aerial"
        case screenSaver = "Screen Saver Engine"
        case settings = "Playback & Energy"

        public var id: String { rawValue }

        public var icon: String {
            switch self {
            case .discover4K: return "globe.americas.fill"
            case .myLibrary: return "film.stack.fill"
            case .lockScreen: return "lock.display"
            case .screenSaver: return "sparkles.tv"
            case .settings: return "slider.horizontal.3"
            }
        }
    }

    public init() {}

    public var body: some View {
        NavigationSplitView {
            sidebarView
                .navigationSplitViewColumnWidth(min: 225, ideal: 240, max: 270)
        } detail: {
            VStack(spacing: 0) {
                topStatusBanner
                Divider()
                Group {
                    switch store.selectedSection {
                    case .discover4K:
                        discover4KCatalogView
                    case .myLibrary:
                        libraryGridView
                    case .lockScreen:
                        lockScreenDetailView
                    case .screenSaver:
                        screenSaverDetailView
                    case .settings:
                        playbackSettingsView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 1020, minHeight: 680)
        .onDrop(of: [.fileURL], isTargeted: $store.isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [.indigo, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 34, height: 34)
                    Image(systemName: "sparkles.tv.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("AuraDesk")
                        .font(.headline.weight(.bold))
                    Text("4K Desktop • Saver • Lock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)

            List(SidebarSection.allCases, selection: $store.selectedSection) { section in
                HStack {
                    Label(section.rawValue, systemImage: section.icon)
                    Spacer()
                    if section == .discover4K {
                        Text("\(catalog.allRemoteItems.count)")
                            .font(.caption2.monospacedDigit())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    } else if section == .myLibrary {
                        Text("\(store.items.count)")
                            .font(.caption2.monospacedDigit())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    }
                }
                .tag(section)
            }
            .listStyle(.sidebar)

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(desktop.isPlaying ? Color.green : Color.secondary.opacity(0.4))
                        .frame(width: 8, height: 8)
                    Text(desktop.isPlaying ? "Desktop Live Active" : "Desktop Stopped")
                        .font(.caption.weight(.medium))
                    Spacer()
                    if desktop.currentVideoURL != nil {
                        Button(desktop.isPlaying ? "Pause" : "Play") {
                            desktop.togglePlayPause()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }
                }

                HStack {
                    Image(systemName: store.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Toggle("Mute Audio", isOn: $store.isMuted)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .font(.caption)
                }
            }
            .padding(12)
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
        }
    }

    private var topStatusBanner: some View {
        HStack(spacing: 12) {
            Button {
                openFilePanel()
            } label: {
                Label("Import Local 4K Video", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)

            Button {
                Task {
                    await store.generateSample4KVideo()
                }
            } label: {
                if store.isGeneratingSample {
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.small)
                        Text("Synthesizing 4K...")
                    }
                } else {
                    Label("Synthesize 4K Aurora Sample", systemImage: "wand.and.stars")
                }
            }
            .buttonStyle(.bordered)
            .disabled(store.isGeneratingSample)

            if let status = lockScreen.statusMessage {
                HStack(spacing: 6) {
                    if lockScreen.isBusy {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: lockScreen.statusIsError ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                            .foregroundStyle(lockScreen.statusIsError ? .red : .green)
                    }
                    Text(status)
                        .font(.caption)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
            }

            Spacer()

            if let saverID = store.activeScreenSaverID ?? store.activeDesktopID,
               let item = store.items.first(where: { $0.id == saverID }) {
                Button {
                    screenSaver.startScreenSaver(with: item.fileURL)
                } label: {
                    Label("Preview Screen Saver", systemImage: "play.tv")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.bar)
    }

    // MARK: - Discover 4K Cloud Catalog View

    private var discover4KCatalogView: some View {
        VStack(spacing: 0) {
            // Filter bar
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search 350+ 4K wallpapers (e.g. SpaceX, Porsche, Cyberpunk, Dubai, Aurora)...", text: $catalog.searchQuery)
                            .textFieldStyle(.plain)
                        if !catalog.searchQuery.isEmpty {
                            Button {
                                catalog.searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))

                    Picker("Source", selection: $catalog.selectedSourceFilter) {
                        ForEach(catalog.sources, id: \.self) { src in
                            Text(src).tag(src)
                        }
                    }
                    .frame(width: 210)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(catalog.categories, id: \.self) { category in
                            let isSelected = catalog.selectedCategory == category
                            Button {
                                catalog.selectedCategory = category
                            } label: {
                                Text(category)
                                    .font(.caption.weight(isSelected ? .bold : .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        isSelected ? Color.accentColor : Color.secondary.opacity(0.14),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(isSelected ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.background)

            Divider()

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 270, maximum: 350), spacing: 18)], spacing: 18) {
                    ForEach(catalog.filteredItems) { remote in
                        RemoteWallpaperCardView(remote: remote)
                    }
                }
                .padding(20)
            }
        }
    }

    // MARK: - Local Library View

    private var libraryGridView: some View {
        ScrollView {
            if store.items.isEmpty {
                emptyLibraryView
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 270, maximum: 360), spacing: 18)], spacing: 18) {
                    ForEach(store.items) { item in
                        WallpaperCardView(item: item)
                    }
                }
                .padding(20)
            }
        }
        .overlay {
            if store.isDropTargeted {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [8]))
                    .background(Color.accentColor.opacity(0.08))
                    .padding(12)
            }
        }
    }

    private var emptyLibraryView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 80)
            Image(systemName: "sparkles.tv.fill")
                .font(.system(size: 56))
                .foregroundStyle(.linearGradient(colors: [.cyan, .blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
            Text("No Local 4K Wallpapers Downloaded Yet")
                .font(.title2.bold())
            Text("Browse 350+ free 4K wallpapers in **Discover 4K Catalog**, drop any `.mp4` or `.mov` video here, or synthesize a 4K Aurora Borealis sample.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)

            HStack(spacing: 12) {
                Button {
                    store.selectedSection = .discover4K
                } label: {
                    Label("Explore 4K Cloud Catalog", systemImage: "globe.americas.fill")
                        .padding(.horizontal, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    openFilePanel()
                } label: {
                    Label("Import Local .MP4 / .MOV", systemImage: "folder.badge.plus")
                        .padding(.horizontal, 6)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var lockScreenDetailView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Native macOS Lock Screen & Aerial Injection Engine")
                        .font(.title2.bold())
                    Text("AuraDesk injects your custom 4K video directly into macOS's native `idleassetsd` Aerial pipeline and updates `com.apple.wallpaper/Store/Index.plist`. This gives you genuine 4K Lock Screen playback and smooth slow-motion wake transitions.")
                        .foregroundStyle(.secondary)
                }

                GroupBox("Target macOS Aerial Slot (`4KSDR240FPS`)") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Picker("Aerial Slot to Override:", selection: $lockScreen.selectedTargetID) {
                                ForEach(lockScreen.availableTargets) { target in
                                    Text("\(target.name) (\(target.id.prefix(8))…)" + (target.hasBackup ? " [Backed Up]" : ""))
                                        .tag(target.id)
                                }
                            }
                            .frame(maxWidth: 450)

                            Button {
                                lockScreen.refreshTargets()
                            } label: {
                                Label("Refresh Slots", systemImage: "arrow.clockwise")
                            }
                        }

                        if let currentTarget = lockScreen.availableTargets.first(where: { $0.id == lockScreen.selectedTargetID }) {
                            HStack(spacing: 16) {
                                Label(
                                    currentTarget.isDownloaded ? "Downloaded on Disk" : "Will Create Slot File",
                                    systemImage: currentTarget.isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle"
                                )
                                .foregroundStyle(currentTarget.isDownloaded ? .green : .orange)
                                .font(.caption)

                                Label(
                                    currentTarget.hasBackup ? "Original Apple Video Backed Up" : "Original Not Yet Overridden",
                                    systemImage: currentTarget.hasBackup ? "externaldrive.badge.checkmark" : "shield"
                                )
                                .foregroundStyle(.secondary)
                                .font(.caption)

                                Spacer()

                                if currentTarget.hasBackup {
                                    Button("Restore Original Apple Video") {
                                        Task {
                                            await lockScreen.restoreOriginalAerial()
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(lockScreen.isBusy)
                                }
                            }
                        }
                    }
                    .padding(10)
                }

                GroupBox("Apply a Downloaded Video to Lock Screen & Screen Saver") {
                    if store.items.isEmpty {
                        Text("Download a 4K video from Discover 4K Catalog or import a local file first.")
                            .foregroundStyle(.secondary)
                            .padding(12)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(store.items) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(.headline)
                                        Text("\(item.category) • \(item.resolution) • \(item.formattedDuration) • \(String(format: "%.1f MB", item.fileSizeMB))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if store.activeLockScreenID == item.id {
                                        Label("Active on Lock Screen", systemImage: "lock.fill")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.green)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.green.opacity(0.14), in: Capsule())
                                    }
                                    Button("Set Lock Screen & Saver") {
                                        Task {
                                            await store.setLockScreenAndAerialScreenSaver(item: item, alsoSetNativeDesktop: false)
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(lockScreen.isBusy)

                                    Button("Set All 3 (Desktop + Saver + Lock)") {
                                        Task {
                                            await store.setAllThree(item: item)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(lockScreen.isBusy)
                                }
                                .padding(8)
                                Divider()
                            }
                        }
                        .padding(6)
                    }
                }
            }
            .padding(24)
        }
    }

    private var screenSaverDetailView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("4K Screen Saver Engine")
                    .font(.title2.bold())
                Text("AuraDesk supports both macOS's native Aerial Screen Saver (when you apply a video to Lock Screen & Saver) and an instant built-in 4K Screen Saver overlay with a Sonoma-style clock.")
                    .foregroundStyle(.secondary)

                GroupBox("Built-in 4K Screen Saver Settings") {
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle("Show Sonoma-style Time & Date Overlay on Screen Saver", isOn: $screenSaver.showClockOnScreenSaver)

                        HStack {
                            Text("Auto-launch Screen Saver after idle:")
                            Slider(value: $screenSaver.idleTimeoutMinutes, in: 0...30, step: 1)
                                .frame(maxWidth: 260)
                            Text(screenSaver.idleTimeoutMinutes == 0 ? "Disabled (Use macOS Native)" : "\(Int(screenSaver.idleTimeoutMinutes)) min")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }

                        if let item = store.items.first(where: { $0.id == (store.activeScreenSaverID ?? store.activeDesktopID) }) ?? store.items.first {
                            HStack {
                                Text("Selected Video: **\(item.title)**")
                                Spacer()
                                Button {
                                    screenSaver.startScreenSaver(with: item.fileURL)
                                } label: {
                                    Label("Test Fullscreen 4K Screen Saver Now", systemImage: "play.tv.fill")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                    .padding(12)
                }
            }
            .padding(24)
        }
    }

    private var playbackSettingsView: some View {
        Form {
            Section("Desktop Video Playback") {
                Toggle("Loop Video Seamlessly", isOn: $store.loopPlayback)
                Toggle("Mute Video Audio", isOn: $store.isMuted)

                if !store.isMuted {
                    HStack {
                        Text("Audio Volume")
                        Slider(value: $store.volume, in: 0...1)
                        Text("\(Int(store.volume * 100))%")
                            .monospacedDigit()
                    }
                }

                Picker("Screen Scaling Mode", selection: $store.videoGravity) {
                    ForEach(VideoGravityMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                HStack {
                    Text("Playback Speed")
                    Slider(value: $store.playbackSpeed, in: 0.25...2.0, step: 0.25)
                    Text(String(format: "%.2fx", store.playbackSpeed))
                        .monospacedDigit()
                }
            }

            Section("Energy & Performance") {
                Toggle("Automatically Pause Desktop Video When Locked or Display Sleeps", isOn: $store.pauseOnScreenSleep)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func openFilePanel() {
        let panel = NSOpenPanel()
        panel.title = "Choose 4K Videos (.mp4, .mov, .m4v)"
        panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie, .movie]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        if panel.runModal() == .OK {
            let urls = panel.urls
            Task {
                await store.importVideoFiles(urls: urls)
                store.selectedSection = .myLibrary
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var found = false
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                found = true
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        Task { @MainActor in
                            await store.importVideoFiles(urls: [url])
                            store.selectedSection = .myLibrary
                        }
                    }
                }
            }
        }
        return found
    }
}

struct RemoteWallpaperCardView: View {
    let remote: RemoteWallpaperItem
    @ObservedObject var catalog = CloudCatalogService.shared
    @ObservedObject var store = WallpaperStore.shared

    var localDownloadedItem: WallpaperItem? {
        store.items.first(where: { $0.remoteID == remote.id })
    }

    var isDownloading: Bool {
        catalog.downloadingIDs.contains(remote.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: remote.thumbURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(height: 156)
                            .clipped()
                    default:
                        Rectangle()
                            .fill(LinearGradient(colors: [.indigo.opacity(0.55), .cyan.opacity(0.45)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 156)
                            .overlay {
                                Image(systemName: "sparkles.tv")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.white.opacity(0.75))
                            }
                    }
                }

                HStack(spacing: 4) {
                    Text(remote.category)
                        .font(.caption2.bold())
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.indigo.opacity(0.85), in: Capsule())
                        .foregroundStyle(.white)

                    Text(remote.resolution)
                        .font(.caption2.bold())
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.72), in: Capsule())
                        .foregroundStyle(.white)

                    Text(remote.formattedDuration)
                        .font(.caption2.monospacedDigit())
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.72), in: Capsule())
                        .foregroundStyle(.white)
                }
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(remote.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(String(format: "%@ • %.1f MB", remote.source, remote.fileSizeMB))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let existing = localDownloadedItem {
                HStack(spacing: 6) {
                    Button {
                        store.setDesktopWallpaper(existing)
                    } label: {
                        Label("Set Desktop", systemImage: "desktopcomputer")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button {
                        Task { await store.setAllThree(item: existing) }
                    } label: {
                        Label("Apply All 3", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            } else if isDownloading {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text(catalog.downloadStatusText[remote.id] ?? "Downloading 4K...")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 4)
            } else {
                HStack(spacing: 6) {
                    Button {
                        Task {
                            await catalog.downloadAndImport(remoteItem: remote, applyMode: .desktopOnly)
                        }
                    } label: {
                        Label("Get & Set Desktop", systemImage: "arrow.down.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button {
                        Task {
                            await catalog.downloadAndImport(remoteItem: remote, applyMode: .allThree)
                        }
                    } label: {
                        Label("All 3", systemImage: "lock.display")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Download 4K video and apply to Desktop, Screen Saver, and Lock Screen")
                }
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }
}

struct WallpaperCardView: View {
    let item: WallpaperItem
    @ObservedObject var store = WallpaperStore.shared
    @ObservedObject var lockScreen = LockScreenManager.shared

    var isDesktopActive: Bool { store.activeDesktopID == item.id }
    var isSaverActive: Bool { store.activeScreenSaverID == item.id }
    var isLockActive: Bool { store.activeLockScreenID == item.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                if let thumbURL = item.thumbnailURL,
                   let nsImg = NSImage(contentsOf: thumbURL) {
                    Image(nsImage: nsImg)
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(height: 158)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(LinearGradient(colors: [.indigo.opacity(0.6), .cyan.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 158)
                        .overlay {
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                }

                HStack(spacing: 4) {
                    Text(item.resolution)
                        .font(.caption2.bold())
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.72), in: Capsule())
                        .foregroundStyle(.white)

                    Text(item.formattedDuration)
                        .font(.caption2.monospacedDigit())
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.72), in: Capsule())
                        .foregroundStyle(.white)
                }
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(String(format: "%@ • %.1f MB • %@", item.category, item.fileSizeMB, item.fileURL.pathExtension.uppercased()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(role: .destructive) {
                    store.deleteItem(item)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Remove from Library")
            }

            HStack(spacing: 6) {
                StatusBadge(title: "Desktop", active: isDesktopActive, color: .cyan)
                StatusBadge(title: "Screen Saver", active: isSaverActive, color: .purple)
                StatusBadge(title: "Lock Screen", active: isLockActive, color: .green)
            }

            Divider()

            VStack(spacing: 6) {
                Button {
                    Task {
                        await store.setAllThree(item: item)
                    }
                } label: {
                    Label("Apply to All 3 (Desktop + Saver + Lock)", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(lockScreen.isBusy)

                HStack(spacing: 6) {
                    Button {
                        store.setDesktopWallpaper(item)
                    } label: {
                        Text("Desktop Only")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button {
                        Task {
                            await store.setLockScreenAndAerialScreenSaver(item: item)
                        }
                    } label: {
                        Text("Lock & Saver")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(lockScreen.isBusy)
                }
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    (isDesktopActive || isLockActive) ? Color.accentColor.opacity(0.75) : Color.primary.opacity(0.08),
                    lineWidth: (isDesktopActive || isLockActive) ? 2 : 1
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }
}

struct StatusBadge: View {
    let title: String
    let active: Bool
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(active ? color : Color.secondary.opacity(0.3))
                .frame(width: 6, height: 6)
            Text(title)
                .font(.system(size: 10, weight: active ? .semibold : .regular))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(active ? color.opacity(0.15) : Color.secondary.opacity(0.08), in: Capsule())
        .foregroundStyle(active ? color : .secondary)
    }
}
