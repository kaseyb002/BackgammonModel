import Foundation
import Testing
@testable import BackgammonModel

// MARK: - Test helpers

private func makePlayers() -> [Player] {
    let p1: Player = Player(id: "alice", name: "Alice", imageURL: nil, checkerColor: .white)
    let p2: Player = Player(id: "bob", name: "Bob", imageURL: nil, checkerColor: .black)
    return [p1, p2]
}

private func winnerID(_ round: Round) -> PlayerID? {
    if case .complete(let winningPlayerId) = round.state { return winningPlayerId }
    return nil
}

private func currentPlayerId(_ round: Round) -> PlayerID? {
    switch round.state {
    case .waitingForRoll(let id), .waitingForMove(let id):
        return id
    case .complete:
        return nil
    }
}

private func makeEmptyBoard() -> [PointState] {
    Array(repeating: .empty, count: Round.pointCount)
}

// MARK: - Board setup tests

@Test
func standardBoardHas15CheckersPerPlayer() {
    let round: Round = Round(players: makePlayers())
    #expect(round.checkerCount(for: .white) == 15)
    #expect(round.checkerCount(for: .black) == 15)
}

@Test
func standardBoardPointLayout() {
    let round: Round = Round(players: makePlayers())
    // White checkers
    #expect(round.points[5].count == 5)
    #expect(round.points[5].color == .white)   // Point 6
    #expect(round.points[7].count == 3)
    #expect(round.points[7].color == .white)   // Point 8
    #expect(round.points[12].count == 5)
    #expect(round.points[12].color == .white)  // Point 13
    #expect(round.points[23].count == 2)
    #expect(round.points[23].color == .white)  // Point 24
    // Black checkers
    #expect(round.points[0].count == 2)
    #expect(round.points[0].color == .black)   // Point 1
    #expect(round.points[11].count == 5)
    #expect(round.points[11].color == .black)  // Point 12
    #expect(round.points[16].count == 3)
    #expect(round.points[16].color == .black)  // Point 17
    #expect(round.points[18].count == 5)
    #expect(round.points[18].color == .black)  // Point 19
}

@Test
func whiteGoesFirst() {
    let round: Round = Round(players: makePlayers())
    #expect(currentPlayerId(round) == "alice")
    #expect(round.players[0].checkerColor == .white)
}

@Test
func colorsAssignedCorrectly() {
    let p1: Player = Player(id: "a", name: "A", imageURL: nil, checkerColor: .black)
    let p2: Player = Player(id: "b", name: "B", imageURL: nil, checkerColor: .black)
    let round: Round = Round(players: [p1, p2])
    #expect(round.players[0].checkerColor == .white)
    #expect(round.players[1].checkerColor == .black)
}

@Test
func initialStateIsWaitingForRoll() {
    let round: Round = Round(players: makePlayers())
    if case .waitingForRoll(let id) = round.state {
        #expect(id == "alice")
    } else {
        #expect(Bool(false), "Expected waitingForRoll state")
    }
}

@Test
func barAndBorneOffStartAtZero() {
    let round: Round = Round(players: makePlayers())
    #expect(round.whiteBar == 0)
    #expect(round.blackBar == 0)
    #expect(round.whiteBorneOff == 0)
    #expect(round.blackBorneOff == 0)
}

// MARK: - Dice roll tests

@Test
func rollDiceSetsRemainingMoves() {
    var round: Round = Round(players: makePlayers())
    round.rollDice(cooked: DiceRoll(die1: 3, die2: 5))
    #expect(round.remainingMoves.sorted() == [3, 5])
    #expect(round.currentDice == DiceRoll(die1: 3, die2: 5))
}

@Test
func doublesGiveFourMoves() {
    var round: Round = Round(players: makePlayers())
    round.rollDice(cooked: DiceRoll(die1: 4, die2: 4))
    #expect(round.remainingMoves == [4, 4, 4, 4])
}

