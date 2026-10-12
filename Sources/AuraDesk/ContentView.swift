import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Figma Dark Botanical Forest Theme Tokens (#171E15)

public enum AuraTheme {
    public static let forestBg = Color(red: 0.090, green: 0.118, blue: 0.082)       // #171E15
    public static let forestDeep = Color(red: 0.067, green: 0.086, blue: 0.059)     // #11160F
    public static let emeraldGlow = Color(red: 0.220, green: 0.720, blue: 0.420)
    public static let mintAccent = Color(red: 0.655, green: 0.953, blue: 0.816)     // #A7F3D0
    public static let glassTop = Color.white.opacity(0.095)
    public static let glassBottom = Color.white.opacity(0.025)
    public static let glassStroke = Color.white.opacity(0.22)

    @MainActor
    public static func load3DAsset(_ name: String) -> NSImage? {
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        let execDir = Bundle.main.bundleURL
        let candidates = [
            execDir.appendingPathComponent("Contents/Resources/\(name).png"),
            execDir.appendingPathComponent("AuraDesk_AuraDesk.bundle/\(name).png"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Sources/AuraDesk/Resources/\(name).png"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("docs/assets/\(name).png")
        ]
        for c in candidates where FileManager.default.fileExists(atPath: c.path) {
            if let img = NSImage(contentsOf: c) {
                return img
            }
        }
        return nil
    }
}

// MARK: - Figma Custom View Modifiers & Components

struct FigmaGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 38
    var isHighlighted: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isHighlighted ? 0.14 : 0.09),
                                Color.white.opacity(isHighlighted ? 0.05 : 0.025)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        .ultraThinMaterial.opacity(0.45),
                        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: isHighlighted
                                ? [AuraTheme.mintAccent.opacity(0.75), AuraTheme.emeraldGlow.opacity(0.35)]
                                : [Color.white.opacity(0.28), Color.white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHighlighted ? 2.0 : 1.3
                    )
            )
            .shadow(color: Color.black.opacity(0.55), radius: 22, x: 0, y: 14)
    }
}

extension View {
    func figmaGlassCard(cornerRadius: CGFloat = 38, isHighlighted: Bool = false) -> some View {
        modifier(FigmaGlassCardModifier(cornerRadius: cornerRadius, isHighlighted: isHighlighted))
    }
}

/// Figma Section Title with Top-Right and Bottom-Left Emerald Corner Brackets: `[ Our Trendy Surfaces ]`
struct FigmaBracketTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 22, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .overlay(alignment: .topTrailing) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 14, y: 0))
                    path.addArc(
                        center: CGPoint(x: 14, y: 8),
                        radius: 8,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(0),
                        clockwise: false
                    )
                    path.addLine(to: CGPoint(x: 22, y: 22))
                }
                .stroke(AuraTheme.mintAccent.opacity(0.8), lineWidth: 2.2)
                .frame(width: 22, height: 22)
            }
            .overlay(alignment: .bottomLeading) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: 14))
                    path.addArc(
                        center: CGPoint(x: 8, y: 14),
                        radius: 8,
                        startAngle: .degrees(180),
                        endAngle: .degrees(90),
                        clockwise: true
                    )
                    path.addLine(to: CGPoint(x: 22, y: 22))
                }
                .stroke(AuraTheme.mintAccent.opacity(0.8), lineWidth: 2.2)
                .frame(width: 22, height: 22)
            }
    }
}

