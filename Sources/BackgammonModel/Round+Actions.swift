import Foundation

extension Round {
    public mutating func rollDice() {
        rollDice(cooked: .random())
    }

    mutating func rollDice(cooked dice: DiceRoll) {
        guard case .waitingForRoll(let currentId) = state else { return }
        let color: CheckerColor = playerColor(for: currentId)

        currentDice = dice
        remainingMoves = dice.values
        currentTurnMoves = []

        if allLegalMoves(for: color).isEmpty {
            logCurrentTurn(playerId: currentId, dice: dice)
            advanceTurn(currentPlayerId: currentId)
        } else {
            state = .waitingForMove(playerId: currentId)
        }
    }

    public mutating func performMove(_ move: Move) throws {
        guard case .waitingForMove(let currentId) = state else {
            throw BackgammonError.notWaitingForMove
        }
        let color: CheckerColor = playerColor(for: currentId)
        let legal: [Move] = allLegalMoves(for: color)
        guard legal.contains(move) else {
            throw BackgammonError.invalidMove
        }

        executeMove(move, color: color)
        consumeDie(value: move.dieValue)
        currentTurnMoves.append(move)

        if borneOffCount(for: color) == Self.checkersPerPlayer {
            logCurrentTurn(playerId: currentId, dice: currentDice!)
            state = .complete(winningPlayerId: currentId)
            completed = .now
            return
        }

        if remainingMoves.isEmpty || allLegalMoves(for: color).isEmpty {
            logCurrentTurn(playerId: currentId, dice: currentDice!)
            advanceTurn(currentPlayerId: currentId)
        }
    }

    mutating func performMoveUnchecked(_ move: Move) {
        guard case .waitingForMove(let currentId) = state else { return }
        let color: CheckerColor = playerColor(for: currentId)
        executeMove(move, color: color)
        consumeDie(value: move.dieValue)
        currentTurnMoves.append(move)

        if borneOffCount(for: color) == Self.checkersPerPlayer {
            logCurrentTurn(playerId: currentId, dice: currentDice!)
            state = .complete(winningPlayerId: currentId)
            completed = .now
            return
        }

        if remainingMoves.isEmpty || allLegalMoves(for: color).isEmpty {
            logCurrentTurn(playerId: currentId, dice: currentDice!)
            advanceTurn(currentPlayerId: currentId)
        }
    }

    private mutating func executeMove(_ move: Move, color: CheckerColor) {
        switch move.from {
        case .point(let pointId):
            points[pointId - 1].count -= 1
            if points[pointId - 1].count == 0 {
                points[pointId - 1].color = nil
            }
        case .bar:
            setBar(for: color, count: barCount(for: color) - 1)
        }

        switch move.to {
        case .point(let pointId):
            if let pointColor: CheckerColor = points[pointId - 1].color,
               pointColor != color,
               points[pointId - 1].count == 1 {
                points[pointId - 1] = .empty
                setBar(for: color.opposite, count: barCount(for: color.opposite) + 1)
            }
            points[pointId - 1].count += 1
            points[pointId - 1].color = color

        case .bearOff:
            setBorneOff(for: color, count: borneOffCount(for: color) + 1)
        }
    }

    private mutating func consumeDie(value: Int) {
        if let index: Int = remainingMoves.firstIndex(of: value) {
            remainingMoves.remove(at: index)
        }
    }

    private mutating func logCurrentTurn(playerId: PlayerID, dice: DiceRoll) {
        log.append(TurnAction(
            playerId: playerId,
            dice: dice,
            moves: currentTurnMoves,
            timestamp: .now
        ))
        trimLog()
        currentTurnMoves = []
        currentDice = nil
        remainingMoves = []
    }

    private mutating func advanceTurn(currentPlayerId: PlayerID) {
        let opponentId: PlayerID = opponentPlayerId(for: currentPlayerId)
        state = .waitingForRoll(playerId: opponentId)
    }

    private mutating func trimLog() {
        if log.count > Self.maxLogActions {
            log.removeFirst(log.count - Self.maxLogActions)
        }
    }
}
