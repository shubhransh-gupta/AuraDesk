import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Monochrome Black & Silver Sharp Pro Theme
public enum AuraTheme {
    public static let obsidianBlack = Color(red: 0.02, green: 0.02, blue: 0.025)
    public static let carbonBg = Color(red: 0.045, green: 0.045, blue: 0.052)
    public static let panelTop = Color(red: 0.11, green: 0.11, blue: 0.125)
    public static let panelBottom = Color(red: 0.055, green: 0.055, blue: 0.065)

    public static let chromeWhite = Color(red: 0.98, green: 0.98, blue: 0.99)
    public static let silverBright = Color(red: 0.88, green: 0.88, blue: 0.90)
    public static let silverMid = Color(red: 0.64, green: 0.64, blue: 0.68)
    public static let silverMuted = Color(red: 0.45, green: 0.45, blue: 0.49)
    public static let gunmetalBorder = Color(red: 0.20, green: 0.20, blue: 0.23)
    public static let silverEdge = Color(red: 0.52, green: 0.52, blue: 0.56)

    public static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [panelTop, panelBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    public static var chromeButtonGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.99, green: 0.99, blue: 1.0),
                Color(red: 0.82, green: 0.82, blue: 0.85),
                Color(red: 0.68, green: 0.68, blue: 0.72)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static var darkMetalGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.16, green: 0.16, blue: 0.18),
                Color(red: 0.08, green: 0.08, blue: 0.095)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    public static var sharpBorderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.32),
                Color.white.opacity(0.10),
                Color.white.opacity(0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct SharpSilverCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 8
    var isHighlighted: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AuraTheme.cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isHighlighted
                            ? LinearGradient(
                                colors: [AuraTheme.chromeWhite, AuraTheme.silverMid],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : AuraTheme.sharpBorderGradient,
                        lineWidth: isHighlighted ? 1.5 : 1.0
                    )
            )
            .shadow(color: .black.opacity(0.65), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func sharpSilverCard(cornerRadius: CGFloat = 8, isHighlighted: Bool = false) -> some View {
        modifier(SharpSilverCardModifier(cornerRadius: cornerRadius, isHighlighted: isHighlighted))
    }
}