/// Figma Pill Outline Button (`1.5px solid rgba(255,255,255,0.65)`, `cornerRadius: 12`)
struct FigmaOutlineButtonStyle: ButtonStyle {
    var prominent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundStyle(prominent ? Color(red: 0.06, green: 0.09, blue: 0.05) : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        prominent
                            ? AuraTheme.mintAccent.opacity(configuration.isPressed ? 0.75 : 0.95)
                            : Color.white.opacity(configuration.isPressed ? 0.18 : 0.05)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        prominent ? AuraTheme.mintAccent : Color.white.opacity(0.65),
                        lineWidth: 1.4
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Main ContentView Matching Marketing Website

public struct ContentView: View {
    @ObservedObject var store = WallpaperStore.shared
    @ObservedObject var catalog = CloudCatalogService.shared
    @ObservedObject var desktop = DesktopWallpaperController.shared
    @ObservedObject var lockScreen = LockScreenManager.shared
    @ObservedObject var screenSaver = ScreenSaverController.shared

    public enum SidebarSection: String, CaseIterable, Identifiable {
        case discover4K = "Home & 4K Catalog"
        case myLibrary = "My Downloaded Library"
        case lockScreen = "Lock Screen & Aerial"
        case screenSaver = "Screen Saver Engine"
        case settings = "Playback & Energy"

        public var id: String { rawValue }

        public var icon: String {
            switch self {
            case .discover4K: return "sparkles.tv.fill"
            case .myLibrary: return "film.stack.fill"
            case .lockScreen: return "lock.display"
            case .screenSaver: return "play.tv.fill"
            case .settings: return "slider.horizontal.3"
            }
        }

        public var asset3DName: String {
            switch self {
            case .discover4K: return "mac-cloud"
            case .myLibrary: return "mac-desktop"
            case .lockScreen: return "mac-lockscreen"
            case .screenSaver: return "mac-screensaver"
            case .settings: return "mac-mchip"
            }
        }
    }

    public init() {}

    public var body: some View {
        ZStack {
            // Deep Botanical Forest Background with Radial Emerald Glows (Matches Figma `#171E15`)
            AuraTheme.forestBg
                .ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(AuraTheme.emeraldGlow.opacity(0.18))
                        .frame(width: 560, height: 560)
                        .blur(radius: 110)
                        .position(x: geo.size.width * 0.48, y: 140)

                    Circle()
                        .fill(AuraTheme.emeraldGlow.opacity(0.12))
                        .frame(width: 480, height: 480)
                        .blur(radius: 100)
                        .position(x: geo.size.width * 0.82, y: geo.size.height * 0.65)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                figmaTopNavigationBar
                Divider().overlay(Color.white.opacity(0.1))

                Group {
                    switch store.selectedSection {
                    case .discover4K:
                        figmaHomeAndCatalogScrollView
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
        .preferredColorScheme(.dark)
        .frame(minWidth: 1100, minHeight: 740)
        .onDrop(of: [.fileURL], isTargeted: $store.isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    // MARK: - Top Navigation Bar (Matches Figma Top Header)

    private var figmaTopNavigationBar: some View {
        HStack(spacing: 20) {
            // Left Logo + Brand Name "AuraDesk."
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AuraTheme.emeraldGlow.opacity(0.22))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(AuraTheme.mintAccent.opacity(0.55), lineWidth: 1.2)
                        )
                        .frame(width: 34, height: 34)
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AuraTheme.mintAccent)
                }
                Text("AuraDesk.")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Spacer()

            // Center Navigation Pills (Matching Figma Header Links)
            HStack(spacing: 6) {
                ForEach(SidebarSection.allCases) { section in
                    let isSelected = store.selectedSection == section
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            store.selectedSection = section
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: section.icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(section.rawValue)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            if section == .myLibrary && !store.items.isEmpty {
                                Text("\(store.items.count)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.black.opacity(0.35), in: Capsule())
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.14) : Color.clear)
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    isSelected ? AuraTheme.mintAccent.opacity(0.6) : Color.clear,
                                    lineWidth: 1.2
                                )
                        )
                        .foregroundStyle(isSelected ? .white : Color.white.opacity(0.72))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            // Right Live Status & Quick Actions
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(desktop.isPlaying ? AuraTheme.mintAccent : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text(desktop.isPlaying ? "4K Live" : "Idle")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    if desktop.currentVideoURL != nil {
                        Button(desktop.isPlaying ? "Pause" : "Play") {
                            desktop.togglePlayPause()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AuraTheme.mintAccent)
                        .padding(.leading, 4)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.06), in: Capsule())
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 1))

                Button {
                    store.isMuted.toggle()
                } label: {
                    Image(systemName: store.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(store.isMuted ? .white.opacity(0.65) : AuraTheme.mintAccent)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.06), in: Circle())
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help(store.isMuted ? "Unmute Desktop Audio" : "Mute Desktop Audio")

                Button {
                    openFilePanel()
                } label: {
                    Label("Import 4K", systemImage: "plus")
                }
                .buttonStyle(FigmaOutlineButtonStyle(prominent: true))
            }
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 14)
        .background(AuraTheme.forestDeep.opacity(0.65))
    }

