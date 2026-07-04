import Foundation
import Observation

@Observable
@MainActor
final class ResultsViewModel {
    let sessionId: String
    private(set) var matches: [MatchResult] = []
    private(set) var isLoading = true
    var errorMessage: String?

    private let api = APIClient.shared

    init(sessionId: String) {
        self.sessionId = sessionId
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            matches = try await api.matches(sessionId: sessionId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
