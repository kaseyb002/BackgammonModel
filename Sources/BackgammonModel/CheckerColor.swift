import Foundation

public enum CheckerColor: String, Equatable, Codable, Sendable, CaseIterable {
    case white
    case black

    public var opposite: CheckerColor {
        switch self {
        case .white: .black
        case .black: .white
        }
    }

    public var displayableName: String {
        switch self {
        case .white: "White"
        case .black: "Black"
        }
    }

    public var direction: Int {
        switch self {
        case .white: -1
        case .black: 1
        }
    }

    public var emoji: String {
        switch self {
        case .white: "⚪"
        case .black: "⚫"
        }
    }
}