struct SharpSilverButtonStyle: ButtonStyle {
    var prominent: Bool = false
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 11 : 12, weight: .semibold))
            .foregroundStyle(prominent ? Color.black : AuraTheme.silverBright)
            .padding(.horizontal, compact ? 10 : 14)
            .padding(.vertical, compact ? 6 : 8)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(prominent ? AuraTheme.chromeButtonGradient : AuraTheme.darkMetalGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(
                        prominent
                            ? Color.white.opacity(0.9)
                            : Color.white.opacity(0.22),
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

// MARK: - Remote Authenticated Thumbnail View
struct Remote4KThumbnailView: View {
    let item: RemoteWallpaperItem
    @ObservedObject var catalog = CloudCatalogService.shared

    var body: some View {
        ZStack {
            // Precision dark metallic fallback backdrop
            LinearGradient(
                colors: [
                    Color(red: 0.13, green: 0.13, blue: 0.15),
                    Color(red: 0.05, green: 0.05, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle architectural grid lines
            GeometryReader { geo in
                Path { path in
                    let step: CGFloat = 28
                    var x: CGFloat = 0
                    while x < geo.size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                        x += step
                    }
                    var y: CGFloat = 0
                    while y < geo.size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                        y += step
                    }
                }
                .stroke(Color.white.opacity(0.035), lineWidth: 0.5)
            }

            if let nsImg = catalog.loadedThumbnails[item.id] {
                Image(nsImage: nsImg)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(AuraTheme.silverMid)
                    Text(item.resolution)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(AuraTheme.silverMuted)
                }
            }

            // Bottom dark gradient vignette for badge legibility
            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .clipped()
        .onAppear {
            catalog.requestThumbnailIfNeeded(for: item)
        }
    }
}

// MARK: - Main ContentView
public struct ContentView: View {
    @ObservedObject private var store = WallpaperStore.shared
    @ObservedObject private var desktopController = DesktopWallpaperController.shared
    @ObservedObject private var lockScreenManager = LockScreenManager.shared
    @ObservedObject private var screenSaverController = ScreenSaverController.shared
    @ObservedObject private var catalogService = CloudCatalogService.shared

    public enum SidebarSection: String, CaseIterable, Identifiable {
        case discover4K = "Top 4K Wallpapers"
        case myLibrary = "Downloaded & Local"
        case lockScreenEngine = "Lock Screen Engine"
        case settings = "Display & Power"

        public var id: String { rawValue }

        var icon: String {
            switch self {
            case .discover4K: return "sparkles.tv.fill"
            case .myLibrary: return "film.stack.fill"
            case .lockScreenEngine: return "lock.desktopcomputer"
            case .settings: return "slider.horizontal.3"
            }
        }

        var subtitle: String {
            switch self {
            case .discover4K: return "350+ Built-In 4K Videos"
            case .myLibrary: return "Ready on Disk"
            case .lockScreenEngine: return "Native macOS Aerials"
            case .settings: return "GPU & Multi-Monitor"
            }
        }
    }

    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            // LEFT SIDEBAR (Pro macOS App Sidebar)
            sidebarView
                .frame(width: 236)
                .background(AuraTheme.obsidianBlack)

            Rectangle()
                .fill(AuraTheme.gunmetalBorder)
                .frame(width: 1)

            // MAIN WORKSPACE
            VStack(spacing: 0) {
                topWorkspaceToolbar

                Rectangle()
                    .fill(AuraTheme.gunmetalBorder)
                    .frame(height: 1)

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 24) {
                        switch store.selectedSection {
                        case .discover4K:
                            top4KWallpapersWorkspace
                        case .myLibrary:
                            downloadedAndLocalWorkspace
                        case .lockScreenEngine:
                            lockScreenEngineWorkspace
                        case .settings:
                            settingsWorkspace
                        }
                    }
                    .padding(24)
                }

                Rectangle()
                    .fill(AuraTheme.gunmetalBorder)
                    .frame(height: 1)

                bottomStatusFooterBar
            }
            .background(AuraTheme.carbonBg)
        }
        .preferredColorScheme(.dark)
        .onDrop(of: [.fileURL], isTargeted: $store.isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    // MARK: - Left Pro Sidebar
    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App Brand Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(AuraTheme.chromeButtonGradient)
                        .frame(width: 32, height: 32)
                    Image(systemName: "play.display")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.black)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("AURADESK")
                            .font(.system(size: 14, weight: .heavy, design: .default))
                            .tracking(1.2)
                            .foregroundStyle(AuraTheme.chromeWhite)

                        Text("PRO")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(AuraTheme.silverBright, in: RoundedRectangle(cornerRadius: 3))
                    }
                    Text("4K Desktop • Saver • Lock")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AuraTheme.silverMuted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)

            Rectangle()
                .fill(AuraTheme.gunmetalBorder)
                .frame(height: 1)

            // Navigation Items
            VStack(alignment: .leading, spacing: 4) {
                Text("WORKSPACE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(AuraTheme.silverMuted)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)

                ForEach(SidebarSection.allCases) { section in
                    let isSelected = store.selectedSection == section
                    Button {
                        store.selectedSection = section
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: section.icon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(isSelected ? .black : AuraTheme.silverMid)
                                .frame(width: 22)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(section.rawValue)
                                    .font(.system(size: 12.5, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(isSelected ? .black : AuraTheme.chromeWhite)
                                Text(section.subtitle)
                                    .font(.system(size: 10))
                                    .foregroundStyle(isSelected ? .black.opacity(0.65) : AuraTheme.silverMuted)
                            }
                            Spacer()

                            if section == .discover4K {
                                Text("\(catalogService.allRemoteItems.count)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(isSelected ? .black : AuraTheme.silverBright)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(isSelected ? Color.black.opacity(0.15) : Color.white.opacity(0.08))
                                    )
                            } else if section == .myLibrary {
                                Text("\(store.items.count)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(isSelected ? .black : AuraTheme.silverBright)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(isSelected ? Color.black.opacity(0.15) : Color.white.opacity(0.08))
                                    )
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(
                                    isSelected
                                        ? AnyShapeStyle(AuraTheme.chromeButtonGradient)
                                        : AnyShapeStyle(Color.clear)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)

            Spacer()

            // Active Output Status Box
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("ACTIVE TARGETS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.1)
                        .foregroundStyle(AuraTheme.silverMid)
                    Spacer()
                    Circle()
                        .fill(desktopController.isPlaying ? AuraTheme.chromeWhite : AuraTheme.silverMuted)
                        .frame(width: 6, height: 6)
                }

                sidebarTargetRow(
                    label: "DESKTOP",
                    value: activeTitle(for: store.activeDesktopID) ?? "Idle"
                )
                sidebarTargetRow(
                    label: "SAVER",
                    value: activeTitle(for: store.activeScreenSaverID) ?? "Idle"
                )
                sidebarTargetRow(
                    label: "LOCK",
                    value: activeTitle(for: store.activeLockScreenID) ?? "System Default"
                )

                HStack(spacing: 6) {
                    Button {
                        desktopController.togglePlayPause()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: desktopController.isPlaying ? "pause.fill" : "play.fill")
                            Text(desktopController.isPlaying ? "Pause" : "Resume")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SharpSilverButtonStyle(prominent: false, compact: true))

                    Button {
                        if let item = store.items.first(where: { $0.id == (store.activeScreenSaverID ?? store.activeDesktopID) }) ?? store.items.first {
                            screenSaverController.startScreenSaver(with: item.fileURL)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles.tv")
                            Text("Saver")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SharpSilverButtonStyle(prominent: false, compact: true))
                }
                .padding(.top, 2)
            }
            .padding(12)
            .sharpSilverCard(cornerRadius: 8)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)

            // Secondary Custom Video / Synthesizer Tools
            VStack(spacing: 6) {
                Button {
                    Task { await store.generateSample4KVideo() }
                } label: {
                    HStack(spacing: 6) {
                        if store.isGeneratingSample {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "wand.and.stars")
                        }
                        Text(store.isGeneratingSample ? "Rendering 4K..." : "Generate 4K Silver Sample")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(SharpSilverButtonStyle(prominent: false, compact: true))
                .disabled(store.isGeneratingSample)

                Button {
                    openFilePanel()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.badge.plus")
                        Text("Import Local Video...")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(SharpSilverButtonStyle(prominent: false, compact: true))
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
        }
    }

    private func sidebarTargetRow(label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(AuraTheme.silverMuted)
                .frame(width: 52, alignment: .leading)
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AuraTheme.silverBright)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Top Workspace Command Toolbar
    private var topWorkspaceToolbar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(store.selectedSection.rawValue.uppercased())
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(0.8)
                    .foregroundStyle(AuraTheme.chromeWhite)
                Text("Select any 4K wallpaper below to apply directly to Desktop, Screen Saver, or Lock Screen")
                    .font(.system(size: 11))
                    .foregroundStyle(AuraTheme.silverMuted)
            }

            Spacer()

            // Search Box
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(AuraTheme.silverMid)
                TextField("Search 350+ 4K wallpapers...", text: $catalogService.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(AuraTheme.chromeWhite)
                    .frame(width: 200)
                if !catalogService.searchQuery.isEmpty {
                    Button {
                        catalogService.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AuraTheme.silverMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(AuraTheme.obsidianBlack)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(AuraTheme.gunmetalBorder, lineWidth: 1)
            )

            // Mute Toggle
            Button {
                store.isMuted.toggle()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: store.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    Text(store.isMuted ? "Muted" : "Audio On")
                }
            }
            .buttonStyle(SharpSilverButtonStyle(prominent: false, compact: true))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(AuraTheme.obsidianBlack.opacity(0.85))
    }

    // MARK: - 1. TOP 4K WALLPAPERS WORKSPACE (Default View)
    private var top4KWallpapersWorkspace: some View {
        VStack(alignment: .leading, spacing: 24) {
            // A. INSTANT-READY 4K WALLPAPERS ON DISK (Zero Download Wait!)
            if !store.items.isEmpty && catalogService.searchQuery.isEmpty && catalogService.selectedCategory == "All" {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(AuraTheme.chromeWhite)
                                .frame(width: 3, height: 14)
                            Text("READY TO APPLY • INSTANT 4K WALLPAPERS")
                                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                .tracking(1.0)
                                .foregroundStyle(AuraTheme.chromeWhite)
                        }
                        Spacer()
                        Text("\(store.items.count) READY ON MAC")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(AuraTheme.silverMid)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(store.items.prefix(6)) { item in
                                instantLocalWallpaperCard(item)
                                    .frame(width: 300)
                            }
                        }
                    }
                }
            }

            // B. TOP FEATURED 4K WALLPAPERS ROW (Right at the top!)
            if catalogService.searchQuery.isEmpty && catalogService.selectedCategory == "All" {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(AuraTheme.chromeWhite)
                                .frame(width: 3, height: 14)
                            Text("OUR TOP 4K WALLPAPERS • FEATURED CURATION")
                                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                .tracking(1.0)
                                .foregroundStyle(AuraTheme.chromeWhite)
                        }
                        Spacer()
                        Text("1-CLICK DOWNLOAD & APPLY TO ALL 3")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(AuraTheme.silverMid)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(catalogService.topFeaturedItems.prefix(8)) { remoteItem in
                                featuredTop4KCard(remoteItem)
                                    .frame(width: 330)
                            }
                        }
                    }
                }
            }

            // C. CATEGORY & SOURCE FILTER BAR
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(AuraTheme.silverBright)
                            .frame(width: 3, height: 14)
                        Text("ALL 4K ULTRA HD CATALOG (\(catalogService.filteredItems.count))")
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .tracking(1.0)
                            .foregroundStyle(AuraTheme.chromeWhite)
                    }

                    Spacer()

                    // Source Filter Buttons
                    HStack(spacing: 4) {
                        ForEach(catalogService.sources, id: \.self) { src in
                            let active = catalogService.selectedSourceFilter == src
                            Button {
                                catalogService.selectedSourceFilter = src
                            } label: {
                                Text(src.uppercased())
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(active ? .black : AuraTheme.silverMid)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(active ? AnyShapeStyle(AuraTheme.chromeButtonGradient) : AnyShapeStyle(AuraTheme.obsidianBlack))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .strokeBorder(active ? Color.white : AuraTheme.gunmetalBorder, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Category Filter Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(catalogService.categories, id: \.self) { cat in
                            let selected = catalogService.selectedCategory == cat
                            Button {
                                catalogService.selectedCategory = cat
                            } label: {
                                Text(cat.uppercased())
                                    .font(.system(size: 10.5, weight: selected ? .heavy : .semibold, design: .monospaced))
                                    .foregroundStyle(selected ? .black : AuraTheme.silverBright)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .fill(selected ? AnyShapeStyle(AuraTheme.chromeButtonGradient) : AnyShapeStyle(AuraTheme.darkMetalGradient))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .strokeBorder(selected ? Color.white : AuraTheme.gunmetalBorder, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // D. 4K WALLPAPER GRID
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 275, maximum: 360), spacing: 16)],
                spacing: 16
            ) {
                ForEach(catalogService.filteredItems) { remoteItem in
                    remote4KCatalogCard(remoteItem)
                }
            }
        }
    }

    // MARK: - Featured Top 4K Card (Hero Row at Top)
    private func featuredTop4KCard(_ item: RemoteWallpaperItem) -> some View {
        let isDownloading = catalogService.downloadingIDs.contains(item.id)
        let localMatch = store.items.first(where: { $0.remoteID == item.id })
        let isDesktopActive = localMatch != nil && store.activeDesktopID == localMatch?.id

        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                Remote4KThumbnailView(item: item)
                    .frame(height: 176)

                HStack {
                    Text("TOP 4K • \(item.category.uppercased())")
                        .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(AuraTheme.chromeButtonGradient, in: RoundedRectangle(cornerRadius: 4))

                    Spacer()

                    if isDesktopActive {
                        Text("ACTIVE")
                            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 4))
                    } else if localMatch != nil {
                        Text("READY")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(AuraTheme.chromeWhite)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(Color.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 4))
                            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
                    } else {
                        Text("4K UHD")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(AuraTheme.silverBright)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(Color.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 4))
                            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
                    }
                }
                .padding(10)
            }

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(AuraTheme.chromeWhite)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(item.resolution)
                        Text("•")
                        Text(String(format: "%.0f MB", item.fileSizeMB))
                        Text("•")
                        Text(item.source)
                    }
                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(AuraTheme.silverMuted)
                    .lineLimit(1)
                }

                if let status = catalogService.downloadStatusText[item.id] {
                    HStack(spacing: 6) {
                        if isDownloading {
                            ProgressView().controlSize(.small)
                        }
                        Text(status)
                            .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                            .foregroundStyle(AuraTheme.silverBright)
                            .lineLimit(1)
                    }
                }

                // 1-Click Apply Bar
                HStack(spacing: 6) {
                    Button {
                        Task {
                            await catalogService.downloadAndImport(remoteItem: item, applyMode: .allThree)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                            Text(isDownloading ? "Applying..." : "Apply All 3")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SharpSilverButtonStyle(prominent: true, compact: true))
                    .disabled(isDownloading)

                    Button {
                        Task {
                            await catalogService.downloadAndImport(remoteItem: item, applyMode: .desktopOnly)
                        }
                    } label: {
                        Text("Desktop")
                    }
                    .buttonStyle(SharpSilverButtonStyle(prominent: false, compact: true))
                    .disabled(isDownloading)

                    Button {
                        Task {
                            await catalogService.downloadAndImport(remoteItem: item, applyMode: .lockScreenOnly)
                        }
                    } label: {
                        Text("Lock")
                    }
                    .buttonStyle(SharpSilverButtonStyle(prominent: false, compact: true))
                    .disabled(isDownloading)
                }
            }
            .padding(12)
        }
        .sharpSilverCard(cornerRadius: 8, isHighlighted: isDesktopActive)
    }

    // MARK: - Standard 4K Catalog Grid Card
    private func remote4KCatalogCard(_ item: RemoteWallpaperItem) -> some View {
        let isDownloading = catalogService.downloadingIDs.contains(item.id)
        let localMatch = store.items.first(where: { $0.remoteID == item.id })
        let isDesktopActive = localMatch != nil && store.activeDesktopID == localMatch?.id

        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                Remote4KThumbnailView(item: item)
                    .frame(height: 152)

                HStack {
                    Text(item.category.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(AuraTheme.chromeWhite)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.white.opacity(0.22), lineWidth: 1))

                    Spacer()

                    if localMatch != nil {
                        Text("READY")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AuraTheme.silverBright, in: RoundedRectangle(cornerRadius: 4))
                    } else {
                        Text("4K")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(AuraTheme.silverBright)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 4))
                    }
                }
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 9) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(AuraTheme.chromeWhite)
                        .lineLimit(1)

                    Text("\(item.resolution) • \(String(format: "%.0f MB", item.fileSizeMB)) • \(Int(item.durationSeconds))s")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(AuraTheme.silverMuted)
                        .lineLimit(1)
                }

                if let status = catalogService.downloadStatusText[item.id] {
                    HStack(spacing: 6) {
                        if isDownloading {
                            ProgressView().controlSize(.small)
                        }
                        Text(status)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(AuraTheme.silverBright)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 5) {
                    Button {
                        Task {
                            await catalogService.downloadAndImport(remoteItem: item, applyMode: .allThree)
                        }
                    } label: {
                        Text(isDownloading ? "Wait..." : "Apply All 3")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SharpSilverButtonStyle(prominent: true, compact: true))
                    .disabled(isDownloading)

                    Button {
                        Task {
                            await catalogService.downloadAndImport(remoteItem: item, applyMode: .desktopOnly)
                        }
                    } label: {
                        Text("Desk")
                    }
                    .buttonStyle(SharpSilverButtonStyle(prominent: false, compact: true))
                    .disabled(isDownloading)

                    Button {
                        Task {
                            await catalogService.downloadAndImport(remoteItem: item, applyMode: .screenSaverOnly)
                        }
                    } label: {
                        Text("Saver")
                    }
                    .buttonStyle(SharpSilverButtonStyle(prominent: false, compact: true))
                    .disabled(isDownloading)

                    Button {
                        Task {
                            await catalogService.downloadAndImport(remoteItem: item, applyMode: .lockScreenOnly)
                        }
                    } label: {
                        Text("Lock")
                    }
                    .buttonStyle(SharpSilverButtonStyle(prominent: false, compact: true))
                    .disabled(isDownloading)
                }
            }
            .padding(11)
        }
        .sharpSilverCard(cornerRadius: 8, isHighlighted: isDesktopActive)
    }

    // MARK: - Instant Local Wallpaper Card
    private func instantLocalWallpaperCard(_ item: WallpaperItem) -> some View {
        let isDesktop = store.activeDesktopID == item.id
        let isSaver = store.activeScreenSaverID == item.id
        let isLock = store.activeLockScreenID == item.id

        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                ZStack {
                    AuraTheme.obsidianBlack
                    if let thumbURL = item.thumbnailURL,
                       let nsImg = NSImage(contentsOf: thumbURL) {
                        Image(nsImage: nsImg)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "film.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(AuraTheme.silverMid)
                    }
                    LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .center, endPoint: .bottom)
                }
                .frame(height: 145)
                .clipped()

                HStack(spacing: 4) {
                    Text(item.resolution)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(AuraTheme.chromeWhite, in: RoundedRectangle(cornerRadius: 3))

                    Spacer()

                    if isDesktop {
                        statusChip("DESK")
                    }
                    if isSaver {
                        statusChip("SAVER")
                    }
                    if isLock {
                        statusChip("LOCK")
                    }
                }
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(AuraTheme.chromeWhite)
                            .lineLimit(1)
                        Text("\(String(format: "%.1f MB", item.fileSizeMB)) • \(item.category)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(AuraTheme.silverMuted)
                    }
                    Spacer()
                    Button {
                        store.deleteItem(item)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(AuraTheme.silverMuted)
                    }
                    .buttonStyle(.plain)
                    .help("Remove from library")
                }

                HStack(spacing: 5) {
                    Button {
                        Task { await store.setAllThree(item: item) }
                    } label: {
                        Text("Apply All 3")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SharpSilverButtonStyle(prominent: true, compact: true))

                    Button {
                        store.setDesktopWallpaper(item)
                    } label: {
                        Text("Desk")
                    }
                    .buttonStyle(SharpSilverButtonStyle(prominent: isDesktop, compact: true))

                    Button {
                        store.setScreenSaverWallpaper(item)
                    } label: {
                        Text("Saver")
                    }
                    .buttonStyle(SharpSilverButtonStyle(prominent: isSaver, compact: true))

                    Button {
                        Task { await store.setLockScreenAndAerialScreenSaver(item: item, alsoSetNativeDesktop: false) }
                    } label: {
                        Text("Lock")
                    }
                    .buttonStyle(SharpSilverButtonStyle(prominent: isLock, compact: true))
                }
            }
            .padding(11)
        }
        .sharpSilverCard(cornerRadius: 8, isHighlighted: isDesktop || isLock)
    }

    private func statusChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
            .foregroundStyle(.black)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(AuraTheme.silverBright, in: RoundedRectangle(cornerRadius: 3))
    }

    // MARK: - 2. DOWNLOADED & LOCAL LIBRARY WORKSPACE
    private var downloadedAndLocalWorkspace: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DOWNLOADED & LOCAL 4K LIBRARY")
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundStyle(AuraTheme.chromeWhite)
                    Text("All 4K wallpapers downloaded from the AuraDesk catalog or imported from disk.")
                        .font(.system(size: 12))
                        .foregroundStyle(AuraTheme.silverMid)
                }
                Spacer()
                Button {
                    store.selectedSection = .discover4K
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles.tv.fill")
                        Text("Browse 350+ 4K Catalog")
                    }
                }
                .buttonStyle(SharpSilverButtonStyle(prominent: true))

                Button {
                    openFilePanel()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Import Video")
                    }
                }
                .buttonStyle(SharpSilverButtonStyle(prominent: false))
            }
            .padding(16)
            .sharpSilverCard(cornerRadius: 8)

            if store.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(AuraTheme.silverMid)
                    Text("No Local 4K Videos Yet")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AuraTheme.chromeWhite)
                    Text("Pick any wallpaper from Top 4K Wallpapers to download & apply in one click.")
                        .font(.system(size: 12))
                        .foregroundStyle(AuraTheme.silverMuted)
                    Button("Go to Top 4K Wallpapers") {
                        store.selectedSection = .discover4K
                    }
                    .buttonStyle(SharpSilverButtonStyle(prominent: true))
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .sharpSilverCard(cornerRadius: 8)
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 280, maximum: 360), spacing: 16)],
                    spacing: 16
                ) {
                    ForEach(store.items) { item in
                        instantLocalWallpaperCard(item)
                    }
                }
            }
        }
    }

    // MARK: - 3. LOCK SCREEN ENGINE WORKSPACE
    private var lockScreenEngineWorkspace: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text("NATIVE MACOS LOCK SCREEN & AERIAL ENGINE")
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .foregroundStyle(AuraTheme.chromeWhite)
                        Text("IDLEASSETSD")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AuraTheme.silverBright, in: RoundedRectangle(cornerRadius: 3))
                    }

                    Text("AuraDesk injects your chosen 4K video directly into macOS Sonoma / Sequoia / Tahoe's native Aerial pipeline with automatic original asset backup and 1-click restoration.")
                        .font(.system(size: 12))
                        .foregroundStyle(AuraTheme.silverMid)
                        .lineSpacing(3)

                    HStack(spacing: 10) {
                        Text("Status:")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(AuraTheme.silverMuted)
                        Text(lockScreenManager.statusMessage ?? "Native Lock Screen Engine Ready")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(AuraTheme.chromeWhite)
                    }
                    .padding(.top, 4)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Button {
                        Task { await lockScreenManager.restoreOriginalAerial() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Restore Original Apple Lock Screen")
                        }
                    }
                    .buttonStyle(SharpSilverButtonStyle(prominent: false))
                    .disabled(lockScreenManager.isBusy)

                    Button {
                        lockScreenManager.refreshTargets()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Rescan macOS Aerial Slots")
                        }
                    }
                    .buttonStyle(SharpSilverButtonStyle(prominent: false, compact: true))
                }
            }
            .padding(18)
            .sharpSilverCard(cornerRadius: 8)

            // Quick Apply from Ready 4K Videos
            VStack(alignment: .leading, spacing: 12) {
                Text("SELECT A READY 4K VIDEO TO INJECT INTO LOCK SCREEN")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(AuraTheme.silverBright)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 280, maximum: 360), spacing: 16)],
                    spacing: 16
                ) {
                    ForEach(store.items) { item in
                        instantLocalWallpaperCard(item)
                    }
                }
            }
        }
    }

    // MARK: - 4. DISPLAY & POWER SETTINGS WORKSPACE
    private var settingsWorkspace: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DISPLAY, PLAYBACK & POWER ENGINE")
                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                .foregroundStyle(AuraTheme.chromeWhite)

            HStack(alignment: .top, spacing: 16) {
                // Playback & Audio Card
                VStack(alignment: .leading, spacing: 14) {
                    Text("VIDEO SCALING & AUDIO")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(AuraTheme.silverMid)

                    HStack {
                        Text("Scaling Mode")
                            .font(.system(size: 12))
                            .foregroundStyle(AuraTheme.silverBright)
                        Spacer()
                        Picker("", selection: $store.videoGravity) {
                            ForEach(VideoGravityMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 220)
                    }

                    Toggle("Mute Desktop Wallpaper Audio", isOn: $store.isMuted)
                        .font(.system(size: 12))
                        .foregroundStyle(AuraTheme.silverBright)

                    if !store.isMuted {
                        HStack {
                            Text("Audio Volume")
                                .font(.system(size: 12))
                                .foregroundStyle(AuraTheme.silverBright)
                            Slider(value: $store.volume, in: 0...1)
                        }
                    }

                    HStack {
                        Text("Playback Speed (\(String(format: "%.2fx", store.playbackSpeed)))")
                            .font(.system(size: 12))
                            .foregroundStyle(AuraTheme.silverBright)
                        Spacer()
                        Slider(value: $store.playbackSpeed, in: 0.5...2.0, step: 0.25)
                            .frame(width: 180)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .sharpSilverCard(cornerRadius: 8)

                // Power & Screen Saver Card
                VStack(alignment: .leading, spacing: 14) {
                    Text("ZERO-DRAIN POWER & SCREEN SAVER")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(AuraTheme.silverMid)

                    Toggle("Auto-Pause When Display Sleeps or Locks", isOn: $store.pauseOnScreenSleep)
                        .font(.system(size: 12))
                        .foregroundStyle(AuraTheme.silverBright)

                    Toggle("Show Sonoma-Style Clock on Screen Saver", isOn: $screenSaverController.showClockOnScreenSaver)
                        .font(.system(size: 12))
                        .foregroundStyle(AuraTheme.silverBright)

                    HStack {
                        Text("Idle Screen Saver Timeout (\(Int(screenSaverController.idleTimeoutMinutes)) min)")
                            .font(.system(size: 12))
                            .foregroundStyle(AuraTheme.silverBright)
                        Spacer()
                        Slider(value: $screenSaverController.idleTimeoutMinutes, in: 0...30, step: 1)
                            .frame(width: 180)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .sharpSilverCard(cornerRadius: 8)
            }
        }
    }

    // MARK: - Bottom Status Footer Bar
    private var bottomStatusFooterBar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Circle()
                    .fill(desktopController.isPlaying ? AuraTheme.chromeWhite : AuraTheme.silverMuted)
                    .frame(width: 7, height: 7)
                Text(desktopController.isPlaying ? "4K ENGINE RUNNING" : "ENGINE STANDBY")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(AuraTheme.silverBright)
            }

            Text("•")
                .foregroundStyle(AuraTheme.silverMuted)

            Text("Catalog: \(catalogService.allRemoteItems.count) 4K Videos")
                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                .foregroundStyle(AuraTheme.silverMid)

            Text("•")
                .foregroundStyle(AuraTheme.silverMuted)

            Text("Local Ready: \(store.items.count)")
                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                .foregroundStyle(AuraTheme.silverMid)

            Spacer()

            Text(lockScreenManager.statusMessage ?? "4K Engine Ready")
                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                .foregroundStyle(AuraTheme.silverMuted)
                .lineLimit(1)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(AuraTheme.obsidianBlack)
    }

    // MARK: - Helpers
    private func activeTitle(for id: UUID?) -> String? {
        guard let id = id else { return nil }
        return store.items.first(where: { $0.id == id })?.title
    }

    private func openFilePanel() {
        let panel = NSOpenPanel()
        panel.title = "Select 4K Video Wallpaper (.mp4, .mov, .m4v)"
        panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie, .movie]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            let urls = panel.urls
            Task {
                await store.importVideoFiles(urls: urls)
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
                        }
                    }
                }
            }
        }
        return found
    }
}