@Test
func rollDiceTransitionsToWaitingForMove() {
    var round: Round = Round(players: makePlayers())
    round.rollDice(cooked: DiceRoll(die1: 3, die2: 5))
    if case .waitingForMove(let id) = round.state {
        #expect(id == "alice")
    } else {
        #expect(Bool(false), "Expected waitingForMove state")
    }
}

// MARK: - Basic move tests

@Test
func simpleMoveForward() throws {
    var round: Round = Round(players: makePlayers())
    round.rollDice(cooked: DiceRoll(die1: 3, die2: 5))

    // White at point 13 moving 5 to point 8
    let move: Move = Move(from: .point(13), to: .point(8), dieValue: 5)
    try round.performMove(move)

    #expect(round.points[12].count == 4)   // Point 13 had 5, now 4
    #expect(round.points[7].count == 4)    // Point 8 had 3, now 4
    #expect(round.remainingMoves == [3])   // Only die 3 remains
}

@Test
func moveConsumesCorrectDie() throws {
    var round: Round = Round(players: makePlayers())
    round.rollDice(cooked: DiceRoll(die1: 1, die2: 6))

    // Use the 6 first
    let move: Move = Move(from: .point(13), to: .point(7), dieValue: 6)
    try round.performMove(move)
    #expect(round.remainingMoves == [1])
}

@Test
func turnEndsAfterAllDiceUsed() throws {
    var round: Round = Round(players: makePlayers())
    round.rollDice(cooked: DiceRoll(die1: 3, die2: 5))

    try round.performMove(Move(from: .point(13), to: .point(8), dieValue: 5))
    try round.performMove(Move(from: .point(8), to: .point(5), dieValue: 3))

    // Turn should end, now waiting for Bob to roll
    if case .waitingForRoll(let id) = round.state {
        #expect(id == "bob")
    } else {
        #expect(Bool(false), "Expected waitingForRoll for bob")
    }
    #expect(round.log.count == 1)
    #expect(round.log[0].moves.count == 2)
}

@Test
func invalidMoveThrows() {
    var round: Round = Round(players: makePlayers())
    round.rollDice(cooked: DiceRoll(die1: 3, die2: 5))

    // Try to move a black checker as white
    #expect(throws: BackgammonError.invalidMove) {
        try round.performMove(Move(from: .point(1), to: .point(4), dieValue: 3))
    }
}

@Test
func cannotMoveWhenWaitingForRoll() {
    var round: Round = Round(players: makePlayers())
    #expect(throws: BackgammonError.notWaitingForMove) {
        try round.performMove(Move(from: .point(13), to: .point(8), dieValue: 5))
    }
}

// MARK: - Hit tests

@Test
func hitSendsOpponentToBar() throws {
    let players: [Player] = makePlayers()
    var points: [PointState] = makeEmptyBoard()
    points[7] = PointState(count: 1, color: .white)   // Point 8: 1 white
    points[4] = PointState(count: 1, color: .black)   // Point 5: 1 black (blot)

    var round: Round = Round(
        players: players,
        points: points,
        state: .waitingForMove(playerId: "alice"),
        currentDice: DiceRoll(die1: 3, die2: 5),
        remainingMoves: [3]
    )

    let move: Move = Move(from: .point(8), to: .point(5), dieValue: 3)
    try round.performMove(move)

    #expect(round.points[4].count == 1)
    #expect(round.points[4].color == .white)
    #expect(round.blackBar == 1)
}

// MARK: - Bar entry tests

@Test
func mustEnterFromBarFirst() {
    let players: [Player] = makePlayers()
    var points: [PointState] = makeEmptyBoard()
    points[12] = PointState(count: 3, color: .white)  // Point 13

    let round: Round = Round(
        players: players,
        points: points,
        state: .waitingForMove(playerId: "alice"),
        whiteBar: 1,
        currentDice: DiceRoll(die1: 3, die2: 5),
        remainingMoves: [3, 5]
    )

    let moves: [Move] = round.allLegalMoves(for: .white)
    for move in moves {
        #expect(move.from == .bar, "All legal moves must be from bar when checker is on bar")
    }
}

