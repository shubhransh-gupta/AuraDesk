import Foundation
import AVFoundation
import AppKit

@MainActor
public final class LockScreenManager: ObservableObject {
    public static let shared = LockScreenManager()

    private let customerDir = "/Library/Application Support/com.apple.idleassetsd/Customer"
    private let aerials4KDir = "/Library/Application Support/com.apple.idleassetsd/Customer/4KSDR240FPS"
    private let entriesPath = "/Library/Application Support/com.apple.idleassetsd/Customer/entries.json"

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
        let dir = appSupport.appendingPathComponent("AetherWall/AerialBackups", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    public func refreshTargets() {
        var nameMap: [String: (name: String, category: String)] = [:]
        let localizedStrings = loadLocalizedStrings()

        if let data = try? Data(contentsOf: URL(fileURLWithPath: entriesPath)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let assets = json["assets"] as? [[String: Any]] {
            for asset in assets {
                if let id = asset["id"] as? String {
                    let locKey = asset["localizedNameKey"] as? String ?? ""
                    let fallback = asset["accessibilityLabel"] as? String ?? asset["shotID"] as? String ?? id
                    let resolvedName = localizedStrings[locKey] ?? fallback
                    let category = asset["accessibilityLabel"] as? String ?? "Aerial"
                    nameMap[id] = (resolvedName, category)
                }
            }
        }

        var targets: [AerialTargetAsset] = []
        let fm = FileManager.default

        if let files = try? fm.contentsOfDirectory(atPath: aerials4KDir) {
            for file in files where file.hasSuffix(".mov") {
                let assetID = (file as NSString).deletingPathExtension
                let fullPath = (aerials4KDir as NSString).appendingPathComponent(file)
                let backupURL = backupDirectoryURL.appendingPathComponent(file)
                let info = nameMap[assetID]
                targets.append(
                    AerialTargetAsset(
                        id: assetID,
                        name: info?.name ?? "Aerial (\(assetID.prefix(8)))",
                        category: info?.category ?? "Downloaded Aerial",
                        filePath: fullPath,
                        isDownloaded: true,
                        hasBackup: fm.fileExists(atPath: backupURL.path)
                    )
                )
            }
        }

        if targets.isEmpty {
            for (id, info) in nameMap.prefix(5) {
                let file = "\(id).mov"
                let fullPath = (aerials4KDir as NSString).appendingPathComponent(file)
                let backupURL = backupDirectoryURL.appendingPathComponent(file)
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
        }

        targets.sort { $0.name < $1.name }
        self.availableTargets = targets
        if selectedTargetID.isEmpty || !targets.contains(where: { $0.id == selectedTargetID }) {
            selectedTargetID = targets.first?.id ?? "9680B8EB-CE2A-4395-AF41-402801F4D6A6"
        }
    }

    public func loadLocalizedStrings() -> [String: String] {
        let bundlePath = "\(customerDir)/TVIdleScreenStrings.bundle"
        let preferredBoxes = ["en.lproj", "en_US.lproj", "en_GB.lproj", "en_AU.lproj", "Base.lproj"]
        let fm = FileManager.default

        for proj in preferredBoxes {
            let path = "\(bundlePath)/\(proj)/Localizable.nocache.strings"
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

        let targetID = selectedTargetID.isEmpty ? "9680B8EB-CE2A-4395-AF41-402801F4D6A6" : selectedTargetID
        let targetMovPath = "\(aerials4KDir)/\(targetID).mov"
        let backupMovURL = backupDirectoryURL.appendingPathComponent("\(targetID).mov")

        do {
            let preparedMovURL = try await prepareCompatibleMovFile(from: item.fileURL)

            let fm = FileManager.default
            if fm.fileExists(atPath: targetMovPath) && !fm.fileExists(atPath: backupMovURL.path) {
                statusMessage = "Backing up original Apple Aerial asset..."
                try? fm.copyItem(atPath: targetMovPath, toPath: backupMovURL.path)
            }

            statusMessage = "Configuring macOS Lock Screen & Screen Saver plist..."
            try updateWallpaperStoreIndexPlist(assetID: targetID, alsoSetDesktop: alsoSetNativeDesktop)

            statusMessage = "Requesting administrator permission to install Lock Screen video..."
            try await installAerialFileWithAdminPrivileges(
                sourceMovPath: preparedMovURL.path,
                targetMovPath: targetMovPath
            )

            refreshTargets()
            let targetName = availableTargets.first(where: { $0.id == targetID })?.name ?? targetID
            statusIsError = false
            statusMessage = "Applied '\(item.title)' to Lock Screen & Screen Saver (via Aerial slot: \(targetName))!"
        } catch {
            statusIsError = true
            statusMessage = "Failed to set Lock Screen: \(error.localizedDescription)"
        }

        isBusy = false
    }

    public func restoreOriginalAerial() async {
        guard !isBusy else { return }
        let targetID = selectedTargetID.isEmpty ? "9680B8EB-CE2A-4395-AF41-402801F4D6A6" : selectedTargetID
        let backupMovURL = backupDirectoryURL.appendingPathComponent("\(targetID).mov")
        let targetMovPath = "\(aerials4KDir)/\(targetID).mov"

        guard FileManager.default.fileExists(atPath: backupMovURL.path) else {
            statusIsError = true
            statusMessage = "No backup found for selected Aerial slot."
            return
        }

        isBusy = true
        statusIsError = false
        statusMessage = "Restoring original Apple Aerial video..."

        do {
            try await installAerialFileWithAdminPrivileges(
                sourceMovPath: backupMovURL.path,
                targetMovPath: targetMovPath
            )
            try? FileManager.default.removeItem(at: backupMovURL)
            refreshTargets()
            statusMessage = "Original Apple Aerial video restored!"
        } catch {
            statusIsError = true
            statusMessage = "Restore failed: \(error.localizedDescription)"
        }

        isBusy = false
    }

    private func prepareCompatibleMovFile(from sourceURL: URL) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("AetherWallStaging", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let outputURL = tempDir.appendingPathComponent("staged_lockscreen.mov")
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        if sourceURL.pathExtension.lowercased() == "mov" {
            try FileManager.default.copyItem(at: sourceURL, to: outputURL)
            return outputURL
        }

        let asset = AVURLAsset(url: sourceURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            try FileManager.default.copyItem(at: sourceURL, to: outputURL)
            return outputURL
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.shouldOptimizeForNetworkUse = false

        await exportSession.export()

        if exportSession.status == .completed {
            return outputURL
        } else {
            if !FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.copyItem(at: sourceURL, to: outputURL)
            }
            return outputURL
        }
    }

    private func updateWallpaperStoreIndexPlist(assetID: String, alsoSetDesktop: Bool) throws {
        let storeDir = (NSHomeDirectory() as NSString).appendingPathComponent("Library/Application Support/com.apple.wallpaper/Store")
        let plistPath = (storeDir as NSString).appendingPathComponent("Index.plist")
        let fm = FileManager.default

        guard fm.fileExists(atPath: plistPath),
              let rawData = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
              var root = try PropertyListSerialization.propertyList(from: rawData, options: .mutableContainersAndLeaves, format: nil) as? [String: Any] else {
            return
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

        let updatedData = try PropertyListSerialization.data(fromPropertyList: root, format: .binary, options: 0)
        try updatedData.write(to: URL(fileURLWithPath: plistPath), options: .atomic)
    }

    private func installAerialFileWithAdminPrivileges(sourceMovPath: String, targetMovPath: String) async throws {
        let escapedSource = sourceMovPath.replacingOccurrences(of: "'", with: "'\\''")
        let escapedTarget = targetMovPath.replacingOccurrences(of: "'", with: "'\\''")
        let escapedDir = aerials4KDir.replacingOccurrences(of: "'", with: "'\\''")

        let shellCmd = """
        mkdir -p '\(escapedDir)' && \
        cp -f '\(escapedSource)' '\(escapedTarget)' && \
        chown root:admin '\(escapedTarget)' && \
        chmod 644 '\(escapedTarget)' && \
        killall idleassetsd 2>/dev/null || true && \
        killall WallpaperAgent 2>/dev/null || true && \
        killall WallpaperVideoExtension 2>/dev/null || true
        """

        let appleScriptSource = "do shell script \"\(shellCmd.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))\" with administrator privileges"

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var errorDict: NSDictionary?
                let script = NSAppleScript(source: appleScriptSource)
                _ = script?.executeAndReturnError(&errorDict)

                if let errorDict = errorDict {
                    let message = errorDict[NSAppleScript.errorMessage] as? String ?? "Administrator privileges were cancelled or failed."
                    continuation.resume(throwing: NSError(domain: "AetherWall.LockScreen", code: 1, userInfo: [NSLocalizedDescriptionKey: message]))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
