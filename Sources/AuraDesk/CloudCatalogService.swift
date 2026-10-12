import Foundation
import AppKit

@MainActor
public final class CloudCatalogService: ObservableObject {
    public static let shared = CloudCatalogService()

    @Published public private(set) var allRemoteItems: [RemoteWallpaperItem] = []
    @Published public private(set) var topFeaturedItems: [RemoteWallpaperItem] = []
    @Published public var selectedCategory: String = "All"
    @Published public var selectedSourceFilter: String = "All Sources"
    @Published public var searchQuery: String = ""
    @Published public var downloadingIDs: Set<String> = []
    @Published public var downloadStatusText: [String: String] = [:]
    @Published public var loadedThumbnails: [String: NSImage] = [:]

    private let imageMemoryCache = NSCache<NSString, NSImage>()
    private var inFlightThumbTasks: Set<String> = []

    public let categories = [
        "All", "Top 4K", "Space", "Dark", "Abstract", "Cars", "Anime", "Nature", "Gaming", "Heroes", "Aerial 4K", "Others"
    ]

    public let sources = [
        "All Sources", "Community 4K", "Apple Aerial 4K"
    ]

    private init() {
        loadCatalogs()
    }

    public var filteredItems: [RemoteWallpaperItem] {
        if selectedCategory == "Top 4K" {
            return topFeaturedItems.filter { matchesSearchAndSource($0) }
        }
        return allRemoteItems.filter { item in
            let matchesCat = selectedCategory == "All" || item.category.caseInsensitiveCompare(selectedCategory) == .orderedSame
            return matchesCat && matchesSearchAndSource(item)
        }
    }

    private func matchesSearchAndSource(_ item: RemoteWallpaperItem) -> Bool {
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
        return matchesSource && matchesSearch
    }

    public func loadCatalogs() {
        var community: [RemoteWallpaperItem] = []

        // 1. Load bundled 213+ Community 4K catalog
        if let url = findBundledCatalogURL(),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([RemoteWallpaperItem].self, from: data) {
            community = decoded
        }

        // 2. Load Apple's 137 4K 240FPS Aerial streams from macOS entries.json
        let appleAerials = loadAppleAerial4KStreams()

        // Interleave curated top picks at the very top so users see our best 4K videos immediately
        var featured: [RemoteWallpaperItem] = []
        let preferredCategories = ["Space", "Dark", "Abstract", "Cars", "Nature", "Anime"]
        for cat in preferredCategories {
            let matches = community.filter { $0.category.caseInsensitiveCompare(cat) == .orderedSame }
            featured.append(contentsOf: matches.prefix(2))
        }
        featured.append(contentsOf: appleAerials.prefix(4))

        self.topFeaturedItems = featured
        var combined: [RemoteWallpaperItem] = []
        let featuredIDs = Set(featured.map { $0.id })
        combined.append(contentsOf: featured)
        for item in community where !featuredIDs.contains(item.id) {
            combined.append(item)
        }
        for item in appleAerials where !featuredIDs.contains(item.id) {
            combined.append(item)
        }
        self.allRemoteItems = combined
    }