@Test
func enterFromBar() throws {
    let players: [Player] = makePlayers()
    var points: [PointState] = makeEmptyBoard()
    points[12] = PointState(count: 3, color: .white)

    var round: Round = Round(
        players: players,
        points: points,
        state: .waitingForMove(playerId: "alice"),
        whiteBar: 1,
        currentDice: DiceRoll(die1: 3, die2: 5),
        remainingMoves: [3, 5]
    )

    // White enters from bar: die 3 → point 22 (25-3)
    let move: Move = Move(from: .bar, to: .point(22), dieValue: 3)
    try round.performMove(move)

    #expect(round.whiteBar == 0)
    #expect(round.points[21].count == 1)
    #expect(round.points[21].color == .white)
}

@Test
func cannotEnterBlockedPoint() {
    let players: [Player] = makePlayers()
    var points: [PointState] = makeEmptyBoard()
    // Block all entry points for white (points 19-24)
    for i in 18...23 {
        points[i] = PointState(count: 2, color: .black)
    }

    var round: Round = Round(
        players: players,
        points: points,
        state: .waitingForRoll(playerId: "alice"),
        whiteBar: 1
    )

    round.rollDice(cooked: DiceRoll(die1: 3, die2: 5))

    // Should have auto-skipped since no legal entry
    if case .waitingForRoll(let id) = round.state {
        #expect(id == "bob")
    } else {
        #expect(Bool(false), "Turn should have been skipped")
    }
}

// MARK: - Bearing off tests

@Test
func canBearOffWithExactRoll() throws {
    let players: [Player] = makePlayers()
    var points: [PointState] = makeEmptyBoard()
    points[2] = PointState(count: 1, color: .white)  // Point 3

    var round: Round = Round(
        players: players,
        points: points,
        state: .waitingForMove(playerId: "alice"),
        whiteBorneOff: 14,
        currentDice: DiceRoll(die1: 3, die2: 1),
        remainingMoves: [3]
    )

    let move: Move = Move(from: .point(3), to: .bearOff, dieValue: 3)
    try round.performMove(move)

    #expect(round.whiteBorneOff == 15)
}

@Test
func canBearOffWithHighDie() throws {
    let players: [Player] = makePlayers()
    var points: [PointState] = makeEmptyBoard()
    points[2] = PointState(count: 1, color: .white)  // Point 3: highest occupied

    var round: Round = Round(
        players: players,
        points: points,
        state: .waitingForMove(playerId: "alice"),
        whiteBorneOff: 14,
        currentDice: DiceRoll(die1: 5, die2: 6),
        remainingMoves: [5]
    )

    // Die 5 > highest occupied value (3) → can bear off from point 3
    let move: Move = Move(from: .point(3), to: .bearOff, dieValue: 5)
    try round.performMove(move)

    #expect(round.whiteBorneOff == 15)
}

@Test
func cannotBearOffUntilAllInHome() {
    let players: [Player] = makePlayers()
    var points: [PointState] = makeEmptyBoard()
    points[2] = PointState(count: 1, color: .white)    // Point 3 (home)
    points[12] = PointState(count: 1, color: .white)   // Point 13 (not home)

    let round: Round = Round(
        players: players,
        points: points,
        state: .waitingForMove(playerId: "alice"),
        whiteBorneOff: 13,
        currentDice: DiceRoll(die1: 3, die2: 5),
        remainingMoves: [3, 5]
    )

    let moves: [Move] = round.allLegalMoves(for: .white)
    let bearOffMoves: [Move] = moves.filter {
        if case .bearOff = $0.to { return true }
        return false
    }
    #expect(bearOffMoves.isEmpty, "Cannot bear off with checker outside home")
}

