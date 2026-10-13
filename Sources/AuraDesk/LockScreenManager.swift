import Foundation
import AVFoundation
import AppKit

@MainActor
public final class LockScreenManager: ObservableObject {
    public static let shared = LockScreenManager()

    // Modern macOS (Sequoia 15+, Tahoe 16/26+) user-level Aerial directories:
    private var userAerialsDir: String {
        (NSHomeDirectory() as NSString).appendingPathComponent("Library/Application Support/com.apple.wallpaper/aerials/videos")
    }
    private var userManifestDir: String {
        (NSHomeDirectory() as NSString).appendingPathComponent("Library/Application Support/com.apple.wallpaper/aerials/manifest")
    }
    private var userEntriesPath: String {
        "\(userManifestDir)/entries.json"
    }

    // System bundled Aerial directories and entries:
    private let systemExtensionEntriesPath = "/System/Library/ExtensionKit/Extensions/WallpaperAerialsExtension.appex/Contents/Resources/entries.json"
    private let systemCustomerDir = "/Library/Application Support/com.apple.idleassetsd/Customer"
    private let systemAerials4KDir = "/Library/Application Support/com.apple.idleassetsd/Customer/4KSDR240FPS"
    private let systemEntriesPath = "/Library/Application Support/com.apple.idleassetsd/Customer/entries.json"

    // Index.plist where macOS stores current active wallpaper and aerial preferences
    private var wallpaperStoreIndexPlistPath: String {
        (NSHomeDirectory() as NSString).appendingPathComponent("Library/Application Support/com.apple.wallpaper/Store/Index.plist")
    }

    @Published public private(set) var availableTargets: [AerialTargetAsset] = []
    @Published public var selectedTargetID: String = ""
    @Published public var isBusy: Bool = false
    @Published public var statusMessage: String?
    @Published public var statusIsError: Bool = false

    private init() {
        refreshTargets()
    }

