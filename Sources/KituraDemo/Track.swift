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

    func asXmlElement() -> XMLElement {
        let trackElement: XMLElement = XMLElement(name: "track")
        let nameElement: XMLElement = XMLElement(name: "name", stringValue: name)
        let composerElement: XMLElement = XMLElement(name: "composer", stringValue: composer)
        let albumTitleElement: XMLElement = XMLElement(name: "albumTitle", stringValue: albumTitle)
        
        trackElement.addChild(nameElement)
        trackElement.addChild(composerElement)
        trackElement.addChild(albumTitleElement)

        return trackElement
    }
}