@Test
func canMoveWithinHomeDuringBearOff() throws {
    let players: [Player] = makePlayers()
    var points: [PointState] = makeEmptyBoard()
    points[5] = PointState(count: 2, color: .white)  // Point 6
    points[2] = PointState(count: 1, color: .white)  // Point 3

    var round: Round = Round(
        players: players,
        points: points,
        state: .waitingForMove(playerId: "alice"),
        whiteBorneOff: 12,
        currentDice: DiceRoll(die1: 2, die2: 3),
        remainingMoves: [2]
    )

    // Move from point 6 to point 4 within home
    let move: Move = Move(from: .point(6), to: .point(4), dieValue: 2)
    try round.performMove(move)

    #expect(round.points[5].count == 1)
    #expect(round.points[3].count == 1)
    #expect(round.points[3].color == .white)
}

// MARK: - Win condition tests

@Test
func winByBearingOffAllCheckers() throws {
    let players: [Player] = makePlayers()
    var points: [PointState] = makeEmptyBoard()
    points[2] = PointState(count: 1, color: .white)

    var round: Round = Round(
        players: players,
        points: points,
        state: .waitingForMove(playerId: "alice"),
        whiteBorneOff: 14,
        currentDice: DiceRoll(die1: 3, die2: 5),
        remainingMoves: [3]
    )

    try round.performMove(Move(from: .point(3), to: .bearOff, dieValue: 3))

    #expect(winnerID(round) == "alice")
    #expect(round.completed != nil)
    #expect(round.state.isComplete)
}

@Test
func cannotActAfterGameComplete() throws {
    let players: [Player] = makePlayers()
    var points: [PointState] = makeEmptyBoard()
    points[2] = PointState(count: 1, color: .white)

    var round: Round = Round(
        players: players,
        points: points,
        state: .waitingForMove(playerId: "alice"),
        whiteBorneOff: 14,
        currentDice: DiceRoll(die1: 3, die2: 5),
        remainingMoves: [3]
    )

    try round.performMove(Move(from: .point(3), to: .bearOff, dieValue: 3))
    #expect(round.state.isComplete)

    #expect(throws: BackgammonError.notWaitingForMove) {
        try round.performMove(Move(from: .point(6), to: .point(1), dieValue: 5))
    }
}

// MARK: - Doubles tests

@Test
func doublesAllowFourMoves() throws {
    var round: Round = Round(players: makePlayers())
    round.rollDice(cooked: DiceRoll(die1: 1, die2: 1))

    #expect(round.remainingMoves.count == 4)

    // White moves: point 8 → 7 four times (all from point 8 which has 3 checkers, and point 6 which has 5)
    try round.performMove(Move(from: .point(8), to: .point(7), dieValue: 1))
    #expect(round.remainingMoves.count == 3)

    try round.performMove(Move(from: .point(8), to: .point(7), dieValue: 1))
    #expect(round.remainingMoves.count == 2)

    try round.performMove(Move(from: .point(8), to: .point(7), dieValue: 1))
    #expect(round.remainingMoves.count == 1)

    try round.performMove(Move(from: .point(6), to: .point(5), dieValue: 1))
    // All 4 dice used, turn over
    if case .waitingForRoll(let id) = round.state {
        #expect(id == "bob")
    } else {
        #expect(Bool(false), "Expected turn to end after 4 moves")
    }
}

// MARK: - Turn alternation tests

@Test
func turnAlternatesBetweenPlayers() throws {
    var round: Round = Round(players: makePlayers())

    // Alice's turn
    round.rollDice(cooked: DiceRoll(die1: 3, die2: 5))
    try round.performMove(Move(from: .point(13), to: .point(8), dieValue: 5))
    try round.performMove(Move(from: .point(8), to: .point(5), dieValue: 3))

    #expect(currentPlayerId(round) == "bob")

    // Bob's turn
    round.rollDice(cooked: DiceRoll(die1: 3, die2: 5))
    try round.performMove(Move(from: .point(12), to: .point(17), dieValue: 5))
    try round.performMove(Move(from: .point(17), to: .point(20), dieValue: 3))

    #expect(currentPlayerId(round) == "alice")
}

