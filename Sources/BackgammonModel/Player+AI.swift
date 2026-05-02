import Foundation

extension Player {
    public static func aiPlayer(
        id: PlayerID = UUID().uuidString,
        name: String = "AI Player",
        difficulty: AIDifficulty,
        checkerColor: CheckerColor
    ) -> AIPlayer {
        AIPlayer(
            id: id,
            name: name,
            imageURL: nil,
            checkerColor: checkerColor,
            difficulty: difficulty
        )
    }
}

public struct AIPlayer: Equatable, Codable, Sendable, Identifiable {
    public let id: PlayerID
    public var name: String
    public var imageURL: URL?
    public let checkerColor: CheckerColor
    public let difficulty: AIDifficulty

    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageURL = "imageUrl"
        case checkerColor
        case difficulty
    }

    public init(
        id: PlayerID,
        name: String,
        imageURL: URL?,
        checkerColor: CheckerColor,
        difficulty: AIDifficulty
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.checkerColor = checkerColor
        self.difficulty = difficulty
    }

    public func changeChecker(color: CheckerColor) -> AIPlayer {
        AIPlayer(
            id: id,
            name: name,
            imageURL: imageURL,
            checkerColor: color,
            difficulty: difficulty
        )
    }

    public var asPlayer: Player {
        Player(
            id: id,
            name: name,
            imageURL: imageURL,
            checkerColor: checkerColor
        )
    }
}
