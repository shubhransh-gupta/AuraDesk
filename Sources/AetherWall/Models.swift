import Foundation
import AVFoundation
import AppKit

public struct WallpaperItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public var remoteID: String?
    public var title: String
    public var category: String
    public var filePath: String
    public var thumbnailPath: String?
    public var durationSeconds: Double
    public var resolution: String
    public var fileSizeMB: Double
    public var addedAt: Date

    public init(
        id: UUID = UUID(),
        remoteID: String? = nil,
        title: String,
        category: String = "Local",
        filePath: String,
        thumbnailPath: String? = nil,
        durationSeconds: Double = 0,
        resolution: String = "4K UHD",
        fileSizeMB: Double = 0,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.remoteID = remoteID
        self.title = title
        self.category = category
        self.filePath = filePath
        self.thumbnailPath = thumbnailPath
        self.durationSeconds = durationSeconds
        self.resolution = resolution
        self.fileSizeMB = fileSizeMB
        self.addedAt = addedAt
    }

    public var fileURL: URL {
        URL(fileURLWithPath: filePath)
    }

    public var thumbnailURL: URL? {
        guard let thumbnailPath else { return nil }
        return URL(fileURLWithPath: thumbnailPath)
    }

    public var formattedDuration: String {
        let totalSeconds = Int(round(durationSeconds))
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

public struct RemoteWallpaperItem: Identifiable, Codable, Equatable {
    public let id: String
    public let name: String
    public let category: String
    public let resolution: String
    public let durationSeconds: Double
    public let fileSizeBytes: Int64
    public let videoURL: String
    public let thumbURL: String
    public let tags: [String]
    public let source: String

    public var fileSizeMB: Double {
        Double(fileSizeBytes) / (1024.0 * 1024.0)
    }

    public var formattedDuration: String {
        let totalSeconds = Int(round(durationSeconds))
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

public enum VideoGravityMode: String, Codable, CaseIterable, Identifiable {
    case aspectFill = "Fill Screen"
    case aspectFit = "Fit Screen"
    case stretch = "Stretch"

    public var id: String { rawValue }

    public var avGravity: AVLayerVideoGravity {
        switch self {
        case .aspectFill: return .resizeAspectFill
        case .aspectFit: return .resizeAspect
        case .stretch: return .resize
        }
    }
}

public struct AerialTargetAsset: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let category: String
    public let filePath: String
    public let isDownloaded: Bool
    public let hasBackup: Bool

    public var fileURL: URL {
        URL(fileURLWithPath: filePath)
    }
}
