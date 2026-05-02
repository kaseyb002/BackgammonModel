import Foundation

extension Round {
    public static func fake(
        players: [Player] = [Player.fake(), Player.fake()]
    ) -> Self {
        Round(players: players)
    }
}

extension Round.TurnAction {
    public static func fake(
        playerId: PlayerID = "fakePlayer",
        dice: DiceRoll = DiceRoll(die1: 3, die2: 5),
        moves: [Move] = [],
        timestamp: Date = .now
    ) -> Self {
        Round.TurnAction(
            playerId: playerId,
            dice: dice,
            moves: moves,
            timestamp: timestamp
        )
    }
}

extension DiceRoll {
    public static func fake(
        die1: Int = 3,
        die2: Int = 5
    ) -> Self {
        DiceRoll(die1: die1, die2: die2)
    }
}

extension Move {
    public static func fake(
        from: MoveOrigin = .point(13),
        to: MoveDestination = .point(8),
        dieValue: Int = 5
    ) -> Self {
        Move(from: from, to: to, dieValue: dieValue)
    }
}

extension PointState {
    public static func fake(
        count: Int = 3,
        color: CheckerColor? = .white
    ) -> Self {
        PointState(count: count, color: color)
    }
}
