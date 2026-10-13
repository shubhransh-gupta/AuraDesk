import AppKit
import AVFoundation
import QuartzCore

final class DesktopWallpaperWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class PlayerContainerView: NSView {
    let playerLayer: AVPlayerLayer

    init(player: AVPlayer, gravity: AVLayerVideoGravity) {
        self.playerLayer = AVPlayerLayer(player: player)
        super.init(frame: .zero)
        self.wantsLayer = true
        self.canDrawConcurrently = true
        self.playerLayer.videoGravity = gravity
        self.playerLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        self.playerLayer.drawsAsynchronously = true // Direct Metal compositor: zero CPU blit
        self.layer?.addSublayer(self.playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}

@MainActor
public final class DesktopWallpaperController: ObservableObject {
    public static let shared = DesktopWallpaperController()

    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var currentVideoURL: URL?

    private var windows: [DesktopWallpaperWindow] = []
    private var containerViews: [PlayerContainerView] = []
    private var queuePlayer: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?

    public var isMuted: Bool = true {
        didSet {
            queuePlayer?.isMuted = isMuted
            if !isMuted {
                queuePlayer?.volume = Float(volume)
            }
        }
    }

    public var volume: Double = 0.5 {
        didSet {
            if !isMuted {
                queuePlayer?.volume = Float(volume)
            }
        }
    }

    public var loopPlayback: Bool = true {
        didSet {
            if let url = currentVideoURL {
                playVideo(url: url)
            }
        }
    }

    public var videoGravity: VideoGravityMode = .aspectFill {
        didSet {
            for view in containerViews {
                view.playerLayer.videoGravity = videoGravity.avGravity
            }
        }
    }

    public var playbackSpeed: Float = 1.0 {
        didSet {
            if isPlaying {
                queuePlayer?.rate = playbackSpeed
            }
        }
    }

    public var pauseOnScreenSleep: Bool = true

    private init() {
        setupNotifications()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.rebuildWindowsForScreens()
            }
        }

        let wsCenter = NSWorkspace.shared.notificationCenter
        wsCenter.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.pauseOnScreenSleep else { return }
                self.queuePlayer?.pause()
            }
        }

        wsCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isPlaying else { return }
                self.queuePlayer?.playImmediately(atRate: self.playbackSpeed)
            }
        }

        wsCenter.addObserver(
            forName: NSWorkspace.sessionDidResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.pauseOnScreenSleep else { return }
                self.queuePlayer?.pause()
            }
        }

        wsCenter.addObserver(
            forName: NSWorkspace.sessionDidBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isPlaying else { return }
                self.queuePlayer?.playImmediately(atRate: self.playbackSpeed)
            }
        }
    }

    @Published public private(set) var isPausedForPowerSavings: Bool = false

    public func pauseForPowerSavings() {
        guard isPlaying, !isPausedForPowerSavings else { return }
        isPausedForPowerSavings = true
        queuePlayer?.pause()
    }

    public func resumeFromPowerSavings() {
        guard isPausedForPowerSavings else { return }
        isPausedForPowerSavings = false
        if isPlaying {
            queuePlayer?.playImmediately(atRate: playbackSpeed)
        }
    }

    public func playVideo(url: URL) {
        stop()

        currentVideoURL = url
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: false])
        let templateItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: ["playable", "tracks", "duration"])
        // Ultra-low RAM footprint: only buffer 1 second of 4K video ahead
        templateItem.preferredForwardBufferDuration = 1.0
        templateItem.canUseNetworkResourcesForLiveStreamingWhilePaused = false

        let player = AVQueuePlayer()
        player.isMuted = isMuted
        player.volume = isMuted ? 0 : Float(volume)
        player.preventsDisplaySleepDuringVideoPlayback = false

        if loopPlayback {
            playerLooper = AVPlayerLooper(player: player, templateItem: templateItem)
        } else {
            player.insert(templateItem, after: nil)
        }

        self.queuePlayer = player
        rebuildWindowsForScreens()

        isPlaying = true
        isPausedForPowerSavings = false

        if EnergyEngine.shared.shouldPausePlayback {
            pauseForPowerSavings()
        } else {
            player.playImmediately(atRate: playbackSpeed)
        }
    }

    public func togglePlayPause() {
        guard let player = queuePlayer else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
            isPausedForPowerSavings = false
        } else {
            player.playImmediately(atRate: playbackSpeed)
            isPlaying = true
            isPausedForPowerSavings = false
        }
    }

    public func stop() {
        queuePlayer?.pause()
        playerLooper?.disableLooping()
        playerLooper = nil
        queuePlayer?.removeAllItems()
        queuePlayer = nil

        for window in windows {
            window.orderOut(nil)
            window.close()
        }
        windows.removeAll()
        containerViews.removeAll()
        isPlaying = false
        isPausedForPowerSavings = false
        currentVideoURL = nil
    }

    private func rebuildWindowsForScreens() {
        guard let player = queuePlayer else { return }

        for window in windows {
            window.orderOut(nil)
            window.close()
        }
        windows.removeAll()
        containerViews.removeAll()

        for screen in NSScreen.screens {
            let window = DesktopWallpaperWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.setFrame(screen.frame, display: true)
            let desktopLevel = Int(CGWindowLevelForKey(.desktopWindow))
            window.level = NSWindow.Level(rawValue: desktopLevel)
            window.collectionBehavior = [
                .canJoinAllSpaces,
                .stationary,
                .ignoresCycle,
                .fullScreenAuxiliary
            ]
            window.isOpaque = true
            window.backgroundColor = .black
            window.ignoresMouseEvents = true
            window.hasShadow = false
            window.isReleasedWhenClosed = false

            let container = PlayerContainerView(player: player, gravity: videoGravity.avGravity)
            container.frame = NSRect(origin: .zero, size: screen.frame.size)
            window.contentView = container
            window.orderFrontRegardless()

            windows.append(window)
            containerViews.append(container)
        }
    }
}
