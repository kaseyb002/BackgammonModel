import Foundation

public enum AIDifficulty: String, CaseIterable, Codable, Sendable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}

public struct AIEngine: Sendable {
    private let difficulty: AIDifficulty

    public init(difficulty: AIDifficulty) {
        self.difficulty = difficulty
    }

    public func getBestMove(for round: Round, playerId: PlayerID) -> Move? {
        let color: CheckerColor = round.playerColor(for: playerId)
        let moves: [Move] = round.allLegalMoves(for: color)
        guard moves.isEmpty == false else { return nil }

        switch difficulty {
        case .easy:
            return getEasyMove(moves: moves, round: round, color: color)
        case .medium:
            return getMediumMove(round: round, moves: moves, color: color)
        case .hard:
            return getHardMove(round: round, moves: moves, color: color)
        }
    }

    // MARK: - Easy: mostly random with slight preference for hits

    private func getEasyMove(moves: [Move], round: Round, color: CheckerColor) -> Move {
        let hits: [Move] = moves.filter { isHitMove($0, round: round, color: color) }
        if hits.isEmpty == false && Double.random(in: 0...1) < 0.4 {
            return hits.randomElement()!
        }
        return moves.randomElement()!
    }

    // MARK: - Medium: heuristic scoring

    private func getMediumMove(round: Round, moves: [Move], color: CheckerColor) -> Move {
        var bestScore: Double = -.infinity
        var bestMove: Move = moves[0]

        for move in moves {
            let score: Double = evaluateMove(move, round: round, color: color)
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        return bestMove
    }

    // MARK: - Hard: deeper positional heuristics

    private func getHardMove(round: Round, moves: [Move], color: CheckerColor) -> Move {
        var bestScore: Double = -.infinity
        var bestMove: Move = moves[0]

        for move in moves {
            var score: Double = evaluateMove(move, round: round, color: color)
            score += evaluatePositionalAdvantage(move, round: round, color: color)
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        return bestMove
    }

    // MARK: - Move evaluation

    private func evaluateMove(_ move: Move, round: Round, color: CheckerColor) -> Double {
        var score: Double = 0.0

        if case .bearOff = move.to {
            score += 10.0
        }

        if isHitMove(move, round: round, color: color) {
            score += 5.0
        }

        if case .point(let destId) = move.to {
            let destPoint: PointState = round.points[destId - 1]
            if destPoint.color == color && destPoint.count == 1 {
                score += 4.0
            }
            if destPoint.color == color && destPoint.count >= 2 {
                score += 2.0
            }
        }

        if case .point(let fromId) = move.from {
            let advancement: Double = Double(Round.homePointValue(point: fromId, for: color))
            score += advancement * 0.1
        }

        if case .bar = move.from {
            score += 3.0
        }

        return score
    }

    private func evaluatePositionalAdvantage(
        _ move: Move, round: Round, color: CheckerColor
    ) -> Double {
        var score: Double = 0.0

        if case .point(let fromId) = move.from {
            let fromPoint: PointState = round.points[fromId - 1]
            if fromPoint.count == 2 && fromPoint.color == color {
                score -= 3.0
            }
        }

        if case .point(let destId) = move.to {
            let opponentHome: ClosedRange<PointID> = Round.homeRange(for: color.opposite)
            if opponentHome.contains(destId) {
                score += 1.5
            }

            var consecutivePoints: Int = 0
            for offset in -3...3 {
                let checkId: PointID = destId + offset
                guard checkId >= 1, checkId <= Round.pointCount else { continue }
                let point: PointState = round.points[checkId - 1]
                if point.color == color && point.count >= 2 {
                    consecutivePoints += 1
                }
            }
            score += Double(consecutivePoints) * 0.5
        }

        if case .point(let destId) = move.to {
            let destPoint: PointState = round.points[destId - 1]
            if destPoint.count == 0 || (destPoint.color == color && destPoint.count == 0) {
                let isExposed: Bool = isBlotVulnerable(
                    pointId: destId, color: color, round: round
                )
                if isExposed {
                    score -= 2.0
                }
            }
        }

        return score
    }

    private func isHitMove(_ move: Move, round: Round, color: CheckerColor) -> Bool {
        guard case .point(let destId) = move.to else { return false }
        let destPoint: PointState = round.points[destId - 1]
        return destPoint.color == color.opposite && destPoint.count == 1
    }

    private func isBlotVulnerable(
        pointId: PointID, color: CheckerColor, round: Round
    ) -> Bool {
        let opponentColor: CheckerColor = color.opposite
        for dieValue in 1...6 {
            let sourcePoint: Int = Round.destination(
                from: pointId, color: opponentColor.opposite, dieValue: dieValue
            )
            guard sourcePoint >= 1, sourcePoint <= Round.pointCount else { continue }
            let point: PointState = round.points[sourcePoint - 1]
            if point.color == opponentColor && point.count > 0 {
                return true
            }
        }
        if round.barCount(for: opponentColor) > 0 {
            let entryDie: Int
            switch opponentColor {
            case .black: entryDie = pointId
            case .white: entryDie = 25 - pointId
            }
            if entryDie >= 1 && entryDie <= 6 {
                return true
            }
        }
        return false
    }
}

// MARK: - Round convenience for AI

extension Round {
    public mutating func makeAITurn(difficulty: AIDifficulty, playerId: PlayerID) throws {
        guard case .waitingForRoll(let id) = state, id == playerId else {
            throw BackgammonError.notWaitingForRoll
        }
        rollDice()

        let ai: AIEngine = AIEngine(difficulty: difficulty)
        while case .waitingForMove(let moveId) = state, moveId == playerId {
            guard let bestMove: Move = ai.getBestMove(for: self, playerId: playerId) else {
                break
            }
            try performMove(bestMove)
        }
    }

    mutating func makeAITurnUnchecked(
        difficulty: AIDifficulty, playerId: PlayerID, dice: DiceRoll
    ) {
        rollDice(cooked: dice)

        let ai: AIEngine = AIEngine(difficulty: difficulty)
        while case .waitingForMove(let moveId) = state, moveId == playerId {
            guard let bestMove: Move = ai.getBestMove(for: self, playerId: playerId) else {
                break
            }
            performMoveUnchecked(bestMove)
        }
    }
}
