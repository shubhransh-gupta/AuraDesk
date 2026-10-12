import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Sparkling Silver & Aurora Night Theme
public enum AuraTheme {
    public static let obsidianBlack = Color(red: 0.02, green: 0.02, blue: 0.035)
    public static let carbonBg = Color(red: 0.035, green: 0.04, blue: 0.065)
    public static let panelTop = Color(red: 0.11, green: 0.12, blue: 0.16).opacity(0.82)
    public static let panelBottom = Color(red: 0.04, green: 0.045, blue: 0.07).opacity(0.90)

    public static let chromeWhite = Color(red: 0.99, green: 0.99, blue: 1.0)
    public static let silverBright = Color(red: 0.91, green: 0.93, blue: 0.96)
    public static let silverMid = Color(red: 0.68, green: 0.71, blue: 0.77)
    public static let silverMuted = Color(red: 0.48, green: 0.51, blue: 0.58)
    public static let gunmetalBorder = Color.white.opacity(0.16)
    public static let silverEdge = Color.white.opacity(0.55)

    // Subtle Aurora / Norwegian Lights accents
    public static let auroraCyan = Color(red: 0.15, green: 0.95, blue: 0.82)
    public static let auroraEmerald = Color(red: 0.10, green: 0.88, blue: 0.55)
    public static let auroraViolet = Color(red: 0.62, green: 0.32, blue: 0.98)
    public static let auroraBlue = Color(red: 0.22, green: 0.62, blue: 1.0)

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
                Color(red: 1.0, green: 1.0, blue: 1.0),
                Color(red: 0.88, green: 0.90, blue: 0.95),
                Color(red: 0.74, green: 0.77, blue: 0.84)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static var darkMetalGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.17, green: 0.18, blue: 0.23).opacity(0.92),
                Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    public static var sharpBorderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.48),
                Color.white.opacity(0.14),
                AuraTheme.auroraCyan.opacity(0.28)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Animated Star Gazing + Norwegian Lights (Aurora Borealis) Background (No Moon)
struct AppAuroraStargazingBackground: View {
    struct StarPoint {
        let x: Double
        let y: Double
        let size: Double
        let speed: Double
        let phase: Double
        let isSparkle: Bool
    }

