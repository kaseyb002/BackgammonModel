import Foundation

extension Round {
    public init(players: [Player]) {
        precondition(players.count == 2, "Backgammon requires exactly 2 players")
        let adjustedPlayers: [Player] = [
            players[0].changeChecker(color: .white),
            players[1].changeChecker(color: .black),
        ]
        self.started = .now
        self.players = adjustedPlayers
        self.state = .waitingForRoll(playerId: adjustedPlayers[0].id)
        self.points = Self.makeStandardBoard()
        self.whiteBar = 0
        self.blackBar = 0
        self.whiteBorneOff = 0
        self.blackBorneOff = 0
        self.currentDice = nil
        self.remainingMoves = []
        self.currentTurnMoves = []
    }

    init(
        players: [Player],
        points: [PointState],
        state: State,
        whiteBar: Int = 0,
        blackBar: Int = 0,
        whiteBorneOff: Int = 0,
        blackBorneOff: Int = 0,
        currentDice: DiceRoll? = nil,
        remainingMoves: [Int] = [],
        currentTurnMoves: [Move] = [],
        started: Date = .now,
        completed: Date? = nil,
        log: [TurnAction] = []
    ) {
        self.players = players
        self.points = points
        self.state = state
        self.whiteBar = whiteBar
        self.blackBar = blackBar
        self.whiteBorneOff = whiteBorneOff
        self.blackBorneOff = blackBorneOff
        self.currentDice = currentDice
        self.remainingMoves = remainingMoves
        self.currentTurnMoves = currentTurnMoves
        self.started = started
        self.completed = completed
        self.log = log
    }

    static func makeStandardBoard() -> [PointState] {
        var points: [PointState] = Array(repeating: .empty, count: pointCount)
        // White (home board 1-6, moves from 24 toward 1)
        points[5] = PointState(count: 5, color: .white)    // Point 6
        points[7] = PointState(count: 3, color: .white)    // Point 8
        points[12] = PointState(count: 5, color: .white)   // Point 13
        points[23] = PointState(count: 2, color: .white)   // Point 24
        // Black (home board 19-24, moves from 1 toward 24)
        points[0] = PointState(count: 2, color: .black)    // Point 1
        points[11] = PointState(count: 5, color: .black)   // Point 12
        points[16] = PointState(count: 3, color: .black)   // Point 17
        points[18] = PointState(count: 5, color: .black)   // Point 19
        return points
    }
}
