import Foundation

public struct DiceRoll: Equatable, Codable, Sendable {
    public let die1: Int
    public let die2: Int

    public init(die1: Int, die2: Int) {
        self.die1 = die1
        self.die2 = die2
    }

    public var isDoubles: Bool {
        die1 == die2
    }

    public var values: [Int] {
        isDoubles ? [die1, die1, die1, die1] : [die1, die2]
    }

    public static func random() -> DiceRoll {
        DiceRoll(
            die1: Int.random(in: 1...6),
            die2: Int.random(in: 1...6)
        )
    }
}