    private func findBundledCatalogURL() -> URL? {
        if let bundleURL = Bundle.main.url(forResource: "curated_4k_catalog", withExtension: "json") {
            return bundleURL
        }
        let execDir = Bundle.main.bundleURL
        let candidates = [
            execDir.appendingPathComponent("Contents/Resources/curated_4k_catalog.json"),
            execDir.appendingPathComponent("AuraDesk_AuraDesk.bundle/curated_4k_catalog.json"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Sources/AuraDesk/Resources/curated_4k_catalog.json")
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

        for asset in assets.prefix(80) {
            guard let id = asset["id"] as? String,
                  let videoURL = asset["url-4K-SDR-240FPS"] as? String,
                  !videoURL.isEmpty else { continue }

            let locKey = asset["localizedNameKey"] as? String ?? ""
            let label = asset["accessibilityLabel"] as? String ?? "Aerial"
            let name = localizedStrings[locKey] ?? label

            // Prefer local snapshot if macOS already cached it in idleassetsd/snapshots
            let localSnap = "/Library/Application Support/com.apple.idleassetsd/snapshots/asset-preview-\(id).jpg"
            let preview: String
            if FileManager.default.fileExists(atPath: localSnap) {
                preview = URL(fileURLWithPath: localSnap).absoluteString
            } else {
                preview = asset["previewImage"] as? String ?? ""
            }

            results.append(
                RemoteWallpaperItem(
                    id: "aerial-\(id)",
                    name: "\(name) • 4K 240fps",
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

    public static func makeAuthenticatedRequest(for url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        req.timeoutInterval = 45
        req.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        if let host = url.host?.lowercased(), host.contains("macwall.app") {
            req.setValue("https://macwall.app/", forHTTPHeaderField: "Referer")
            req.setValue("https://macwall.app", forHTTPHeaderField: "Origin")
        }
        return req
    }

    public func requestThumbnailIfNeeded(for item: RemoteWallpaperItem) {
        if loadedThumbnails[item.id] != nil { return }
        if let cached = imageMemoryCache.object(forKey: item.id as NSString) {
            loadedThumbnails[item.id] = cached
            return
        }
        guard !inFlightThumbTasks.contains(item.id) else { return }
        inFlightThumbTasks.insert(item.id)

        let diskCacheURL = WallpaperStore.shared.thumbnailsDirectory
            .appendingPathComponent("remote_\(item.id.replacingOccurrences(of: "/", with: "_")).jpg")

        if FileManager.default.fileExists(atPath: diskCacheURL.path),
           let diskImg = NSImage(contentsOf: diskCacheURL) {
            imageMemoryCache.setObject(diskImg, forKey: item.id as NSString)
            loadedThumbnails[item.id] = diskImg
            inFlightThumbTasks.remove(item.id)
            return
        }

        guard let url = URL(string: item.thumbURL), !item.thumbURL.isEmpty else {
            inFlightThumbTasks.remove(item.id)
            return
        }

        if url.isFileURL, let localImg = NSImage(contentsOf: url) {
            imageMemoryCache.setObject(localImg, forKey: item.id as NSString)
            loadedThumbnails[item.id] = localImg
            inFlightThumbTasks.remove(item.id)
            return
        }

        Task {
            defer { self.inFlightThumbTasks.remove(item.id) }
            let session = URLSession(configuration: .default, delegate: InsecureCDNDelegate.shared, delegateQueue: nil)
            let req = Self.makeAuthenticatedRequest(for: url)
            if let (data, resp) = try? await session.data(for: req),
               let http = resp as? HTTPURLResponse,
               (200..<300).contains(http.statusCode),
               let img = NSImage(data: data) {
                try? data.write(to: diskCacheURL)
                self.imageMemoryCache.setObject(img, forKey: item.id as NSString)
                self.loadedThumbnails[item.id] = img
            }
        }
    }

    public func downloadAndImport(
        remoteItem: RemoteWallpaperItem,
        applyMode: ApplyAfterDownloadMode = .desktopOnly
    ) async {
        // If already downloaded in local library, apply immediately without re-downloading!
        if let existing = WallpaperStore.shared.items.first(where: { $0.remoteID == remoteItem.id }) {
            await applyLocalItem(existing, mode: applyMode)
            return
        }

        guard !downloadingIDs.contains(remoteItem.id) else { return }
        guard let videoURL = URL(string: remoteItem.videoURL) else { return }

        downloadingIDs.insert(remoteItem.id)
        downloadStatusText[remoteItem.id] = "Fetching 4K stream..."

        do {
            let session = URLSession(configuration: .default, delegate: InsecureCDNDelegate.shared, delegateQueue: nil)
            let request = Self.makeAuthenticatedRequest(for: videoURL)
            let (tempLocalURL, response) = try await session.download(for: request)

            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw NSError(
                    domain: "AuraDeskCDN",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"]
                )
            }

            let ext = videoURL.pathExtension.isEmpty ? "mp4" : videoURL.pathExtension.lowercased()
            let newUUID = UUID()
            let destURL = WallpaperStore.shared.videosDirectory.appendingPathComponent("\(newUUID.uuidString).\(ext)")
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.moveItem(at: tempLocalURL, to: destURL)

            // Save thumbnail if available
            var thumbPath: String? = nil
            if let tURL = URL(string: remoteItem.thumbURL), !remoteItem.thumbURL.isEmpty {
                if tURL.isFileURL {
                    let savedThumb = WallpaperStore.shared.thumbnailsDirectory.appendingPathComponent("\(newUUID.uuidString).jpg")
                    try? FileManager.default.copyItem(at: tURL, to: savedThumb)
                    thumbPath = savedThumb.path
                } else {
                    let thumbReq = Self.makeAuthenticatedRequest(for: tURL)
                    if let (thumbData, _) = try? await session.data(for: thumbReq) {
                        let savedThumb = WallpaperStore.shared.thumbnailsDirectory.appendingPathComponent("\(newUUID.uuidString).jpg")
                        try? thumbData.write(to: savedThumb)
                        thumbPath = savedThumb.path
                    }
                }
            }

            downloadStatusText[remoteItem.id] = "Preparing 4K Engine..."
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

            await applyLocalItem(localItem, mode: applyMode)
            downloadStatusText.removeValue(forKey: remoteItem.id)
        } catch {
            downloadStatusText[remoteItem.id] = "Retry (\(error.localizedDescription))"
        }

        downloadingIDs.remove(remoteItem.id)
    }

    private func applyLocalItem(_ localItem: WallpaperItem, mode: ApplyAfterDownloadMode) async {
        switch mode {
        case .libraryOnly:
            break
        case .desktopOnly:
            WallpaperStore.shared.setDesktopWallpaper(localItem)
        case .screenSaverOnly:
            WallpaperStore.shared.setScreenSaverWallpaper(localItem)
        case .lockScreenOnly:
            await WallpaperStore.shared.setLockScreenAndAerialScreenSaver(item: localItem, alsoSetNativeDesktop: false)
        case .allThree:
            await WallpaperStore.shared.setAllThree(item: localItem)
        }
    }

    public enum ApplyAfterDownloadMode {
        case libraryOnly
        case desktopOnly
        case screenSaverOnly
        case lockScreenOnly
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
