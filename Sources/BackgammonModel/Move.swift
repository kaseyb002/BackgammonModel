import Foundation

public typealias PointID = Int

public struct Move: Equatable, Codable, Sendable {
    public let from: MoveOrigin
    public let to: MoveDestination
    public let dieValue: Int

    public init(from: MoveOrigin, to: MoveDestination, dieValue: Int) {
        self.from = from
        self.to = to
        self.dieValue = dieValue
    }

    public enum MoveOrigin: Equatable, Codable, Sendable {
        case point(PointID)
        case bar
    }

    public enum MoveDestination: Equatable, Codable, Sendable {
        case point(PointID)
        case bearOff
    }
}
