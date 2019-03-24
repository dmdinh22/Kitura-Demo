import Foundation

struct Track: Codable {
    var name: String
    var composer: String?
    var albumTitle: String

    enum TrackError: Error {
        case initFromRowFailed
    }

    init(fromRow row: [String: Any?]) throws {
        // ensure we have at least a name & album title
        guard let rowName = row["Name"] as? String, let rowTitle = row["Title"] as? String else {
            throw TrackError.initFromRowFailed
        }
        name = rowName
        albumTitle = rowTitle
        composer = row["Composer"] as? String
    }
}

