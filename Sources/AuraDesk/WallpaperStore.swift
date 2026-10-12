import Foundation
import AVFoundation
import AppKit
import SwiftUI

@MainActor
public final class WallpaperStore: ObservableObject {
    public static let shared = WallpaperStore()

    @Published public var items: [WallpaperItem] = []
    @Published public var activeDesktopID: UUID? {
        didSet { saveState() }
    }
    @Published public var activeScreenSaverID: UUID? {
        didSet { saveState() }
    }
    @Published public var activeLockScreenID: UUID? {
        didSet { saveState() }
    }

    @Published public var isMuted: Bool = true {
        didSet {
            DesktopWallpaperController.shared.isMuted = isMuted
            saveState()
        }
    }

    @Published public var volume: Double = 0.5 {
        didSet {
            DesktopWallpaperController.shared.volume = volume
            saveState()
        }
    }

    @Published public var loopPlayback: Bool = true {
        didSet {
            DesktopWallpaperController.shared.loopPlayback = loopPlayback
            saveState()
        }
    }

    @Published public var videoGravity: VideoGravityMode = .aspectFill {
        didSet {
            DesktopWallpaperController.shared.videoGravity = videoGravity
            saveState()
        }
    }

    @Published public var playbackSpeed: Float = 1.0 {
        didSet {
            DesktopWallpaperController.shared.playbackSpeed = playbackSpeed
            saveState()
        }
    }

    @Published public var pauseOnScreenSleep: Bool = true {
        didSet {
            DesktopWallpaperController.shared.pauseOnScreenSleep = pauseOnScreenSleep
            saveState()
        }
    }

    @Published public var isGeneratingSample: Bool = false
    @Published public var selectedSection: ContentView.SidebarSection = .discover4K
    @Published public var isDropTargeted: Bool = false

    private let defaults = UserDefaults.standard
    private let itemsKey = "auradesk.wallpaper.items.v1"

    public var appStorageDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("AuraDesk", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    public var thumbnailsDirectory: URL {
        let dir = appStorageDirectory.appendingPathComponent("Thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    public var videosDirectory: URL {
        let dir = appStorageDirectory.appendingPathComponent("Videos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private init() {
        loadState()
        restoreActivePlaybackOnLaunch()
    }

    private func loadState() {
        isMuted = defaults.object(forKey: "auradesk.isMuted") as? Bool ?? true
        volume = defaults.object(forKey: "auradesk.volume") as? Double ?? 0.5
        loopPlayback = defaults.object(forKey: "auradesk.loopPlayback") as? Bool ?? true
        if let gravRaw = defaults.string(forKey: "auradesk.videoGravity"),
           let mode = VideoGravityMode(rawValue: gravRaw) {
            videoGravity = mode
        }
        playbackSpeed = defaults.object(forKey: "auradesk.playbackSpeed") as? Float ?? 1.0
        pauseOnScreenSleep = defaults.object(forKey: "auradesk.pauseOnScreenSleep") as? Bool ?? true

        DesktopWallpaperController.shared.isMuted = isMuted
        DesktopWallpaperController.shared.volume = volume
        DesktopWallpaperController.shared.loopPlayback = loopPlayback
        DesktopWallpaperController.shared.videoGravity = videoGravity
        DesktopWallpaperController.shared.playbackSpeed = playbackSpeed
        DesktopWallpaperController.shared.pauseOnScreenSleep = pauseOnScreenSleep

        if let data = defaults.data(forKey: itemsKey),
           let decoded = try? JSONDecoder().decode([WallpaperItem].self, from: data) {
            self.items = decoded.filter { FileManager.default.fileExists(atPath: $0.filePath) }
        }

        if let idStr = defaults.string(forKey: "auradesk.activeDesktopID") {
            activeDesktopID = UUID(uuidString: idStr)
        }
        if let idStr = defaults.string(forKey: "auradesk.activeScreenSaverID") {
            activeScreenSaverID = UUID(uuidString: idStr)
        }
        if let idStr = defaults.string(forKey: "auradesk.activeLockScreenID") {
            activeLockScreenID = UUID(uuidString: idStr)
        }
    }

    public func saveState() {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: itemsKey)
        }
        defaults.set(isMuted, forKey: "auradesk.isMuted")
        defaults.set(volume, forKey: "auradesk.volume")
        defaults.set(loopPlayback, forKey: "auradesk.loopPlayback")
        defaults.set(videoGravity.rawValue, forKey: "auradesk.videoGravity")
        defaults.set(playbackSpeed, forKey: "auradesk.playbackSpeed")
        defaults.set(pauseOnScreenSleep, forKey: "auradesk.pauseOnScreenSleep")
        defaults.set(activeDesktopID?.uuidString, forKey: "auradesk.activeDesktopID")
        defaults.set(activeScreenSaverID?.uuidString, forKey: "auradesk.activeScreenSaverID")
        defaults.set(activeLockScreenID?.uuidString, forKey: "auradesk.activeLockScreenID")
    }

    private func restoreActivePlaybackOnLaunch() {
        if let desktopID = activeDesktopID,
           let item = items.first(where: { $0.id == desktopID }) {
            DesktopWallpaperController.shared.playVideo(url: item.fileURL)
        }
        if let saverID = activeScreenSaverID,
           let item = items.first(where: { $0.id == saverID }) {
            ScreenSaverController.shared.setScreenSaverVideo(url: item.fileURL)
        }
    }

    public func importVideoFiles(urls: [URL]) async {
        for sourceURL in urls {
            let accessing = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if accessing { sourceURL.stopAccessingSecurityScopedResource() }
            }

            let ext = sourceURL.pathExtension.lowercased()
            guard ["mp4", "mov", "m4v"].contains(ext) else { continue }

            let id = UUID()
            let destFileName = "\(id.uuidString).\(ext)"
            let destURL = videosDirectory.appendingPathComponent(destFileName)

            do {
                try FileManager.default.copyItem(at: sourceURL, to: destURL)
                let metadata = await extractMetadataAndThumbnail(for: destURL, id: id)
                let title = sourceURL.deletingPathExtension().lastPathComponent
                let newItem = WallpaperItem(
                    id: id,
                    title: title,
                    category: "Imported",
                    filePath: destURL.path,
                    thumbnailPath: metadata.thumbnailPath,
                    durationSeconds: metadata.duration,
                    resolution: metadata.resolution,
                    fileSizeMB: metadata.fileSizeMB
                )
                items.insert(newItem, at: 0)
                saveState()

                if activeDesktopID == nil {
                    setDesktopWallpaper(newItem)
                }
            } catch {
                print("Error importing video: \(error)")
            }
        }
    }

