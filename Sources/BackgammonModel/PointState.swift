import Foundation

public struct PointState: Equatable, Codable, Sendable {
    public var count: Int
    public var color: CheckerColor?

    public init(count: Int, color: CheckerColor?) {
        self.count = count
        self.color = color
    }

    public static let empty: PointState = PointState(count: 0, color: nil)
}