    private static let stars: [StarPoint] = {
        var list: [StarPoint] = []
        for i in 0..<190 {
            let seed = Double(i * 997 + 137)
            let x = fmod(abs(sin(seed * 1.13) * 10000.0), 1.0)
            let y = fmod(abs(cos(seed * 2.47) * 10000.0), 1.0)
            let size = 1.0 + fmod(abs(sin(seed * 3.71) * 100.0), 2.4)
            let speed = 1.2 + fmod(abs(cos(seed * 5.19) * 100.0), 2.8)
            let phase = fmod(abs(sin(seed * 7.31) * 100.0), 6.28)
            let isSparkle = (i % 9 == 0)
            list.append(StarPoint(x: x, y: y, size: size, speed: speed, phase: phase, isSparkle: isSparkle))
        }
        return list
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let w = size.width
                let h = size.height

                // 1. Deep Arctic Night Sky Base
                let skyRect = CGRect(origin: .zero, size: size)
                context.fill(
                    Path(skyRect),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(red: 0.015, green: 0.02, blue: 0.045),
                            Color(red: 0.025, green: 0.035, blue: 0.075),
                            Color(red: 0.01, green: 0.015, blue: 0.03)
                        ]),
                        startPoint: CGPoint(x: w * 0.5, y: 0),
                        endPoint: CGPoint(x: w * 0.5, y: h)
                    )
                )

                // 2. Norwegian Lights (Aurora Borealis) & Neon Ribbons
                drawAuroraRibbon(
                    context: &context,
                    size: size,
                    time: t * 0.55,
                    yBase: h * 0.22,
                    amplitude: 48,
                    thickness: h * 0.34,
                    colors: [
                        Color.clear,
                        Color(red: 0.08, green: 0.96, blue: 0.68).opacity(0.22),
                        Color(red: 0.12, green: 0.85, blue: 0.98).opacity(0.16),
                        Color.clear
                    ]
                )

                drawAuroraRibbon(
                    context: &context,
                    size: size,
                    time: t * 0.42 + 2.1,
                    yBase: h * 0.40,
                    amplitude: 62,
                    thickness: h * 0.38,
                    colors: [
                        Color.clear,
                        Color(red: 0.58, green: 0.22, blue: 0.98).opacity(0.18),
                        Color(red: 0.95, green: 0.20, blue: 0.75).opacity(0.12),
                        Color.clear
                    ]
                )

                drawAuroraRibbon(
                    context: &context,
                    size: size,
                    time: t * 0.68 + 4.3,
                    yBase: h * 0.68,
                    amplitude: 40,
                    thickness: h * 0.30,
                    colors: [
                        Color.clear,
                        Color(red: 0.10, green: 0.92, blue: 0.78).opacity(0.16),
                        Color(red: 0.25, green: 0.55, blue: 1.0).opacity(0.14),
                        Color.clear
                    ]
                )

                // 3. Twinkling Star Gazing Field
                for star in Self.stars {
                    let sx = star.x * w
                    let sy = star.y * h
                    let twinkle = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * star.speed + star.phase))
                    let r = star.size * (0.8 + 0.3 * twinkle)
                    let starRect = CGRect(x: sx - r * 0.5, y: sy - r * 0.5, width: r, height: r)

                    context.fill(
                        Path(ellipseIn: starRect),
                        with: .color(Color.white.opacity(twinkle))
                    )

                    if star.isSparkle && twinkle > 0.72 {
                        let spikeLen = r * 3.2
                        var hLine = Path()
                        hLine.move(to: CGPoint(x: sx - spikeLen, y: sy))
                        hLine.addLine(to: CGPoint(x: sx + spikeLen, y: sy))
                        hLine.move(to: CGPoint(x: sx, y: sy - spikeLen))
                        hLine.addLine(to: CGPoint(x: sx, y: sy + spikeLen))
                        context.stroke(hLine, with: .color(Color.white.opacity(twinkle * 0.55)), lineWidth: 0.75)
                    }
                }

                // 4. Periodic Shooting Star Streak (No Moon)
                let cycle = fmod(t, 6.5)
                if cycle < 1.35 {
                    let p = cycle / 1.35
                    let startX = w * 0.78 - p * (w * 0.48)
                    let startY = h * 0.12 + p * (h * 0.34)
                    let tailX = startX + 110
                    let tailY = startY - 75

                    var meteorPath = Path()
                    meteorPath.move(to: CGPoint(x: startX, y: startY))
                    meteorPath.addLine(to: CGPoint(x: tailX, y: tailY))

                    context.stroke(
                        meteorPath,
                        with: .linearGradient(
                            Gradient(colors: [
                                Color.white.opacity(0.95 * (1.0 - p * 0.5)),
                                AuraTheme.auroraCyan.opacity(0.55 * (1.0 - p)),
                                Color.clear
                            ]),
                            startPoint: CGPoint(x: startX, y: startY),
                            endPoint: CGPoint(x: tailX, y: tailY)
                        ),
                        lineWidth: 1.8
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func drawAuroraRibbon(
        context: inout GraphicsContext,
        size: CGSize,
        time: Double,
        yBase: Double,
        amplitude: Double,
        thickness: Double,
        colors: [Color]
    ) {
        let w = size.width
        let steps = 28
        var path = Path()

        for i in 0...steps {
            let frac = Double(i) / Double(steps)
            let x = frac * w
            let wave = sin(frac * 4.2 + time) * amplitude + cos(frac * 7.5 - time * 1.3) * (amplitude * 0.45)
            let y = yBase + wave
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        for i in (0...steps).reversed() {
            let frac = Double(i) / Double(steps)
            let x = frac * w
            let wave = sin(frac * 4.2 + time) * amplitude + cos(frac * 7.5 - time * 1.3) * (amplitude * 0.45)
            let y = yBase + wave + thickness
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.closeSubpath()

        context.fill(
            path,
            with: .linearGradient(
                Gradient(colors: colors),
                startPoint: CGPoint(x: w * 0.5, y: yBase - amplitude),
                endPoint: CGPoint(x: w * 0.5, y: yBase + thickness + amplitude)
            )
        )
    }
}

// MARK: - Strictly Clipped Sharp Silver Card Modifier
struct SharpSilverCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 10
    var isHighlighted: Bool = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(shape.fill(AuraTheme.cardGradient))
            .clipShape(shape)
            .overlay(
                shape.strokeBorder(
                    isHighlighted
                        ? LinearGradient(
                            colors: [AuraTheme.chromeWhite, AuraTheme.auroraCyan, AuraTheme.silverMid],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : AuraTheme.sharpBorderGradient,
                    lineWidth: isHighlighted ? 1.6 : 1.0
                )
            )
            .shadow(color: .black.opacity(0.65), radius: 14, x: 0, y: 7)
    }
}

extension View {
    func sharpSilverCard(cornerRadius: CGFloat = 10, isHighlighted: Bool = false) -> some View {
        modifier(SharpSilverCardModifier(cornerRadius: cornerRadius, isHighlighted: isHighlighted))
    }
}

struct SharpSilverButtonStyle: ButtonStyle {
    var prominent: Bool = false
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 11 : 12, weight: .bold))
            .foregroundStyle(prominent ? Color.black : AuraTheme.chromeWhite)
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
                            ? Color.white
                            : Color.white.opacity(0.28),
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

// MARK: - Strictly Bounded Remote Authenticated Thumbnail View (Never Overflows Box!)
struct Remote4KThumbnailView: View {
    let item: RemoteWallpaperItem
    @ObservedObject var catalog = CloudCatalogService.shared

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Deep metallic night fallback backdrop
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.14, blue: 0.20),
                        Color(red: 0.04, green: 0.05, blue: 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if let nsImg = catalog.loadedThumbnails[item.id] {
                    Image(nsImage: nsImg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "sparkles.tv.fill")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(AuraTheme.silverBright)
                        Text(item.resolution)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(AuraTheme.silverMid)
                    }
                }

                // Bottom dark gradient vignette for badge legibility
                LinearGradient(
                    colors: [.clear, .black.opacity(0.72)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .clipped()
        .onAppear {
            catalog.requestThumbnailIfNeeded(for: item)
        }
    }
}

// MARK: - Strictly Bounded Local Thumbnail View
struct Local4KThumbnailView: View {
    let item: WallpaperItem

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.14, green: 0.15, blue: 0.22),
                        Color(red: 0.04, green: 0.05, blue: 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if let thumbURL = item.thumbnailURL,
                   let nsImg = NSImage(contentsOf: thumbURL) {
                    Image(nsImage: nsImg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    VStack(spacing: 5) {
                        Image(systemName: "film.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AuraTheme.silverBright)
                        Text(item.resolution)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(AuraTheme.silverMid)
                    }
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.72)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .clipped()
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
        ZStack {
            // Animated Star Gazing + Norwegian Lights (Aurora Borealis) Background (No Moon)
            AppAuroraStargazingBackground()

            HStack(spacing: 0) {
                // LEFT SIDEBAR
                sidebarView
                    .frame(width: 238)
                    .background(Color.black.opacity(0.55))

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
            }
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
                            .font(.system(size: 14, weight: .heavy))
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
                        .foregroundStyle(AuraTheme.silverMid)
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
                    .foregroundStyle(AuraTheme.silverMid)
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
                                .foregroundStyle(isSelected ? .black : AuraTheme.silverBright)
                                .frame(width: 22)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(section.rawValue)
                                    .font(.system(size: 12.5, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(isSelected ? .black : AuraTheme.chromeWhite)
                                Text(section.subtitle)
                                    .font(.system(size: 10))
                                    .foregroundStyle(isSelected ? .black.opacity(0.68) : AuraTheme.silverMid)
                            }
                            Spacer()

                            if section == .discover4K {
                                Text("\(catalogService.allRemoteItems.count)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(isSelected ? .black : AuraTheme.chromeWhite)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(isSelected ? Color.black.opacity(0.16) : Color.white.opacity(0.12))
                                    )
                            } else if section == .myLibrary {
                                Text("\(store.items.count)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(isSelected ? .black : AuraTheme.chromeWhite)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(isSelected ? Color.black.opacity(0.16) : Color.white.opacity(0.12))
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
                        .foregroundStyle(AuraTheme.silverBright)
                    Spacer()
                    Circle()
                        .fill(desktopController.isPlaying ? AuraTheme.auroraCyan : AuraTheme.silverMuted)
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
                .foregroundStyle(AuraTheme.silverMid)
                .frame(width: 52, alignment: .leading)
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AuraTheme.chromeWhite)
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
                    .foregroundStyle(AuraTheme.silverMid)
            }

            Spacer()

            // Search Box
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(AuraTheme.silverBright)
                TextField("Search 350+ 4K wallpapers...", text: $catalogService.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(AuraTheme.chromeWhite)
                    .frame(width: 210)
                    .onChange(of: catalogService.searchQuery) { _, newValue in
                        if !newValue.isEmpty && store.selectedSection != .discover4K {
                            store.selectedSection = .discover4K
                        }
                    }
                if !catalogService.searchQuery.isEmpty {
                    Button {
                        catalogService.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AuraTheme.silverMid)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.black.opacity(0.65))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
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
        .background(Color.black.opacity(0.55))
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
                            .foregroundStyle(AuraTheme.silverBright)
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
                            .foregroundStyle(AuraTheme.silverBright)
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
                                    .foregroundStyle(active ? .black : AuraTheme.silverBright)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(active ? AnyShapeStyle(AuraTheme.chromeButtonGradient) : AnyShapeStyle(Color.black.opacity(0.65)))
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
                                    .foregroundStyle(selected ? .black : AuraTheme.chromeWhite)
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

    // MARK: - Featured Top 4K Card (Hero Row at Top — Strictly Clipped)
    private func featuredTop4KCard(_ item: RemoteWallpaperItem) -> some View {
        let isDownloading = catalogService.downloadingIDs.contains(item.id)
        let localMatch = store.items.first(where: { $0.remoteID == item.id })
        let isDesktopActive = localMatch != nil && store.activeDesktopID == localMatch?.id

        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                Remote4KThumbnailView(item: item)
                    .frame(height: 172)
                    .clipped()

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
                            .background(Color.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 4))
                            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.white.opacity(0.45), lineWidth: 1))
                    } else {
                        Text("4K UHD")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(AuraTheme.chromeWhite)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(Color.black.opacity(0.80), in: RoundedRectangle(cornerRadius: 4))
                            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.white.opacity(0.32), lineWidth: 1))
                    }
                }
                .padding(10)
            }
            .frame(height: 172)
            .clipped()

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
                    .foregroundStyle(AuraTheme.silverMid)
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
        .sharpSilverCard(cornerRadius: 10, isHighlighted: isDesktopActive)
    }

    // MARK: - Standard 4K Catalog Grid Card (Strictly Clipped)
    private func remote4KCatalogCard(_ item: RemoteWallpaperItem) -> some View {
        let isDownloading = catalogService.downloadingIDs.contains(item.id)
        let localMatch = store.items.first(where: { $0.remoteID == item.id })
        let isDesktopActive = localMatch != nil && store.activeDesktopID == localMatch?.id

        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                Remote4KThumbnailView(item: item)
                    .frame(height: 152)
                    .clipped()

                HStack {
                    Text(item.category.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(AuraTheme.chromeWhite)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.white.opacity(0.28), lineWidth: 1))

                    Spacer()

                    if localMatch != nil {
                        Text("READY")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AuraTheme.chromeWhite, in: RoundedRectangle(cornerRadius: 4))
                    } else {
                        Text("4K")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(AuraTheme.chromeWhite)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 4))
                    }
                }
                .padding(8)
            }
            .frame(height: 152)
            .clipped()

            VStack(alignment: .leading, spacing: 9) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(AuraTheme.chromeWhite)
                        .lineLimit(1)

                    Text("\(item.resolution) • \(String(format: "%.0f MB", item.fileSizeMB)) • \(Int(item.durationSeconds))s")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(AuraTheme.silverMid)
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
        .sharpSilverCard(cornerRadius: 10, isHighlighted: isDesktopActive)
    }

    // MARK: - Instant Local Wallpaper Card (Strictly Clipped)
    private func instantLocalWallpaperCard(_ item: WallpaperItem) -> some View {
        let isDesktop = store.activeDesktopID == item.id
        let isSaver = store.activeScreenSaverID == item.id
        let isLock = store.activeLockScreenID == item.id

        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                Local4KThumbnailView(item: item)
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
            .frame(height: 145)
            .clipped()

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(AuraTheme.chromeWhite)
                            .lineLimit(1)
                        Text("\(String(format: "%.1f MB", item.fileSizeMB)) • \(item.category)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(AuraTheme.silverMid)
                    }
                    Spacer()
                    Button {
                        store.deleteItem(item)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(AuraTheme.silverMid)
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
        .sharpSilverCard(cornerRadius: 10, isHighlighted: isDesktop || isLock)
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
            .sharpSilverCard(cornerRadius: 10)

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
                .sharpSilverCard(cornerRadius: 10)
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
                            .foregroundStyle(AuraTheme.silverMid)
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
            .sharpSilverCard(cornerRadius: 10)

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
                .sharpSilverCard(cornerRadius: 10)

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
                .sharpSilverCard(cornerRadius: 10)
            }
        }
    }

    // MARK: - Bottom Status Footer Bar
    private var bottomStatusFooterBar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Circle()
                    .fill(desktopController.isPlaying ? AuraTheme.auroraCyan : AuraTheme.silverMuted)
                    .frame(width: 7, height: 7)
                Text(desktopController.isPlaying ? "4K ENGINE RUNNING" : "ENGINE STANDBY")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(AuraTheme.chromeWhite)
            }

            Text("•")
                .foregroundStyle(AuraTheme.silverMid)

            Text("Catalog: \(catalogService.allRemoteItems.count) 4K Videos")
                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                .foregroundStyle(AuraTheme.silverBright)

            Text("•")
                .foregroundStyle(AuraTheme.silverMid)

            Text("Local Ready: \(store.items.count)")
                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                .foregroundStyle(AuraTheme.silverBright)

            Spacer()

            Text(lockScreenManager.statusMessage ?? "4K Engine Ready")
                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                .foregroundStyle(AuraTheme.silverMid)
                .lineLimit(1)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.68))
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
