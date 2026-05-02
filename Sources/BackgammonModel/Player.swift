import Foundation

public typealias PlayerID = String

public struct Player: Equatable, Codable, Sendable, Identifiable {
    public let id: PlayerID
    public var name: String
    public var imageURL: URL?
    public let checkerColor: CheckerColor

    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageURL = "imageUrl"
        case checkerColor
    }

    public init(
        id: PlayerID,
        name: String,
        imageURL: URL?,
        checkerColor: CheckerColor
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.checkerColor = checkerColor
    }

    public func changeChecker(color: CheckerColor) -> Player {
        Player(
            id: id,
            name: name,
            imageURL: imageURL,
            checkerColor: color
        )
    }
}