    // MARK: - Home & 4K Catalog ScrollView (Exact Figma Hero + Trendy Banners + 3D Pop-Out Grid)

    private var figmaHomeAndCatalogScrollView: some View {
        ScrollView {
            VStack(spacing: 36) {

                // Status notification pill if Lock Screen injection was recently run
                if let status = lockScreen.statusMessage {
                    HStack(spacing: 8) {
                        if lockScreen.isBusy {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: lockScreen.statusIsError ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                                .foregroundStyle(lockScreen.statusIsError ? .red : AuraTheme.mintAccent)
                        }
                        Text(status)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                        Spacer()
                        Button("Dismiss") {
                            lockScreen.statusMessage = nil
                        }
                        .buttonStyle(.plain)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .figmaGlassCard(cornerRadius: 20)
                }

                // 1. FIGMA HERO SECTION WITH CENTRAL 3D MAC STUDIO SPINE & POP-OUT RIGHT CARD
                ZStack(alignment: .top) {
                    // Central Giant 3D Mac Studio Display Spine
                    if let centerImg = AuraTheme.load3DAsset("hero-center-mac") {
                        Image(nsImage: centerImg)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 420, height: 480)
                            .shadow(color: .black.opacity(0.85), radius: 30, y: 20)
                            .offset(y: -10)
                            .allowsHitTesting(false)
                    }

                    HStack(alignment: .top, spacing: 24) {
                        // Left Column: "Breathe 4K Motion" + Buttons + Floating Glass Review Card
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Breathe 4K Motion")
                                .font(.system(size: 46, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text("Apply any 4K 60/240fps live animation or video to your macOS Desktop, Screen Saver, and native Lock Screen — 100% free.")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.74))
                                .frame(maxWidth: 340, alignment: .leading)
                                .lineSpacing(3)

                            HStack(spacing: 14) {
                                Button {
                                    openFilePanel()
                                } label: {
                                    Text("Import 4K Video")
                                }
                                .buttonStyle(FigmaOutlineButtonStyle())

                                Button {
                                    Task { await store.generateSample4KVideo() }
                                } label: {
                                    HStack(spacing: 10) {
                                        ZStack {
                                            Circle()
                                                .strokeBorder(Color.white.opacity(0.55), lineWidth: 1.4)
                                                .frame(width: 36, height: 36)
                                            if store.isGeneratingSample {
                                                ProgressView().controlSize(.small)
                                            } else {
                                                Image(systemName: "play.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        Text(store.isGeneratingSample ? "Synthesizing 4K..." : "Synthesize 4K Demo...")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(.white.opacity(0.88))
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(store.isGeneratingSample)
                            }

                            // Floating Glass Card on Mid-Left (Matches Figma Testimonial Card)
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [AuraTheme.emeraldGlow, AuraTheme.mintAccent],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 38, height: 38)
                                        Image(systemName: "cpu.fill")
                                            .foregroundStyle(AuraTheme.forestDeep)
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Apple Silicon Hardware HEVC")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text("★★★★★  < 1% CPU Overhead")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle( Color.yellow.opacity(0.9) )
                                    }
                                }
                                Text("Zero Dock clutter, instant sleep auto-pause, and native `idleassetsd` Lock Screen injection with 1-click backup restore.")
                                    .font(.system(size: 11.5))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .lineSpacing(2)
                            }
                            .padding(18)
                            .frame(width: 300, alignment: .leading)
                            .figmaGlassCard(cornerRadius: 32)
                            .padding(.top, 16)
                        }

                        Spacer()

                        // Right Column: 3D Pop-Out Card (Mac Desktop Icon popping out of top border!)
                        VStack(alignment: .leading, spacing: 10) {
                            Spacer().frame(height: 95)

                            Text("ACTIVE SURFACE ENGINE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(AuraTheme.mintAccent)

                            Text("4K Desktop & Lock")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text("\(catalog.allRemoteItems.count) Cloud 4K videos ready + \(store.items.count) downloaded locally.")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.7))

                            HStack {
                                Button("My Library (\(store.items.count))") {
                                    store.selectedSection = .myLibrary
                                }
                                .buttonStyle(FigmaOutlineButtonStyle())

                                Spacer()

                                if let activeItem = store.items.first(where: { $0.id == (store.activeScreenSaverID ?? store.activeDesktopID) }) ?? store.items.first {
                                    Button {
                                        screenSaver.startScreenSaver(with: activeItem.fileURL)
                                    } label: {
                                        Image(systemName: "play.tv.fill")
                                            .foregroundStyle(.white)
                                            .frame(width: 34, height: 34)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .strokeBorder(Color.white.opacity(0.55), lineWidth: 1.3)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .help("Preview Fullscreen 4K Screen Saver")
                                }
                            }
                            .padding(.top, 6)
                        }
                        .padding(22)
                        .frame(width: 285)
                        .figmaGlassCard(cornerRadius: 40)
                        .overlay(alignment: .top) {
                            if let rightImg = AuraTheme.load3DAsset("mac-desktop") {
                                Image(nsImage: rightImg)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 190, height: 190)
                                    .shadow(color: .black.opacity(0.8), radius: 20, y: 12)
                                    .offset(y: -68)
                                    .allowsHitTesting(false)
                            }
                        }
                        .padding(.top, 55)
                    }
                }
                .padding(.top, 10)

                // 2. "OUR TRENDY SURFACES" WIDE HORIZONTAL GLASS BANNER (Matches Figma Wide Banner!)
                VStack(spacing: 22) {
                    FigmaBracketTitle(title: "Our Trendy Surfaces")

                    HStack(spacing: 24) {
                        if let lockImg = AuraTheme.load3DAsset("mac-lockscreen") {
                            Image(nsImage: lockImg)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 210, height: 190)
                                .shadow(color: .black.opacity(0.85), radius: 22, y: 12)
                                .offset(y: -14)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("For Native macOS Lock Screen & 240fps Aerial Saver")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text("Unlike basic desktop players, AuraDesk remuxes any 4K video into `.mov`, backs up Apple's original `4KSDR240FPS` Aerial file, updates `Index.plist`, and injects your video into `idleassetsd` for real Lock Screen motion.")
                                .font(.system(size: 12.5))
                                .foregroundStyle(.white.opacity(0.72))
                                .lineSpacing(2)

                            HStack(spacing: 12) {
                                Button("Configure Lock Screen Slot") {
                                    store.selectedSection = .lockScreen
                                }
                                .buttonStyle(FigmaOutlineButtonStyle())

                                Button("Screen Saver Clock") {
                                    store.selectedSection = .screenSaver
                                }
                                .buttonStyle(FigmaOutlineButtonStyle())
                            }
                            .padding(.top, 4)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 18)
                    .figmaGlassCard(cornerRadius: 52)
                }

                // 3. "OUR TOP 4K WALLPAPERS" — 3D POP-OUT CARDS GRID (Matches Figma 3-Col Grid!)
                VStack(spacing: 22) {
                    FigmaBracketTitle(title: "Our Top 4K Wallpapers")

                    // Search & Category Filter Bar inside a Glass Pill
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(AuraTheme.mintAccent)
                                TextField("Search 350+ 4K wallpapers (SpaceX, Porsche, Cyberpunk, Nature, Aerial)...", text: $catalog.searchQuery)
                                    .textFieldStyle(.plain)
                                    .foregroundStyle(.white)
                                if !catalog.searchQuery.isEmpty {
                                    Button {
                                        catalog.searchQuery = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.white.opacity(0.6))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                            )

                            Picker("Source", selection: $catalog.selectedSourceFilter) {
                                ForEach(catalog.sources, id: \.self) { src in
                                    Text(src).tag(src)
                                }
                            }
                            .frame(width: 200)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(catalog.categories, id: \.self) { category in
                                    let isSelected = catalog.selectedCategory == category
                                    Button {
                                        catalog.selectedCategory = category
                                    } label: {
                                        Text(category)
                                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(
                                                Capsule()
                                                    .fill(isSelected ? AuraTheme.mintAccent : Color.white.opacity(0.07))
                                            )
                                            .overlay(
                                                Capsule()
                                                    .strokeBorder(Color.white.opacity(isSelected ? 0 : 0.2), lineWidth: 1)
                                            )
                                            .foregroundStyle(isSelected ? AuraTheme.forestDeep : .white)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(18)
                    .figmaGlassCard(cornerRadius: 30)

                    // Grid of Figma Pop-Out 4K Cards
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 285, maximum: 360), spacing: 22)],
                        spacing: 42
                    ) {
                        ForEach(catalog.filteredItems) { remote in
                            RemoteWallpaperCardView(remote: remote)
                        }
                    }
                    .padding(.top, 24)
                }
            }
            .padding(28)
        }
    }

    // MARK: - My Downloaded Library View (Figma Styled)

    private var libraryGridView: some View {
        ScrollView {
            VStack(spacing: 28) {
                HStack {
                    FigmaBracketTitle(title: "My Downloaded 4K Library")
                    Spacer()
                    Button {
                        openFilePanel()
                    } label: {
                        Label("Add Local .MP4 / .MOV", systemImage: "folder.badge.plus")
                    }
                    .buttonStyle(FigmaOutlineButtonStyle(prominent: true))
                }

                if store.items.isEmpty {
                    emptyLibraryView
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 285, maximum: 360), spacing: 22)],
                        spacing: 42
                    ) {
                        ForEach(store.items) { item in
                            WallpaperCardView(item: item)
                        }
                    }
                    .padding(.top, 24)
                }
            }
            .padding(28)
        }
    }

    private var emptyLibraryView: some View {
        VStack(spacing: 18) {
            if let img = AuraTheme.load3DAsset("mac-cloud") {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 210, height: 210)
                    .shadow(color: .black.opacity(0.8), radius: 24, y: 12)
            }
            Text("No Local 4K Wallpapers Yet")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Explore 350+ free 4K wallpapers in **Home & 4K Catalog**, drop any `.mp4` or `.mov` video here, or synthesize a 4K Aurora Borealis sample.")
                .font(.system(size: 13.5))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 480)

            HStack(spacing: 14) {
                Button("Explore 350+ 4K Catalog") {
                    store.selectedSection = .discover4K
                }
                .buttonStyle(FigmaOutlineButtonStyle(prominent: true))

                Button("Import Local .MP4 / .MOV") {
                    openFilePanel()
                }
                .buttonStyle(FigmaOutlineButtonStyle())
            }
            .padding(.top, 6)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .figmaGlassCard(cornerRadius: 44)
    }

    // MARK: - Lock Screen & Aerial Injection View (Figma Styled)

    private var lockScreenDetailView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(spacing: 24) {
                    if let lockImg = AuraTheme.load3DAsset("mac-lockscreen") {
                        Image(nsImage: lockImg)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 180, height: 180)
                            .shadow(color: .black.opacity(0.85), radius: 20, y: 10)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        FigmaBracketTitle(title: "Native Lock Screen Engine")
                        Text("AuraDesk injects your custom 4K video directly into macOS's native `idleassetsd` Aerial pipeline and updates `com.apple.wallpaper/Store/Index.plist`. Every override automatically backs up Apple's original `.mov` file first.")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.75))
                            .lineSpacing(3)
                    }
                }
                .padding(24)
                .figmaGlassCard(cornerRadius: 42)

                // Target Aerial Slot Picker Card
                VStack(alignment: .leading, spacing: 14) {
                    Text("Target macOS Aerial Slot (`4KSDR240FPS`)")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    HStack(spacing: 14) {
                        Picker("Aerial Slot to Override:", selection: $lockScreen.selectedTargetID) {
                            ForEach(lockScreen.availableTargets) { target in
                                Text("\(target.name) (\(target.id.prefix(8))…)" + (target.hasBackup ? " [Backed Up]" : ""))
                                    .tag(target.id)
                            }
                        }
                        .frame(maxWidth: 460)

                        Button("Refresh Slots") {
                            lockScreen.refreshTargets()
                        }
                        .buttonStyle(FigmaOutlineButtonStyle())
                    }

                    if let currentTarget = lockScreen.availableTargets.first(where: { $0.id == lockScreen.selectedTargetID }) {
                        HStack(spacing: 18) {
                            Label(
                                currentTarget.isDownloaded ? "Downloaded on Disk" : "Will Create Slot File",
                                systemImage: currentTarget.isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle"
                            )
                            .foregroundStyle(currentTarget.isDownloaded ? AuraTheme.mintAccent : .orange)
                            .font(.caption)

                            Label(
                                currentTarget.hasBackup ? "Original Apple Video Backed Up" : "Original Not Yet Overridden",
                                systemImage: currentTarget.hasBackup ? "externaldrive.badge.checkmark" : "shield"
                            )
                            .foregroundStyle(.white.opacity(0.7))
                            .font(.caption)

                            Spacer()

                            if currentTarget.hasBackup {
                                Button("Restore Original Apple Video") {
                                    Task {
                                        await lockScreen.restoreOriginalAerial()
                                    }
                                }
                                .buttonStyle(FigmaOutlineButtonStyle())
                                .disabled(lockScreen.isBusy)
                            }
                        }
                    }
                }
                .padding(24)
                .figmaGlassCard(cornerRadius: 36)

                // Downloaded videos ready for Lock Screen
                VStack(alignment: .leading, spacing: 14) {
                    Text("Apply a Downloaded Video to Lock Screen & Screen Saver")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    if store.items.isEmpty {
                        Text("Download a 4K video from the Home & 4K Catalog tab or import a local file first.")
                            .foregroundStyle(.white.opacity(0.65))
                            .padding(.vertical, 8)
                    } else {
                        ForEach(store.items) { item in
                            HStack(spacing: 14) {
                                if let thumbURL = item.thumbnailURL,
                                   let nsImg = NSImage(contentsOf: thumbURL) {
                                    Image(nsImage: nsImg)
                                        .resizable()
                                        .aspectRatio(16/9, contentMode: .fill)
                                        .frame(width: 96, height: 54)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text("\(item.category) • \(item.resolution) • \(item.formattedDuration) • \(String(format: "%.1f MB", item.fileSizeMB))")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.65))
                                }
                                Spacer()
                                if store.activeLockScreenID == item.id {
                                    Text("Active on Lock Screen")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(AuraTheme.mintAccent.opacity(0.2), in: Capsule())
                                        .foregroundStyle(AuraTheme.mintAccent)
                                }
                                Button("Set Lock & Saver") {
                                    Task {
                                        await store.setLockScreenAndAerialScreenSaver(item: item, alsoSetNativeDesktop: false)
                                    }
                                }
                                .buttonStyle(FigmaOutlineButtonStyle(prominent: true))
                                .disabled(lockScreen.isBusy)

                                Button("Apply All 3") {
                                    Task {
                                        await store.setAllThree(item: item)
                                    }
                                }
                                .buttonStyle(FigmaOutlineButtonStyle())
                                .disabled(lockScreen.isBusy)
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))
                        }
                    }
                }
                .padding(24)
                .figmaGlassCard(cornerRadius: 36)
            }
            .padding(28)
        }
    }

    // MARK: - Screen Saver Engine View (Figma Styled)

    private var screenSaverDetailView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(spacing: 24) {
                    if let saverImg = AuraTheme.load3DAsset("mac-screensaver") {
                        Image(nsImage: saverImg)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 180, height: 180)
                            .shadow(color: .black.opacity(0.85), radius: 20, y: 10)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        FigmaBracketTitle(title: "4K Screen Saver Engine")
                        Text("Supports both macOS's native Aerial Screen Saver and an instant built-in 4K Screen Saver overlay with a Sonoma-style date & time clock.")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.75))
                            .lineSpacing(3)
                    }
                }
                .padding(24)
                .figmaGlassCard(cornerRadius: 42)

                VStack(alignment: .leading, spacing: 18) {
                    Toggle("Show Sonoma-style Time & Date Overlay on Screen Saver", isOn: $screenSaver.showClockOnScreenSaver)
                        .foregroundStyle(.white)

                    HStack(spacing: 14) {
                        Text("Auto-launch Screen Saver after idle:")
                            .foregroundStyle(.white)
                        Slider(value: $screenSaver.idleTimeoutMinutes, in: 0...30, step: 1)
                            .frame(maxWidth: 260)
                        Text(screenSaver.idleTimeoutMinutes == 0 ? "Disabled (Use macOS Native)" : "\(Int(screenSaver.idleTimeoutMinutes)) min")
                            .monospacedDigit()
                            .foregroundStyle(AuraTheme.mintAccent)
                    }

                    if let item = store.items.first(where: { $0.id == (store.activeScreenSaverID ?? store.activeDesktopID) }) ?? store.items.first {
                        HStack {
                            Text("Selected Video: **\(item.title)**")
                                .foregroundStyle(.white)
                            Spacer()
                            Button {
                                screenSaver.startScreenSaver(with: item.fileURL)
                            } label: {
                                Label("Launch Fullscreen 4K Screen Saver Now", systemImage: "play.tv.fill")
                            }
                            .buttonStyle(FigmaOutlineButtonStyle(prominent: true))
                        }
                        .padding(.top, 6)
                    }
                }
                .padding(26)
                .figmaGlassCard(cornerRadius: 36)
            }
            .padding(28)
        }
    }

    // MARK: - Playback & Energy Settings View (Figma Styled)

    private var playbackSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(spacing: 24) {
                    if let chipImg = AuraTheme.load3DAsset("mac-mchip") {
                        Image(nsImage: chipImg)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 170, height: 170)
                            .shadow(color: .black.opacity(0.85), radius: 20, y: 10)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        FigmaBracketTitle(title: "Playback & Energy Shield")
                        Text("Hardware-accelerated Apple Silicon HEVC/H.264 decoding with zero-drain sleep and lock detection.")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
                .padding(24)
                .figmaGlassCard(cornerRadius: 42)

                VStack(alignment: .leading, spacing: 18) {
                    Toggle("Loop 4K Video Seamlessly (AVPlayerLooper)", isOn: $store.loopPlayback)
                        .foregroundStyle(.white)
                    Toggle("Mute Desktop Video Audio", isOn: $store.isMuted)
                        .foregroundStyle(.white)

                    if !store.isMuted {
                        HStack {
                            Text("Audio Volume")
                                .foregroundStyle(.white)
                            Slider(value: $store.volume, in: 0...1)
                                .frame(maxWidth: 260)
                            Text("\(Int(store.volume * 100))%")
                                .monospacedDigit()
                                .foregroundStyle(AuraTheme.mintAccent)
                        }
                    }

                    Picker("Multi-Monitor Scaling Mode", selection: $store.videoGravity) {
                        ForEach(VideoGravityMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .frame(maxWidth: 340)

                    HStack {
                        Text("Playback Rate")
                            .foregroundStyle(.white)
                        Slider(value: $store.playbackSpeed, in: 0.25...2.0, step: 0.25)
                            .frame(maxWidth: 260)
                        Text(String(format: "%.2fx", store.playbackSpeed))
                            .monospacedDigit()
                            .foregroundStyle(AuraTheme.mintAccent)
                    }

                    Divider().overlay(Color.white.opacity(0.15))

                    Toggle("Smart Energy Shield: Pause Desktop Video When Display Sleeps or Locks", isOn: $store.pauseOnScreenSleep)
                        .foregroundStyle(.white)
                }
                .padding(26)
                .figmaGlassCard(cornerRadius: 36)
            }
            .padding(28)
        }
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

// MARK: - Figma 3D Pop-Out Remote Catalog Card

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
            // Pop-Out Floating Thumbnail Frame (Rises -18pt above the glass card top, just like the Figma 3D cards!)
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: remote.thumbURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(height: 152)
                            .clipped()
                    default:
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [AuraTheme.forestDeep, AuraTheme.emeraldGlow.opacity(0.45)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 152)
                            .overlay {
                                Image(systemName: "sparkles.tv")
                                    .font(.system(size: 30))
                                    .foregroundStyle(AuraTheme.mintAccent.opacity(0.8))
                            }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.28), lineWidth: 1.2)
                )
                .shadow(color: .black.opacity(0.75), radius: 16, y: 10)

                HStack(spacing: 4) {
                    Text(remote.category)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AuraTheme.forestDeep.opacity(0.85), in: Capsule())
                        .foregroundStyle(AuraTheme.mintAccent)

                    Text(remote.resolution)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.75), in: Capsule())
                        .foregroundStyle(.white)
                }
                .padding(10)
            }
            .offset(y: -22)
            .padding(.bottom, -14)

            VStack(alignment: .leading, spacing: 4) {
                Text(remote.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(String(format: "%@ • %@ • %.1f MB", remote.source, remote.formattedDuration, remote.fileSizeMB))
                    .font(.system(size: 11.5))
                    .foregroundStyle(.white.opacity(0.65))
            }

            if let existing = localDownloadedItem {
                HStack(spacing: 8) {
                    Button("Set Desktop") {
                        store.setDesktopWallpaper(existing)
                    }
                    .buttonStyle(FigmaOutlineButtonStyle())

                    Button("Apply All 3") {
                        Task { await store.setAllThree(item: existing) }
                    }
                    .buttonStyle(FigmaOutlineButtonStyle(prominent: true))
                }
                .padding(.top, 4)
            } else if isDownloading {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text(catalog.downloadStatusText[remote.id] ?? "Downloading 4K...")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(AuraTheme.mintAccent)
                    Spacer()
                }
                .padding(.vertical, 6)
            } else {
                HStack(spacing: 8) {
                    Button {
                        Task {
                            await catalog.downloadAndImport(remoteItem: remote, applyMode: .desktopOnly)
                        }
                    } label: {
                        Text("Get 4K Desktop")
                    }
                    .buttonStyle(FigmaOutlineButtonStyle())

                    Spacer()

                    Button {
                        Task {
                            await catalog.downloadAndImport(remoteItem: remote, applyMode: .allThree)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.display")
                            Text("All 3")
                        }
                    }
                    .buttonStyle(FigmaOutlineButtonStyle(prominent: true))
                    .help("Download 4K video and apply to Desktop, Screen Saver, and Lock Screen")
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
        .padding(.top, 6)
        .figmaGlassCard(cornerRadius: 36, isHighlighted: localDownloadedItem != nil)
    }
}