// MARK: - Log tests

@Test
func turnActionsLoggedCorrectly() throws {
    var round: Round = Round(players: makePlayers())
    round.rollDice(cooked: DiceRoll(die1: 3, die2: 5))
    try round.performMove(Move(from: .point(13), to: .point(8), dieValue: 5))
    try round.performMove(Move(from: .point(8), to: .point(5), dieValue: 3))

    #expect(round.log.count == 1)
    #expect(round.log[0].playerId == "alice")
    #expect(round.log[0].dice == DiceRoll(die1: 3, die2: 5))
    #expect(round.log[0].moves.count == 2)
}

@Test
func logTrimsToMaxActions() throws {
    var round: Round = Round(players: makePlayers())
    var turnCount: Int = 0
    let maxTurns: Int = 150

    while round.state.isComplete == false && turnCount < maxTurns {
        switch round.state {
        case .waitingForRoll(let id):
            round.rollDice(cooked: .random())
            if case .waitingForMove = round.state {
                let ai: AIEngine = AIEngine(difficulty: .easy)
                while case .waitingForMove(let moveId) = round.state, moveId == id {
                    guard let move: Move = ai.getBestMove(for: round, playerId: id) else { break }
                    round.performMoveUnchecked(move)
                }
            }
            turnCount += 1
        default:
            break
        }
    }
    #expect(round.log.count <= Round.maxLogActions)
}

// MARK: - Legal moves tests

@Test
func legalMovesFromInitialPosition() {
    var round: Round = Round(players: makePlayers())
    round.rollDice(cooked: DiceRoll(die1: 3, die2: 5))

    let moves: [Move] = round.allLegalMoves(for: .white)
    #expect(moves.isEmpty == false)

    for move in moves {
        #expect(move.dieValue == 3 || move.dieValue == 5)
    }
}

@Test
func noMovesFromEmptyPoint() {
    var round: Round = Round(players: makePlayers())
    round.rollDice(cooked: DiceRoll(die1: 3, die2: 5))

    let moves: [Move] = round.allLegalMoves(for: .white)
    let fromPoint10: [Move] = moves.filter {
        if case .point(10) = $0.from { return true }
        return false
    }
    #expect(fromPoint10.isEmpty, "No checkers on point 10, so no moves from there")
}

@Test
func cannotLandOnBlockedPoint() {
    let players: [Player] = makePlayers()
    var points: [PointState] = makeEmptyBoard()
    points[7] = PointState(count: 1, color: .white)   // Point 8
    points[4] = PointState(count: 2, color: .black)   // Point 5 (blocked)

    let round: Round = Round(
        players: players,
        points: points,
        state: .waitingForMove(playerId: "alice"),
        currentDice: DiceRoll(die1: 3, die2: 5),
        remainingMoves: [3]
    )

    let moves: [Move] = round.legalMoves(for: .white, dieValue: 3)
    let toPoint5: [Move] = moves.filter {
        if case .point(5) = $0.to { return true }
        return false
    }
    #expect(toPoint5.isEmpty, "Cannot land on point blocked by 2+ opponent checkers")
}

// MARK: - Board geometry tests

@Test
func homeRanges() {
    #expect(Round.homeRange(for: .white) == 1...6)
    #expect(Round.homeRange(for: .black) == 19...24)
}

@Test
func homePointValues() {
    #expect(Round.homePointValue(point: 1, for: .white) == 1)
    #expect(Round.homePointValue(point: 6, for: .white) == 6)
    #expect(Round.homePointValue(point: 24, for: .black) == 1)
    #expect(Round.homePointValue(point: 19, for: .black) == 6)
}

