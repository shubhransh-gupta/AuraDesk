import Foundation
import AppKit

@MainActor
public final class CloudCatalogService: ObservableObject {
    public static let shared = CloudCatalogService()

    @Published public private(set) var allRemoteItems: [RemoteWallpaperItem] = []
    @Published public var selectedCategory: String = "All"
    @Published public var selectedSourceFilter: String = "All Sources"
    @Published public var searchQuery: String = ""
    @Published public var downloadingIDs: Set<String> = []
    @Published public var downloadStatusText: [String: String] = [:]

    public let categories = [
        "All", "Space", "Nature", "Anime", "Cars", "Abstract", "Dark", "Gaming", "Heroes", "Aerial 4K", "Others"
    ]

    public let sources = [
        "All Sources", "Community 4K", "Apple Aerial 4K"
    ]

    private init() {
        loadCatalogs()
    }

    public var filteredItems: [RemoteWallpaperItem] {
        allRemoteItems.filter { item in
            let matchesCat = selectedCategory == "All" || item.category.caseInsensitiveCompare(selectedCategory) == .orderedSame
            let matchesSource = selectedSourceFilter == "All Sources" || item.source == selectedSourceFilter
            let matchesSearch: Bool
            if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                matchesSearch = true
            } else {
                let q = searchQuery.lowercased()
                matchesSearch = item.name.lowercased().contains(q)
                    || item.category.lowercased().contains(q)
                    || item.tags.contains(where: { $0.lowercased().contains(q) })
            }
            return matchesCat && matchesSource && matchesSearch
        }
    }

    public func loadCatalogs() {
        var combined: [RemoteWallpaperItem] = []

        // 1. Load bundled 213+ Community 4K catalog
        if let url = findBundledCatalogURL(),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([RemoteWallpaperItem].self, from: data) {
            combined.append(contentsOf: decoded)
        }

        // 2. Load Apple's 137 4K 240FPS Aerial streams from macOS entries.json
        let appleAerials = loadAppleAerial4KStreams()
        combined.append(contentsOf: appleAerials)

        self.allRemoteItems = combined
    }

    private func findBundledCatalogURL() -> URL? {
        if let bundleURL = Bundle.main.url(forResource: "curated_4k_catalog", withExtension: "json") {
            return bundleURL
        }
        // Fallback for SPM resource bundle
        let execDir = Bundle.main.bundleURL
        let candidates = [
            execDir.appendingPathComponent("Contents/Resources/curated_4k_catalog.json"),
            execDir.appendingPathComponent("AetherWall_AetherWall.bundle/curated_4k_catalog.json"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Sources/AetherWall/Resources/curated_4k_catalog.json")
        ]
        for c in candidates where FileManager.default.fileExists(atPath: c.path) {
            return c
        }
        return nil
    }

    private func loadAppleAerial4KStreams() -> [RemoteWallpaperItem] {
        let entriesPath = "/Library/Application Support/com.apple.idleassetsd/Customer/entries.json"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: entriesPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let assets = json["assets"] as? [[String: Any]] else {
            return []
        }

        let localizedStrings = LockScreenManager.shared.loadLocalizedStrings()
        var results: [RemoteWallpaperItem] = []

        for asset in assets.prefix(60) {
            guard let id = asset["id"] as? String,
                  let videoURL = asset["url-4K-SDR-240FPS"] as? String,
                  !videoURL.isEmpty else { continue }

            let locKey = asset["localizedNameKey"] as? String ?? ""
            let label = asset["accessibilityLabel"] as? String ?? "Aerial"
            let name = localizedStrings[locKey] ?? label
            let preview = asset["previewImage"] as? String ?? ""

            results.append(
                RemoteWallpaperItem(
                    id: "aerial-\(id)",
                    name: "\(name) (240fps 4K)",
                    category: "Aerial 4K",
                    resolution: "3840×2160",
                    durationSeconds: 180.0,
                    fileSizeBytes: 340_000_000,
                    videoURL: videoURL,
                    thumbURL: preview,
                    tags: [label.lowercased(), "aerial", "4k", "240fps", "apple"],
                    source: "Apple Aerial 4K"
                )
            )
        }
        return results
    }

    public func downloadAndImport(
        remoteItem: RemoteWallpaperItem,
        applyMode: ApplyAfterDownloadMode = .desktopOnly
    ) async {
        guard !downloadingIDs.contains(remoteItem.id) else { return }
        guard let videoURL = URL(string: remoteItem.videoURL) else { return }

        downloadingIDs.insert(remoteItem.id)
        downloadStatusText[remoteItem.id] = "Downloading 4K..."

        do {
            // Configure URLSession that accepts Apple's Sylvan CDN as well as public CDNs
            let session = URLSession(configuration: .default, delegate: InsecureCDNDelegate.shared, delegateQueue: nil)
            let (tempLocalURL, _) = try await session.download(from: videoURL)

            let ext = videoURL.pathExtension.isEmpty ? "mp4" : videoURL.pathExtension.lowercased()
            let newUUID = UUID()
            let destURL = WallpaperStore.shared.videosDirectory.appendingPathComponent("\(newUUID.uuidString).\(ext)")
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.moveItem(at: tempLocalURL, to: destURL)

            // Also download thumbnail if available
            var thumbPath: String? = nil
            if let tURL = URL(string: remoteItem.thumbURL), !remoteItem.thumbURL.isEmpty {
                if let (thumbData, _) = try? await session.data(from: tURL) {
                    let savedThumb = WallpaperStore.shared.thumbnailsDirectory.appendingPathComponent("\(newUUID.uuidString).jpg")
                    try? thumbData.write(to: savedThumb)
                    thumbPath = savedThumb.path
                }
            }

            let meta = await WallpaperStore.shared.extractMetadataAndThumbnail(for: destURL, id: newUUID)
            let finalThumb = thumbPath ?? meta.thumbnailPath

            let localItem = WallpaperItem(
                id: newUUID,
                remoteID: remoteItem.id,
                title: remoteItem.name,
                category: remoteItem.category,
                filePath: destURL.path,
                thumbnailPath: finalThumb,
                durationSeconds: meta.duration > 0 ? meta.duration : remoteItem.durationSeconds,
                resolution: remoteItem.resolution,
                fileSizeMB: meta.fileSizeMB > 0 ? meta.fileSizeMB : remoteItem.fileSizeMB
            )

            WallpaperStore.shared.items.insert(localItem, at: 0)
            WallpaperStore.shared.saveState()

            switch applyMode {
            case .libraryOnly:
                break
            case .desktopOnly:
                WallpaperStore.shared.setDesktopWallpaper(localItem)
            case .allThree:
                await WallpaperStore.shared.setAllThree(item: localItem)
            }

            downloadStatusText.removeValue(forKey: remoteItem.id)
        } catch {
            downloadStatusText[remoteItem.id] = "Failed: \(error.localizedDescription)"
        }

        downloadingIDs.remove(remoteItem.id)
    }

    public enum ApplyAfterDownloadMode {
        case libraryOnly
        case desktopOnly
        case allThree
    }
}

final class InsecureCDNDelegate: NSObject, URLSessionDelegate, Sendable {
    static let shared = InsecureCDNDelegate()

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
