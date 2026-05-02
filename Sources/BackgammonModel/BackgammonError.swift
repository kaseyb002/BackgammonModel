import Foundation

public enum BackgammonError: Error, Sendable {
    case gameAlreadyComplete
    case invalidMove
    case notWaitingForRoll
    case notWaitingForMove
}
