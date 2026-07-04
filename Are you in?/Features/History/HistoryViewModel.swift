import Foundation
import Observation

@Observable
@MainActor
final class HistoryViewModel {
    private(set) var myResponses: [HistoryResponseEntry] = []
    private(set) var matches: [HistoryMatchEntry] = []
    private(set) var isLoading = true
    var errorMessage: String?

    private let api = APIClient.shared

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let responses = api.myResponseHistory()
            async let matchList = api.matchHistory()
            (myResponses, matches) = try await (responses, matchList)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