    public func deleteItem(_ item: WallpaperItem) {
        if activeDesktopID == item.id {
            DesktopWallpaperController.shared.stop()
            activeDesktopID = nil
        }
        if activeScreenSaverID == item.id {
            ScreenSaverController.shared.setScreenSaverVideo(url: nil)
            activeScreenSaverID = nil
        }
        if activeLockScreenID == item.id {
            activeLockScreenID = nil
        }

        try? FileManager.default.removeItem(at: item.fileURL)
        if let thumb = item.thumbnailURL {
            try? FileManager.default.removeItem(at: thumb)
        }
        items.removeAll { $0.id == item.id }
        saveState()
    }

    public func setDesktopWallpaper(_ item: WallpaperItem) {
        activeDesktopID = item.id
        DesktopWallpaperController.shared.playVideo(url: item.fileURL)
    }

    public func setScreenSaverWallpaper(_ item: WallpaperItem) {
        activeScreenSaverID = item.id
        ScreenSaverController.shared.setScreenSaverVideo(url: item.fileURL)
    }

    public func setAllThree(item: WallpaperItem) async {
        setDesktopWallpaper(item)
        setScreenSaverWallpaper(item)
        await setLockScreenAndAerialScreenSaver(item: item, alsoSetNativeDesktop: false)
    }

    public func setLockScreenAndAerialScreenSaver(item: WallpaperItem, alsoSetNativeDesktop: Bool = false) async {
        await LockScreenManager.shared.applyToLockScreenAndScreenSaver(
            item: item,
            alsoSetNativeDesktop: alsoSetNativeDesktop
        )
        if !LockScreenManager.shared.statusIsError {
            activeLockScreenID = item.id
            activeScreenSaverID = item.id
            ScreenSaverController.shared.setScreenSaverVideo(url: item.fileURL)
        }
    }

