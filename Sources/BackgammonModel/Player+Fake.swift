import Foundation

extension Player {
    public static func fake(
        id: PlayerID = UUID().uuidString,
        name: String = "Fake Player",
        imageURL: URL? = nil,
        checkerColor: CheckerColor = .white
    ) -> Self {
        Player(
            id: id,
            name: name,
            imageURL: imageURL,
            checkerColor: checkerColor
        )
    }
}
