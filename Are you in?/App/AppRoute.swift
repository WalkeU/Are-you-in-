import Foundation

enum AppRoute: Hashable {
    case game(sessionId: String)
    case results(sessionId: String)
    case history
}
