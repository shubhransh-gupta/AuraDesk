import AppKit
import AVFoundation
import SwiftUI

final class ScreenSaverWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class ScreenSaverOverlayView: NSView {
    let playerLayer: AVPlayerLayer
    var onUserInteraction: (() -> Void)?
    private var clockTimer: Timer?
    private let timeLabel = NSTextField(labelWithString: "")
    private let dateLabel = NSTextField(labelWithString: "")
    private var initialMouseLocation: NSPoint?

    init(player: AVPlayer, gravity: AVLayerVideoGravity, showClock: Bool) {
        self.playerLayer = AVPlayerLayer(player: player)
        super.init(frame: .zero)
        self.wantsLayer = true
        self.playerLayer.videoGravity = gravity
        self.playerLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        self.layer?.addSublayer(self.playerLayer)

        if showClock {
            setupClockOverlay()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupClockOverlay() {
        timeLabel.font = NSFont.systemFont(ofSize: 82, weight: .semibold)
        timeLabel.textColor = NSColor.white.withAlphaComponent(0.92)
        timeLabel.alignment = .center
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        let shadow = NSShadow()
        shadow.shadowBlurRadius = 16
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.55)
        shadow.shadowOffset = NSSize(width: 0, height: -2)
        timeLabel.shadow = shadow

        dateLabel.font = NSFont.systemFont(ofSize: 22, weight: .medium)
        dateLabel.textColor = NSColor.white.withAlphaComponent(0.85)
        dateLabel.alignment = .center
        dateLabel.shadow = shadow
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(timeLabel)
        addSubview(dateLabel)

        NSLayoutConstraint.activate([
            dateLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            dateLabel.topAnchor.constraint(equalTo: topAnchor, constant: 96),
            timeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            timeLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4)
        ])

        updateClockText()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateClockText()
        }
    }

    private func updateClockText() {
        let now = Date()
        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"
        timeLabel.stringValue = tf.string(from: now)

        let df = DateFormatter()
        df.dateFormat = "EEEE, MMMM d"
        dateLabel.stringValue = df.string(from: now)
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        onUserInteraction?()
    }

    override func mouseDown(with event: NSEvent) {
        onUserInteraction?()
    }

    override func mouseMoved(with event: NSEvent) {
        let loc = NSEvent.mouseLocation
        if let initial = initialMouseLocation {
            let dist = hypot(loc.x - initial.x, loc.y - initial.y)
            if dist > 18 {
                onUserInteraction?()
            }
        } else {
            initialMouseLocation = loc
        }
    }

    deinit {
        clockTimer?.invalidate()
    }
}

@MainActor
public final class ScreenSaverController: ObservableObject {
    public static let shared = ScreenSaverController()

    @Published public private(set) var isActive: Bool = false
    @Published public var idleTimeoutMinutes: Double = 0
    @Published public var showClockOnScreenSaver: Bool = true

    private var windows: [ScreenSaverWindow] = []
    private var queuePlayer: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var idleCheckTimer: Timer?
    private var activeVideoURL: URL?

    private init() {
        startIdleMonitor()
    }

    public func setScreenSaverVideo(url: URL?) {
        self.activeVideoURL = url
    }

    private func startIdleMonitor() {
        idleCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkSystemIdleTime()
            }
        }
    }

    private func checkSystemIdleTime() {
        guard idleTimeoutMinutes > 0, !isActive else { return }
        guard let url = activeVideoURL ?? DesktopWallpaperController.shared.currentVideoURL else { return }

        let idleSeconds = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: CGEventType(rawValue: ~0)!
        )

        if idleSeconds >= idleTimeoutMinutes * 60.0 {
            startScreenSaver(with: url)
        }
    }

    public func startScreenSaver(with url: URL) {
        guard !isActive else { return }
        isActive = true

        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let templateItem = AVPlayerItem(asset: asset)

        let player = AVQueuePlayer()
        player.isMuted = true
        playerLooper = AVPlayerLooper(player: player, templateItem: templateItem)
        self.queuePlayer = player

        NSCursor.hide()

        for (index, screen) in NSScreen.screens.enumerated() {
            let window = ScreenSaverWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.setFrame(screen.frame, display: true)
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.isOpaque = true
            window.backgroundColor = .black
            window.acceptsMouseMovedEvents = true
            window.isReleasedWhenClosed = false

            let view = ScreenSaverOverlayView(
                player: player,
                gravity: DesktopWallpaperController.shared.videoGravity.avGravity,
                showClock: showClockOnScreenSaver && index == 0
            )
            view.frame = NSRect(origin: .zero, size: screen.frame.size)
            view.onUserInteraction = { [weak self] in
                Task { @MainActor in
                    self?.stopScreenSaver()
                }
            }
            window.contentView = view
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(view)
            windows.append(window)
        }

        NSApp.activate(ignoringOtherApps: true)
        player.play()
    }

    public func stopScreenSaver() {
        guard isActive else { return }
        isActive = false
        NSCursor.unhide()

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
    }
}