@Test
func barEntryPoints() {
    #expect(Round.barEntryPoint(color: .white, dieValue: 1) == 24)
    #expect(Round.barEntryPoint(color: .white, dieValue: 6) == 19)
    #expect(Round.barEntryPoint(color: .black, dieValue: 1) == 1)
    #expect(Round.barEntryPoint(color: .black, dieValue: 6) == 6)
}

@Test
func destinations() {
    #expect(Round.destination(from: 13, color: .white, dieValue: 5) == 8)
    #expect(Round.destination(from: 1, color: .black, dieValue: 5) == 6)
}

// MARK: - Pip count tests

@Test
func initialPipCount() {
    let round: Round = Round(players: makePlayers())
    #expect(round.pipCount(for: .white) == 167)
    #expect(round.pipCount(for: .black) == 167)
}

// MARK: - Fake tests

@Test
func playerFakeHasDefaults() {
    let player: Player = Player.fake()
    #expect(player.name == "Fake Player")
    #expect(player.id.isEmpty == false)
    #expect(player.checkerColor == .white)
}

@Test
func roundFakeCreatesValidGame() {
    let round: Round = Round.fake()
    #expect(round.players.count == 2)
    #expect(round.checkerCount(for: .white) == 15)
    #expect(round.checkerCount(for: .black) == 15)
    #expect(round.state.isComplete == false)
}

@Test
func diceRollFakeHasDefaults() {
    let dice: DiceRoll = DiceRoll.fake()
    #expect(dice.die1 == 3)
    #expect(dice.die2 == 5)
    #expect(dice.isDoubles == false)
}

@Test
func moveFakeHasDefaults() {
    let move: Move = Move.fake()
    #expect(move.from == .point(13))
    #expect(move.to == .point(8))
    #expect(move.dieValue == 5)
}

@Test
func turnActionFakeHasDefaults() {
    let action: Round.TurnAction = Round.TurnAction.fake()
    #expect(action.playerId == "fakePlayer")
    #expect(action.moves.isEmpty)
}

@Test
func pointStateFakeHasDefaults() {
    let point: PointState = PointState.fake()
    #expect(point.count == 3)
    #expect(point.color == .white)
}

// MARK: - Codable tests

@Test
func roundEncodesAndDecodes() throws {
    let round: Round = Round(players: makePlayers())
    let encoder: JSONEncoder = .init()
    let decoder: JSONDecoder = .init()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    let data: Data = try encoder.encode(round)
    let decoded: Round = try decoder.decode(Round.self, from: data)
    #expect(decoded == round)
}

@Test
func playerEncodesAndDecodes() throws {
    let player: Player = Player(
        id: "test", name: "Test",
        imageURL: URL(string: "https://example.com/img.png"),
        checkerColor: .white
    )
    let encoder: JSONEncoder = .init()
    let decoder: JSONDecoder = .init()

    let data: Data = try encoder.encode(player)
    let decoded: Player = try decoder.decode(Player.self, from: data)
    #expect(decoded == player)
}

@Test
func diceRollEncodesAndDecodes() throws {
    let dice: DiceRoll = DiceRoll(die1: 4, die2: 2)
    let encoder: JSONEncoder = .init()
    let decoder: JSONDecoder = .init()

    let data: Data = try encoder.encode(dice)
    let decoded: DiceRoll = try decoder.decode(DiceRoll.self, from: data)
    #expect(decoded == dice)
}

// MARK: - AI tests

@Test
func easyAIReturnsValidMove() {
    let players: [Player] = makePlayers()
    var round: Round = Round(players: players)
    round.rollDice(cooked: DiceRoll(die1: 3, die2: 5))

    let ai: AIEngine = AIEngine(difficulty: .easy)
    let move: Move? = ai.getBestMove(for: round, playerId: "alice")
    #expect(move != nil)
    let legalMoves: [Move] = round.allLegalMoves(for: .white)
    #expect(legalMoves.contains(move!))
}

