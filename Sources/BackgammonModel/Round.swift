import Foundation

public struct Round: Equatable, Codable, Sendable {
    public static let pointCount: Int = 24
    public static let checkersPerPlayer: Int = 15
    public static let maxLogActions: Int = 100

    public let started: Date
    public internal(set) var completed: Date?
    public internal(set) var log: [TurnAction] = []
    public internal(set) var state: State
    public internal(set) var players: [Player]
    public internal(set) var points: [PointState]
    public internal(set) var whiteBar: Int
    public internal(set) var blackBar: Int
    public internal(set) var whiteBorneOff: Int
    public internal(set) var blackBorneOff: Int
    public internal(set) var currentDice: DiceRoll?
    public internal(set) var remainingMoves: [Int]
    public internal(set) var currentTurnMoves: [Move]

    public enum State: Equatable, Codable, Sendable {
        case waitingForRoll(playerId: PlayerID)
        case waitingForMove(playerId: PlayerID)
        case complete(winningPlayerId: PlayerID)
    }

    public struct TurnAction: Equatable, Codable, Sendable {
        public let playerId: PlayerID
        public let dice: DiceRoll
        public let moves: [Move]
        public let timestamp: Date

        public init(
            playerId: PlayerID,
            dice: DiceRoll,
            moves: [Move],
            timestamp: Date
        ) {
            self.playerId = playerId
            self.dice = dice
            self.moves = moves
            self.timestamp = timestamp
        }
    }
}