    public func extractMetadataAndThumbnail(
        for url: URL,
        id: UUID
    ) async -> (thumbnailPath: String?, duration: Double, resolution: String, fileSizeMB: Double) {
        let asset = AVURLAsset(url: url)
        var durationSeconds: Double = 0
        if let cmDuration = try? await asset.load(.duration) {
            durationSeconds = CMTimeGetSeconds(cmDuration)
            if durationSeconds.isNaN || durationSeconds.isInfinite {
                durationSeconds = 0
            }
        }

        var resolutionLabel = "4K UHD"
        if let tracks = try? await asset.loadTracks(withMediaType: .video),
           let track = tracks.first,
           let size = try? await track.load(.naturalSize) {
            let width = Int(abs(size.width))
            let height = Int(abs(size.height))
            let maxDim = max(width, height)
            if maxDim >= 3800 {
                resolutionLabel = "4K UHD"
            } else if maxDim >= 2500 {
                resolutionLabel = "2K QHD"
            } else if maxDim >= 1900 {
                resolutionLabel = "1080p"
            } else if width > 0 && height > 0 {
                resolutionLabel = "\(width)×\(height)"
            }
        }

        var fileSizeMB: Double = 0
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let fileSize = attrs[.size] as? UInt64 {
            fileSizeMB = Double(fileSize) / (1024.0 * 1024.0)
        }

        var thumbPath: String? = nil
        let existingThumb = thumbnailsDirectory.appendingPathComponent("\(id.uuidString).jpg")
        if FileManager.default.fileExists(atPath: existingThumb.path) {
            thumbPath = existingThumb.path
        } else {
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 960, height: 540)

            let snapTime = CMTime(seconds: min(1.0, max(0.1, durationSeconds * 0.15)), preferredTimescale: 600)
            if let cgImage = try? generator.copyCGImage(at: snapTime, actualTime: nil) {
                let rep = NSBitmapImageRep(cgImage: cgImage)
                if let jpegData = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.85]) {
                    try? jpegData.write(to: existingThumb)
                    thumbPath = existingThumb.path
                }
            }
        }

        return (thumbPath, durationSeconds, resolutionLabel, fileSizeMB)
    }

    public func generateSample4KVideo() async {
        guard !isGeneratingSample else { return }
        isGeneratingSample = true
        defer { isGeneratingSample = false }

        let id = UUID()
        let outputURL = videosDirectory.appendingPathComponent("\(id.uuidString).mov")

        do {
            try await Task.detached(priority: .userInitiated) {
                try Self.renderProcedural4KMov(to: outputURL)
            }.value

            let meta = await extractMetadataAndThumbnail(for: outputURL, id: id)
            let sampleItem = WallpaperItem(
                id: id,
                title: "AuraDesk Neon Saffron Horizon (4K)",
                category: "Synthesized 4K",
                filePath: outputURL.path,
                thumbnailPath: meta.thumbnailPath,
                durationSeconds: meta.duration,
                resolution: meta.resolution,
                fileSizeMB: meta.fileSizeMB
            )
            items.insert(sampleItem, at: 0)
            saveState()
            setDesktopWallpaper(sampleItem)
            setScreenSaverWallpaper(sampleItem)
            selectedSection = .myLibrary
        } catch {
            print("Failed to generate sample 4K video: \(error)")
        }
    }

    nonisolated private static func renderProcedural4KMov(to outputURL: URL) throws {
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        let width = 3840
        let height = 2160
        let fps: Int32 = 30
        let durationSeconds = 5
        let totalFrames = Int(fps) * durationSeconds

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.hevc,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 16_000_000
            ]
        ]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writerInput.expectsMediaDataInRealTime = false

        let sourceBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: sourceBufferAttributes
        )

        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        for frameIdx in 0..<totalFrames {
            while !writerInput.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.005)
            }

            guard let pool = adaptor.pixelBufferPool else { continue }
            var pixelBufferOut: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBufferOut)
            guard let pixelBuffer = pixelBufferOut else { continue }

            CVPixelBufferLockBaseAddress(pixelBuffer, [])
            if let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) {
                let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
                if let ctx = CGContext(
                    data: baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
                ) {
                    let progress = Double(frameIdx) / Double(totalFrames)
                    let angle = progress * 2.0 * .pi

                    let c1 = CGColor(
                        red: 0.02,
                        green: 0.01,
                        blue: 0.005,
                        alpha: 1.0
                    )
                    let c2 = CGColor(
                        red: 0.22 + 0.08 * cos(angle),
                        green: 0.08 + 0.04 * sin(angle),
                        blue: 0.01,
                        alpha: 1.0
                    )
                    let c3 = CGColor(
                        red: 0.75 + 0.20 * sin(angle + 0.8),
                        green: 0.30 + 0.12 * cos(angle + 0.6),
                        blue: 0.02,
                        alpha: 1.0
                    )

                    if let grad = CGGradient(
                        colorsSpace: colorSpace,
                        colors: [c1, c2, c3] as CFArray,
                        locations: [0.0, 0.60, 1.0]
                    ) {
                        let startPt = CGPoint(
                            x: Double(width) * (0.25 + 0.2 * cos(angle)),
                            y: Double(height) * (0.15 + 0.15 * sin(angle))
                        )
                        let endPt = CGPoint(
                            x: Double(width) * (0.75 + 0.2 * sin(angle)),
                            y: Double(height) * (0.85 + 0.15 * cos(angle))
                        )
                        ctx.drawLinearGradient(
                            grad,
                            start: startPt,
                            end: endPt,
                            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
                        )
                    }

                    let orbCenter = CGPoint(
                        x: Double(width) * (0.5 + 0.28 * sin(angle)),
                        y: Double(height) * (0.5 + 0.22 * cos(angle))
                    )
                    let orbColors = [
                        CGColor(red: 1.0, green: 0.45, blue: 0.0, alpha: 0.55),
                        CGColor(red: 1.0, green: 0.60, blue: 0.15, alpha: 0.0)
                    ] as CFArray
                    if let radial = CGGradient(colorsSpace: colorSpace, colors: orbColors, locations: [0.0, 1.0]) {
                        ctx.drawRadialGradient(
                            radial,
                            startCenter: orbCenter,
                            startRadius: 10,
                            endCenter: orbCenter,
                            endRadius: CGFloat(width) * 0.42,
                            options: []
                        )
                    }
                }
            }
            CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

            let presentationTime = CMTime(value: CMTimeValue(frameIdx), timescale: fps)
            adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
        }

        writerInput.markAsFinished()
        let semaphore = DispatchSemaphore(value: 0)
        writer.finishWriting {
            semaphore.signal()
        }
        semaphore.wait()
    }
}