    public var backupDirectoryURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("AuraDesk/AerialBackups", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    public func refreshTargets() {
        var nameMap: [String: (name: String, category: String)] = [:]
        let localizedStrings = loadLocalizedStrings()

        // 1. Scan user entries, system extension bundled entries, and customer entries
        let manifestPaths = [userEntriesPath, systemExtensionEntriesPath, systemEntriesPath]
        for path in manifestPaths {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let assets = json["assets"] as? [[String: Any]] {
                for asset in assets {
                    if let id = asset["id"] as? String {
                        let locKey = asset["localizedNameKey"] as? String ?? ""
                        let fallback = asset["accessibilityLabel"] as? String ?? asset["shotID"] as? String ?? id
                        let resolvedName = localizedStrings[locKey] ?? fallback
                        let category = asset["accessibilityLabel"] as? String ?? "Aerial"
                        if nameMap[id] == nil {
                            nameMap[id] = (resolvedName, category)
                        }
                    }
                }
            }
        }

        var targets: [AerialTargetAsset] = []
        var seenIDs = Set<String>()
        let fm = FileManager.default

        // 2. Scan user aerials folder (~/Library/Application Support/com.apple.wallpaper/aerials/videos)
        if let userFiles = try? fm.contentsOfDirectory(atPath: userAerialsDir) {
            for file in userFiles where file.hasSuffix(".mov") {
                let assetID = (file as NSString).deletingPathExtension
                let fullPath = (userAerialsDir as NSString).appendingPathComponent(file)
                let backupURL = backupDirectoryURL.appendingPathComponent(file)
                let info = nameMap[assetID]
                seenIDs.insert(assetID)
                targets.append(
                    AerialTargetAsset(
                        id: assetID,
                        name: info?.name ?? "Aerial (\(assetID.prefix(8)))",
                        category: info?.category ?? "User Aerial",
                        filePath: fullPath,
                        isDownloaded: true,
                        hasBackup: fm.fileExists(atPath: backupURL.path)
                    )
                )
            }
        }

        // 3. Scan system aerials folder (/Library/Application Support/com.apple.idleassetsd/Customer/4KSDR240FPS)
        if let sysFiles = try? fm.contentsOfDirectory(atPath: systemAerials4KDir) {
            for file in sysFiles where file.hasSuffix(".mov") {
                let assetID = (file as NSString).deletingPathExtension
                guard !seenIDs.contains(assetID) else { continue }
                let fullPath = (systemAerials4KDir as NSString).appendingPathComponent(file)
                let backupURL = backupDirectoryURL.appendingPathComponent(file)
                let info = nameMap[assetID]
                seenIDs.insert(assetID)
                targets.append(
                    AerialTargetAsset(
                        id: assetID,
                        name: info?.name ?? "Aerial (\(assetID.prefix(8)))",
                        category: info?.category ?? "System Aerial",
                        filePath: fullPath,
                        isDownloaded: true,
                        hasBackup: fm.fileExists(atPath: backupURL.path)
                    )
                )
            }
        }

        // 4. Always provide universal standard Aerial candidate slots from nameMap
        let defaults = [
            "4207734D-74FE-4F92-B5E1-6EC8DEE24A15", // Golden Gate Sunset (Standard Default)
            "9680B8EB-CE2A-4395-AF41-402801F4D6A6", // Dubai (Standard Customer)
            "009BA758-7060-4479-8EE8-FB9B40C8FB97", // Korea and Japan Night
            "29BDF297-EB43-403A-8719-A78DA11A2948", // San Francisco
            "81CA5ACD-E682-4D8B-A948-0F147EB6ED4F"  // Yosemite
        ]
        for id in defaults where !seenIDs.contains(id) {
            let info = nameMap[id] ?? ("macOS Aerial (\(id.prefix(8)))", "Aerial 4K")
            let fullPath = (userAerialsDir as NSString).appendingPathComponent("\(id).mov")
            let backupURL = backupDirectoryURL.appendingPathComponent("\(id).mov")
            seenIDs.insert(id)
            targets.append(
                AerialTargetAsset(
                    id: id,
                    name: info.name,
                    category: info.category,
                    filePath: fullPath,
                    isDownloaded: false,
                    hasBackup: fm.fileExists(atPath: backupURL.path)
                )
            )
        }

        targets.sort { $0.name < $1.name }
        self.availableTargets = targets

        // 5. Default selectedTargetID: check Index.plist for currently configured assetID!
        let activeConfiguredID = readCurrentConfiguredAssetID()
        if let active = activeConfiguredID, targets.contains(where: { $0.id == active }) {
            selectedTargetID = active
        } else if selectedTargetID.isEmpty || !targets.contains(where: { $0.id == selectedTargetID }) {
            selectedTargetID = targets.first(where: { $0.isDownloaded })?.id ?? targets.first?.id ?? "4207734D-74FE-4F92-B5E1-6EC8DEE24A15"
        }
    }

    public func readCurrentConfiguredAssetID() -> String? {
        guard FileManager.default.fileExists(atPath: wallpaperStoreIndexPlistPath),
              let rawData = try? Data(contentsOf: URL(fileURLWithPath: wallpaperStoreIndexPlistPath)),
              let root = try? PropertyListSerialization.propertyList(from: rawData, options: [], format: nil) as? [String: Any],
              let allSpaces = root["AllSpacesAndDisplays"] as? [String: Any],
              let idle = allSpaces["Idle"] as? [String: Any],
              let content = idle["Content"] as? [String: Any],
              let choices = content["Choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let configData = firstChoice["Configuration"] as? Data,
              let configDict = try? PropertyListSerialization.propertyList(from: configData, options: [], format: nil) as? [String: Any],
              let assetID = configDict["assetID"] as? String else {
            return nil
        }
        return assetID
    }

    public func loadLocalizedStrings() -> [String: String] {
        let candidateBundles = [
            "\(userManifestDir)/TVIdleScreenStrings.bundle",
            "\(systemCustomerDir)/TVIdleScreenStrings.bundle"
        ]
        let preferredLangs = ["en.lproj", "en_US.lproj", "en_GB.lproj", "en_AU.lproj", "Base.lproj"]
        let fm = FileManager.default

        for bundlePath in candidateBundles {
            guard fm.fileExists(atPath: bundlePath) else { continue }
            for lang in preferredLangs {
                let path = "\(bundlePath)/\(lang)/Localizable.nocache.strings"
                if fm.fileExists(atPath: path),
                   let dict = NSDictionary(contentsOfFile: path) as? [String: String] {
                    return dict
                }
            }
            if let subdirs = try? fm.contentsOfDirectory(atPath: bundlePath) {
                for sub in subdirs where sub.hasSuffix(".lproj") {
                    let path = "\(bundlePath)/\(sub)/Localizable.nocache.strings"
                    if fm.fileExists(atPath: path),
                       let dict = NSDictionary(contentsOfFile: path) as? [String: String] {
                        return dict
                    }
                }
            }
        }
        return [:]
    }

    public func applyToLockScreenAndScreenSaver(
        item: WallpaperItem,
        alsoSetNativeDesktop: Bool = false
    ) async {
        guard !isBusy else { return }
        isBusy = true
        statusIsError = false
        statusMessage = "Preparing 4K video for Lock Screen & Screen Saver..."

        // Choose target ID (e.g. 4207734D-74FE-4F92-B5E1-6EC8DEE24A15)
        let targetID: String
        if !selectedTargetID.isEmpty {
            targetID = selectedTargetID
        } else if let active = readCurrentConfiguredAssetID() {
            targetID = active
        } else if let firstDownloaded = availableTargets.first(where: { $0.isDownloaded }) {
            targetID = firstDownloaded.id
        } else {
            targetID = "4207734D-74FE-4F92-B5E1-6EC8DEE24A15"
        }

        let fm = FileManager.default
        let backupMovURL = backupDirectoryURL.appendingPathComponent("\(targetID).mov")

        do {
            let preparedMovURL = try await prepareCompatibleMovFile(from: item.fileURL)

            statusMessage = "Backing up original Apple asset..."
            let userTargetMovPath = "\(userAerialsDir)/\(targetID).mov"
            let sysTargetMovPath = "\(systemAerials4KDir)/\(targetID).mov"

            // 1. Back up existing asset if not already backed up
            if fm.fileExists(atPath: userTargetMovPath) && !fm.fileExists(atPath: backupMovURL.path) {
                try? fm.copyItem(atPath: userTargetMovPath, toPath: backupMovURL.path)
            } else if fm.fileExists(atPath: sysTargetMovPath) && !fm.fileExists(atPath: backupMovURL.path) {
                try? fm.copyItem(atPath: sysTargetMovPath, toPath: backupMovURL.path)
            }

            statusMessage = "Installing 4K video to macOS Aerial pipeline..."
            // 2. Ensure user aerial directory exists (~/Library/Application Support/com.apple.wallpaper/aerials/videos)
            try? fm.createDirectory(atPath: userAerialsDir, withIntermediateDirectories: true)

            // Direct user-space copy (Instant, NO ADMIN PERMISSION PROMPT NEEDED!)
            if fm.fileExists(atPath: userTargetMovPath) {
                try? fm.removeItem(atPath: userTargetMovPath)
            }
            try fm.copyItem(atPath: preparedMovURL.path, toPath: userTargetMovPath)
            // Ensure file has world-readable permissions (0o644) so wallpaper daemons running under system/sandbox contexts can read it
            try? fm.setAttributes([.posixPermissions: 0o644], ofItemAtPath: userTargetMovPath)

            // 3. If system directory also exists and is writable, copy there too
            if fm.fileExists(atPath: systemAerials4KDir) && fm.isWritableFile(atPath: systemAerials4KDir) {
                let sysDest = "\(systemAerials4KDir)/\(targetID).mov"
                if fm.fileExists(atPath: sysDest) { try? fm.removeItem(atPath: sysDest) }
                try? fm.copyItem(atPath: preparedMovURL.path, toPath: sysDest)
                try? fm.setAttributes([.posixPermissions: 0o644], ofItemAtPath: sysDest)
            }

            // 4. Configure Index.plist for Lock Screen & Screen Saver
            statusMessage = "Configuring macOS Lock Screen preference..."
            try updateWallpaperStoreIndexPlist(assetID: targetID, alsoSetDesktop: alsoSetNativeDesktop)

            // 5. Ensure macOS screensaver defaults point to WallpaperAerialsExtension
            configureSystemScreensaverDefaults()

            // 6. Restart macOS wallpaper daemons cleanly
            statusMessage = "Refreshing native macOS Lock Screen & Screen Saver..."
            restartWallpaperDaemons()

            refreshTargets()
            let targetName = availableTargets.first(where: { $0.id == targetID })?.name ?? targetID
            statusIsError = false
            statusMessage = "Active on Lock Screen & Saver: '\(item.title)' (via \(targetName))"
        } catch {
            statusIsError = true
            statusMessage = "Lock Screen error: \(error.localizedDescription)"
        }

        isBusy = false
    }

    public func restoreOriginalAerial() async {
        guard !isBusy else { return }
        let targetID = selectedTargetID.isEmpty ? (readCurrentConfiguredAssetID() ?? "4207734D-74FE-4F92-B5E1-6EC8DEE24A15") : selectedTargetID
        let backupMovURL = backupDirectoryURL.appendingPathComponent("\(targetID).mov")
        let userTargetMovPath = "\(userAerialsDir)/\(targetID).mov"
        let sysTargetMovPath = "\(systemAerials4KDir)/\(targetID).mov"

        guard FileManager.default.fileExists(atPath: backupMovURL.path) else {
            statusIsError = true
            statusMessage = "No backup found for Aerial slot \(targetID.prefix(8))."
            return
        }

        isBusy = true
        statusIsError = false
        statusMessage = "Restoring original Apple Aerial video..."

        do {
            let fm = FileManager.default
            if fm.fileExists(atPath: userTargetMovPath) {
                try? fm.removeItem(atPath: userTargetMovPath)
            }
            try fm.copyItem(atPath: backupMovURL.path, toPath: userTargetMovPath)
            try? fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: userTargetMovPath)

            if fm.fileExists(atPath: sysTargetMovPath) && fm.isWritableFile(atPath: sysTargetMovPath) {
                try? fm.removeItem(atPath: sysTargetMovPath)
                try? fm.copyItem(atPath: backupMovURL.path, toPath: sysTargetMovPath)
            }

            try? fm.removeItem(at: backupMovURL)
            restartWallpaperDaemons()
            refreshTargets()
            statusMessage = "Original Apple Lock Screen video restored!"
        } catch {
            statusIsError = true
            statusMessage = "Restore failed: \(error.localizedDescription)"
        }

        isBusy = false
    }

    private func prepareCompatibleMovFile(from sourceURL: URL) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("AuraDeskStaging", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let outputURL = tempDir.appendingPathComponent("staged_lockscreen.mov")
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        // 1. Look for ffmpeg on the system for ultra-fast, robust remuxing
        let ffmpegPaths = ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"]
        let ffmpegPath = ffmpegPaths.first { FileManager.default.isExecutableFile(atPath: $0) }

        if let ffmpeg = ffmpegPath {
            // First try fast zero-reencode remux with video copy and audio strip (-an)
            let remuxProcess = Process()
            remuxProcess.executableURL = URL(fileURLWithPath: ffmpeg)
            remuxProcess.arguments = [
                "-y",
                "-i", sourceURL.path,
                "-c:v", "copy",
                "-an",
                "-movflags", "+faststart",
                outputURL.path
            ]
            let pipe = Pipe()
            remuxProcess.standardError = pipe
            remuxProcess.standardOutput = pipe

            do {
                try remuxProcess.run()
                remuxProcess.waitUntilExit()
                if remuxProcess.terminationStatus == 0 && FileManager.default.fileExists(atPath: outputURL.path) {
                    let attrs = try FileManager.default.attributesOfItem(atPath: outputURL.path)
                    if let size = attrs[.size] as? Int64, size > 1024 {
                        return outputURL
                    }
                }
            } catch {}

            // If direct stream copy failed, transcode via VideoToolbox hardware acceleration
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try? FileManager.default.removeItem(at: outputURL)
            }

            let transcodeProcess = Process()
            transcodeProcess.executableURL = URL(fileURLWithPath: ffmpeg)
            transcodeProcess.arguments = [
                "-y",
                "-i", sourceURL.path,
                "-c:v", "hevc_videotoolbox",
                "-b:v", "14M",
                "-tag:v", "hvc1",
                "-an",
                "-movflags", "+faststart",
                outputURL.path
            ]
            let transPipe = Pipe()
            transcodeProcess.standardError = transPipe
            transcodeProcess.standardOutput = transPipe

            do {
                try transcodeProcess.run()
                transcodeProcess.waitUntilExit()
                if transcodeProcess.terminationStatus == 0 && FileManager.default.fileExists(atPath: outputURL.path) {
                    return outputURL
                }
            } catch {}
        }

        // 2. Native AVFoundation fallback (stripping audio tracks)
        let asset = AVURLAsset(url: sourceURL)
        let composition = AVMutableComposition()
        if let videoTrack = try? await asset.loadTracks(withMediaType: .video).first,
           let duration = try? await asset.load(.duration) {
            let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            let timeRange = CMTimeRange(start: .zero, duration: duration)
            try? compVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: .zero)

            if let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) {
                exportSession.outputURL = outputURL
                exportSession.outputFileType = .mov
                exportSession.shouldOptimizeForNetworkUse = true
                await exportSession.export()
                if exportSession.status == .completed && FileManager.default.fileExists(atPath: outputURL.path) {
                    return outputURL
                }
            }
        }

        // 3. Final fallback: copy file directly
        if !FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.copyItem(at: sourceURL, to: outputURL)
        }
        return outputURL
    }

    private func configureSystemScreensaverDefaults() {
        let screensaverProcess = Process()
        screensaverProcess.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        screensaverProcess.arguments = [
            "-currentHost", "write", "com.apple.screensaver",
            "moduleDict", "-dict",
            "moduleName", "WallpaperAerialsExtension",
            "path", "/System/Library/ExtensionKit/Extensions/WallpaperAerialsExtension.appex",
            "type", "0"
        ]
        try? screensaverProcess.run()
        screensaverProcess.waitUntilExit()

        // Also ensure idleTime is configured if zero or missing
        let idleCheckProcess = Process()
        idleCheckProcess.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        idleCheckProcess.arguments = [
            "-currentHost", "write", "com.apple.screensaver", "idleTime", "-int", "300"
        ]
        try? idleCheckProcess.run()
        idleCheckProcess.waitUntilExit()
    }

    private func updateWallpaperStoreIndexPlist(assetID: String, alsoSetDesktop: Bool) throws {
        let storeDir = (NSHomeDirectory() as NSString).appendingPathComponent("Library/Application Support/com.apple.wallpaper/Store")
        let plistPath = (storeDir as NSString).appendingPathComponent("Index.plist")
        let fm = FileManager.default

        try? fm.createDirectory(atPath: storeDir, withIntermediateDirectories: true)

        var root: [String: Any]
        if fm.fileExists(atPath: plistPath),
           let rawData = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
           let parsed = try? PropertyListSerialization.propertyList(from: rawData, options: .mutableContainersAndLeaves, format: nil) as? [String: Any] {
            root = parsed
        } else {
            root = [
                "AllSpacesAndDisplays": [:] as [String: Any],
                "SystemDefault": [:] as [String: Any],
                "Displays": [:] as [String: Any],
                "Spaces": [:] as [String: Any]
            ]
        }

        let configDict: [String: Any] = ["assetID": assetID]
        let configData = try PropertyListSerialization.data(fromPropertyList: configDict, format: .binary, options: 0)

        let optionsDict: [String: Any] = [
            "values": [
                "aerialShuffleFrequency": [
                    "picker": [
                        "_0": ["id": "shuffle_never"]
                    ]
                ]
            ]
        ]
        let optionsData = try PropertyListSerialization.data(fromPropertyList: optionsDict, format: .binary, options: 0)

        let aerialChoice: [String: Any] = [
            "Configuration": configData,
            "Files": [] as [Any],
            "Provider": "com.apple.wallpaper.choice.aerials"
        ]

        let now = Date()
        let aerialSection: [String: Any] = [
            "Content": [
                "Choices": [aerialChoice],
                "EncodedOptionValues": optionsData,
                "Shuffle": "$null"
            ],
            "LastSet": now,
            "LastUse": now
        ]

        for topKey in ["AllSpacesAndDisplays", "SystemDefault"] {
            var section = (root[topKey] as? [String: Any]) ?? [:]
            section["Idle"] = aerialSection
            if alsoSetDesktop {
                section["Desktop"] = aerialSection
                section["Type"] = "linked"
            } else {
                section["Type"] = "individual"
            }
            root[topKey] = section
        }

        // Also update any explicit display configurations in Displays
        if var displays = root["Displays"] as? [String: Any] {
            for (dispKey, val) in displays {
                if var dispDict = val as? [String: Any] {
                    dispDict["Idle"] = aerialSection
                    if alsoSetDesktop {
                        dispDict["Desktop"] = aerialSection
                        dispDict["Type"] = "linked"
                    }
                    displays[dispKey] = dispDict
                }
            }
            root["Displays"] = displays
        }

        // Also update any explicit spaces configurations in Spaces
        if var spaces = root["Spaces"] as? [String: Any] {
            for (spaceKey, val) in spaces {
                if var spaceDict = val as? [String: Any] {
                    spaceDict["Idle"] = aerialSection
                    if alsoSetDesktop {
                        spaceDict["Desktop"] = aerialSection
                        spaceDict["Type"] = "linked"
                    }
                    spaces[spaceKey] = spaceDict
                }
            }
            root["Spaces"] = spaces
        }

        let updatedData = try PropertyListSerialization.data(fromPropertyList: root, format: .binary, options: 0)
        try updatedData.write(to: URL(fileURLWithPath: plistPath), options: .atomic)
    }

    private func restartWallpaperDaemons() {
        let killProcess = Process()
        killProcess.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killProcess.arguments = [
            "WallpaperAerialsExtension",
            "WallpaperAgent",
            "idleassetsd",
            "WallpaperVideoExtension"
        ]
        try? killProcess.run()
        killProcess.waitUntilExit()
    }
}