@Test
func mediumAIReturnsValidMove() {
    let players: [Player] = makePlayers()
    var round: Round = Round(players: players)
    round.rollDice(cooked: DiceRoll(die1: 3, die2: 5))

    let ai: AIEngine = AIEngine(difficulty: .medium)
    let move: Move? = ai.getBestMove(for: round, playerId: "alice")
    #expect(move != nil)
    let legalMoves: [Move] = round.allLegalMoves(for: .white)
    #expect(legalMoves.contains(move!))
}

@Test
func hardAIReturnsValidMove() {
    let players: [Player] = makePlayers()
    var round: Round = Round(players: players)
    round.rollDice(cooked: DiceRoll(die1: 3, die2: 5))

    let ai: AIEngine = AIEngine(difficulty: .hard)
    let move: Move? = ai.getBestMove(for: round, playerId: "alice")
    #expect(move != nil)
    let legalMoves: [Move] = round.allLegalMoves(for: .white)
    #expect(legalMoves.contains(move!))
}

@Test
func aiNoMovesOnEmptyBoard() {
    let players: [Player] = makePlayers()
    let points: [PointState] = makeEmptyBoard()
    let round: Round = Round(
        players: players,
        points: points,
        state: .waitingForMove(playerId: "alice"),
        currentDice: DiceRoll(die1: 3, die2: 5),
        remainingMoves: [3, 5]
    )

    let ai: AIEngine = AIEngine(difficulty: .easy)
    let move: Move? = ai.getBestMove(for: round, playerId: "alice")
    #expect(move == nil)
}

@Test
func aiPlayerCreation() {
    let aiPlayer: AIPlayer = Player.aiPlayer(
        name: "Test AI",
        difficulty: .hard,
        checkerColor: .black
    )
    #expect(aiPlayer.name == "Test AI")
    #expect(aiPlayer.difficulty == .hard)
    #expect(aiPlayer.checkerColor == .black)
    #expect(aiPlayer.id.isEmpty == false)
}

@Test
func aiPlayerConversion() {
    let aiPlayer: AIPlayer = Player.aiPlayer(difficulty: .medium, checkerColor: .white)
    let regularPlayer: Player = aiPlayer.asPlayer
    #expect(regularPlayer.id == aiPlayer.id)
    #expect(regularPlayer.name == aiPlayer.name)
    #expect(regularPlayer.checkerColor == aiPlayer.checkerColor)
}

// MARK: - Full game playthrough

@Test
func fullGamePlaythrough() throws {
    var round: Round = Round(players: makePlayers())
    var turnCount: Int = 0
    let maxTurns: Int = 1000

    while round.state.isComplete == false && turnCount < maxTurns {
        guard case .waitingForRoll(let currentId) = round.state else { break }
        try round.makeAITurn(difficulty: .easy, playerId: currentId)
        turnCount += 1
    }

    #expect(round.state.isComplete, "Game should complete within \(maxTurns) turns")
    #expect(winnerID(round) != nil)
    #expect(round.completed != nil)
}

@Test
func aiVsAiMediumGame() throws {
    var round: Round = Round(players: makePlayers())
    var turnCount: Int = 0
    let maxTurns: Int = 1000

    while round.state.isComplete == false && turnCount < maxTurns {
        guard case .waitingForRoll(let currentId) = round.state else { break }
        let difficulty: AIDifficulty = round.playerColor(for: currentId) == .white
            ? .medium : .easy
        try round.makeAITurn(difficulty: difficulty, playerId: currentId)
        turnCount += 1
    }

    #expect(round.state.isComplete, "AI vs AI game should complete")
}

@Test
func aiVsAiHardGame() throws {
    var round: Round = Round(players: makePlayers())
    var turnCount: Int = 0
    let maxTurns: Int = 1000

    while round.state.isComplete == false && turnCount < maxTurns {
        guard case .waitingForRoll(let currentId) = round.state else { break }
        try round.makeAITurn(difficulty: .hard, playerId: currentId)
        turnCount += 1
    }

    #expect(round.state.isComplete, "AI vs AI hard game should complete")
}

