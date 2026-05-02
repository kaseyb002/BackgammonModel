import Foundation

// MARK: - Player helpers

extension Round {
    public func playerColor(for playerId: PlayerID) -> CheckerColor {
        players.first(where: { $0.id == playerId })!.checkerColor
    }

    func opponentPlayerId(for playerId: PlayerID) -> PlayerID {
        players.first(where: { $0.id != playerId })!.id
    }

    public func player(byID id: PlayerID) -> Player? {
        players.first(where: { $0.id == id })
    }

    public func isPlayersTurn(playerID: PlayerID) -> Bool {
        switch state {
        case .waitingForRoll(let id), .waitingForMove(let id):
            return playerID == id
        case .complete:
            return false
        }
    }

    public var currentPlayer: Player? {
        switch state {
        case .waitingForRoll(let playerID), .waitingForMove(let playerID):
            player(byID: playerID)
        case .complete:
            nil
        }
    }
}

// MARK: - Bar and borne off helpers

extension Round {
    public func barCount(for color: CheckerColor) -> Int {
        switch color {
        case .white: whiteBar
        case .black: blackBar
        }
    }

    public func borneOffCount(for color: CheckerColor) -> Int {
        switch color {
        case .white: whiteBorneOff
        case .black: blackBorneOff
        }
    }

    mutating func setBar(for color: CheckerColor, count: Int) {
        switch color {
        case .white: whiteBar = count
        case .black: blackBar = count
        }
    }

    mutating func setBorneOff(for color: CheckerColor, count: Int) {
        switch color {
        case .white: whiteBorneOff = count
        case .black: blackBorneOff = count
        }
    }
}

// MARK: - Board geometry

extension Round {
    public static func isInHome(point: PointID, for color: CheckerColor) -> Bool {
        switch color {
        case .white: point >= 1 && point <= 6
        case .black: point >= 19 && point <= 24
        }
    }

    public static func homePointValue(point: PointID, for color: CheckerColor) -> Int {
        switch color {
        case .white: point
        case .black: 25 - point
        }
    }

    public static func destination(from point: PointID, color: CheckerColor, dieValue: Int) -> Int {
        switch color {
        case .white: point - dieValue
        case .black: point + dieValue
        }
    }

    public static func barEntryPoint(color: CheckerColor, dieValue: Int) -> PointID {
        switch color {
        case .white: 25 - dieValue
        case .black: dieValue
        }
    }

    public static func homeRange(for color: CheckerColor) -> ClosedRange<PointID> {
        switch color {
        case .white: 1...6
        case .black: 19...24
        }
    }
}

// MARK: - Board state queries

extension Round {
    public func allCheckersInHome(for color: CheckerColor) -> Bool {
        if barCount(for: color) > 0 { return false }
        let home: ClosedRange<PointID> = Self.homeRange(for: color)
        for pointId in 1...Self.pointCount {
            if home.contains(pointId) { continue }
            let point: PointState = points[pointId - 1]
            if point.color == color && point.count > 0 { return false }
        }
        return true
    }

    public func canLand(at pointId: PointID, color: CheckerColor) -> Bool {
        let point: PointState = points[pointId - 1]
        return point.color == nil || point.color == color || point.count <= 1
    }

    public func checkerCount(for color: CheckerColor) -> Int {
        var count: Int = barCount(for: color) + borneOffCount(for: color)
        for point in points {
            if point.color == color {
                count += point.count
            }
        }
        return count
    }

    public func pipCount(for color: CheckerColor) -> Int {
        var pips: Int = 0
        for pointId in 1...Self.pointCount {
            let point: PointState = points[pointId - 1]
            if point.color == color {
                let distance: Int = Self.homePointValue(point: pointId, for: color)
                pips += point.count * distance
            }
        }
        pips += barCount(for: color) * 25
        return pips
    }
}

// MARK: - Legal moves

extension Round {
    public func allLegalMoves(for color: CheckerColor) -> [Move] {
        var moves: [Move] = []
        let uniqueDice: Set<Int> = Set(remainingMoves)
        for dieValue in uniqueDice {
            moves.append(contentsOf: legalMoves(for: color, dieValue: dieValue))
        }
        return moves
    }

    public func legalMoves(for color: CheckerColor, dieValue: Int) -> [Move] {
        if barCount(for: color) > 0 {
            return barEntryMoves(for: color, dieValue: dieValue)
        }

        if allCheckersInHome(for: color) {
            return bearingOffMoves(for: color, dieValue: dieValue)
                + normalMoves(for: color, dieValue: dieValue)
        }

        return normalMoves(for: color, dieValue: dieValue)
    }

    private func barEntryMoves(for color: CheckerColor, dieValue: Int) -> [Move] {
        let entryPoint: PointID = Self.barEntryPoint(color: color, dieValue: dieValue)
        guard canLand(at: entryPoint, color: color) else { return [] }
        return [Move(from: .bar, to: .point(entryPoint), dieValue: dieValue)]
    }

    private func normalMoves(for color: CheckerColor, dieValue: Int) -> [Move] {
        var moves: [Move] = []
        for pointId in 1...Self.pointCount {
            let point: PointState = points[pointId - 1]
            guard point.color == color, point.count > 0 else { continue }
            let dest: Int = Self.destination(from: pointId, color: color, dieValue: dieValue)
            guard dest >= 1, dest <= Self.pointCount else { continue }
            guard canLand(at: dest, color: color) else { continue }
            moves.append(Move(from: .point(pointId), to: .point(dest), dieValue: dieValue))
        }
        return moves
    }

    private func bearingOffMoves(for color: CheckerColor, dieValue: Int) -> [Move] {
        var moves: [Move] = []
        let home: ClosedRange<PointID> = Self.homeRange(for: color)
        var highestOccupiedValue: Int = 0

        for pointId in home {
            let point: PointState = points[pointId - 1]
            if point.color == color && point.count > 0 {
                let value: Int = Self.homePointValue(point: pointId, for: color)
                highestOccupiedValue = max(highestOccupiedValue, value)
            }
        }

        for pointId in home {
            let point: PointState = points[pointId - 1]
            guard point.color == color, point.count > 0 else { continue }
            let homeValue: Int = Self.homePointValue(point: pointId, for: color)

            if homeValue == dieValue {
                moves.append(Move(from: .point(pointId), to: .bearOff, dieValue: dieValue))
            }

            if dieValue > highestOccupiedValue && homeValue == highestOccupiedValue {
                let bearOffMove: Move = Move(from: .point(pointId), to: .bearOff, dieValue: dieValue)
                if moves.contains(bearOffMove) == false {
                    moves.append(bearOffMove)
                }
            }
        }
        return moves
    }

    func hasLegalMoves(for color: CheckerColor) -> Bool {
        allLegalMoves(for: color).isEmpty == false
    }
}

// MARK: - State extensions

extension Round.State {
    public var isComplete: Bool {
        switch self {
        case .complete:
            return true
        case .waitingForRoll, .waitingForMove:
            return false
        }
    }
}