// MARK: - Figma 3D Pop-Out Local Library Card

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
                        .frame(height: 152)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [AuraTheme.forestDeep, AuraTheme.emeraldGlow.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 152)
                        .overlay {
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(AuraTheme.mintAccent)
                        }
                }

                HStack(spacing: 4) {
                    Text(item.resolution)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.75), in: Capsule())
                        .foregroundStyle(AuraTheme.mintAccent)

                    Text(item.formattedDuration)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.75), in: Capsule())
                        .foregroundStyle(.white)
                }
                .padding(10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.28), lineWidth: 1.2)
            )
            .shadow(color: .black.opacity(0.75), radius: 16, y: 10)
            .offset(y: -22)
            .padding(.bottom, -14)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(String(format: "%@ • %.1f MB • %@", item.category, item.fileSizeMB, item.fileURL.pathExtension.uppercased()))
                        .font(.system(size: 11.5))
                        .foregroundStyle(.white.opacity(0.65))
                }
                Spacer()
                Button(role: .destructive) {
                    store.deleteItem(item)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.white.opacity(0.55))
                }
                .buttonStyle(.plain)
                .help("Remove from Library")
            }

            HStack(spacing: 6) {
                StatusBadge(title: "Desktop", active: isDesktopActive, color: AuraTheme.mintAccent)
                StatusBadge(title: "Saver", active: isSaverActive, color: AuraTheme.mintAccent)
                StatusBadge(title: "Lock Screen", active: isLockActive, color: AuraTheme.mintAccent)
            }

            HStack(spacing: 8) {
                Button("Desktop") {
                    store.setDesktopWallpaper(item)
                }
                .buttonStyle(FigmaOutlineButtonStyle())

                Button("Lock & Saver") {
                    Task {
                        await store.setLockScreenAndAerialScreenSaver(item: item)
                    }
                }
                .buttonStyle(FigmaOutlineButtonStyle())
                .disabled(lockScreen.isBusy)

                Spacer()

                Button("All 3") {
                    Task {
                        await store.setAllThree(item: item)
                    }
                }
                .buttonStyle(FigmaOutlineButtonStyle(prominent: true))
                .disabled(lockScreen.isBusy)
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
        .padding(.top, 6)
        .figmaGlassCard(cornerRadius: 36, isHighlighted: isDesktopActive || isLockActive)
    }
}

struct StatusBadge: View {
    let title: String
    let active: Bool
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(active ? color : Color.white.opacity(0.25))
                .frame(width: 6, height: 6)
            Text(title)
                .font(.system(size: 10, weight: active ? .bold : .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(active ? color.opacity(0.18) : Color.white.opacity(0.06), in: Capsule())
        .foregroundStyle(active ? color : .white.opacity(0.55))
    }
}