// MARK: - Black player move tests

@Test
func blackMovesForward() throws {
    var round: Round = Round(players: makePlayers())

    // Alice's turn (white)
    round.rollDice(cooked: DiceRoll(die1: 1, die2: 2))
    try round.performMove(Move(from: .point(6), to: .point(5), dieValue: 1))
    try round.performMove(Move(from: .point(6), to: .point(4), dieValue: 2))

    // Bob's turn (black) - moves from lower to higher
    round.rollDice(cooked: DiceRoll(die1: 3, die2: 5))
    try round.performMove(Move(from: .point(12), to: .point(15), dieValue: 3))

    #expect(round.points[11].count == 4)  // Point 12: was 5, now 4
    #expect(round.points[14].count == 1)  // Point 15: new checker
    #expect(round.points[14].color == .black)
}

@Test
func blackEntersFromBar() throws {
    let players: [Player] = makePlayers()
    var points: [PointState] = makeEmptyBoard()
    points[18] = PointState(count: 3, color: .black)

    var round: Round = Round(
        players: players,
        points: points,
        state: .waitingForMove(playerId: "bob"),
        blackBar: 1,
        currentDice: DiceRoll(die1: 4, die2: 2),
        remainingMoves: [4, 2]
    )

    // Black enters from bar: die 4 → point 4
    let move: Move = Move(from: .bar, to: .point(4), dieValue: 4)
    try round.performMove(move)

    #expect(round.blackBar == 0)
    #expect(round.points[3].count == 1)
    #expect(round.points[3].color == .black)
}

// MARK: - Edge case tests

@Test
func skippedTurnLogsEmptyMoves() {
    let players: [Player] = makePlayers()
    var points: [PointState] = makeEmptyBoard()
    for i in 18...23 {
        points[i] = PointState(count: 2, color: .black)
    }

    var round: Round = Round(
        players: players,
        points: points,
        state: .waitingForRoll(playerId: "alice"),
        whiteBar: 1
    )

    round.rollDice(cooked: DiceRoll(die1: 3, die2: 5))

    #expect(round.log.count == 1)
    #expect(round.log[0].moves.isEmpty)
    #expect(round.log[0].playerId == "alice")
}

@Test
func checkerColorProperties() {
    #expect(CheckerColor.white.opposite == .black)
    #expect(CheckerColor.black.opposite == .white)
    #expect(CheckerColor.white.displayableName == "White")
    #expect(CheckerColor.black.displayableName == "Black")
    #expect(CheckerColor.white.direction == -1)
    #expect(CheckerColor.black.direction == 1)
}

@Test
func diceRollDoubles() {
    let doubles: DiceRoll = DiceRoll(die1: 3, die2: 3)
    #expect(doubles.isDoubles == true)
    #expect(doubles.values == [3, 3, 3, 3])

    let nonDoubles: DiceRoll = DiceRoll(die1: 3, die2: 5)
    #expect(nonDoubles.isDoubles == false)
    #expect(nonDoubles.values == [3, 5])
}

@Test
func allCheckersInHomeDetection() {
    let players: [Player] = makePlayers()

    // All white checkers in home (points 1-6)
    var points: [PointState] = makeEmptyBoard()
    points[0] = PointState(count: 5, color: .white)  // Point 1
    points[2] = PointState(count: 5, color: .white)  // Point 3
    points[5] = PointState(count: 5, color: .white)  // Point 6

    let round: Round = Round(
        players: players,
        points: points,
        state: .waitingForRoll(playerId: "alice")
    )
    #expect(round.allCheckersInHome(for: .white) == true)

    // Not all in home
    let standardRound: Round = Round(players: players)
    #expect(standardRound.allCheckersInHome(for: .white) == false)
}
