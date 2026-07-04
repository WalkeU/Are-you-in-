import Foundation
import Observation

enum GameStage: Equatable {
    case loading
    case answering
    case waitingForPartner
    case completed
    case failed(String)
}

@Observable
@MainActor
final class GameViewModel {
    let sessionId: String

    /// Fixed for the lifetime of this screen - re-fetching the session reshuffles order
    /// server-side, which would otherwise jumble the deck mid-round.
    private(set) var items: [SessionItem] = []
    private(set) var stage: GameStage = .loading
    private(set) var currentIndex: Int = 0
    /// Non-nil while the give/receive/both follow-up sheet is being shown for `item`.
    var awaitingRoleFor: SessionItem?

    private let api = APIClient.shared
    private var pollTask: Task<Void, Never>?

    init(sessionId: String) {
        self.sessionId = sessionId
    }

    var currentItem: SessionItem? {
        guard currentIndex < items.count else { return nil }
        return items[currentIndex]
    }

    var progress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(currentIndex) / Double(items.count)
    }

    func load() async {
        stage = .loading
        do {
            let detail = try await api.sessionDetail(id: sessionId)
            guard detail.status == .active || detail.status == .completed else {
                stage = .failed("Ez a kör már nem elérhető.")
                return
            }
            items = detail.items
            currentIndex = items.firstIndex(where: { !$0.isAnswered }) ?? items.count

            if detail.status == .completed {
                stage = .completed
            } else if currentIndex >= items.count {
                stage = .waitingForPartner
                startPolling()
            } else {
                stage = .answering
            }
        } catch {
            stage = .failed(error.localizedDescription)
        }
    }

    func answer(_ answer: Bool, role: ResponseRole?) async {
        guard let item = currentItem else { return }
        do {
            let updated = try await api.submitResponse(
                sessionId: sessionId,
                kinkId: item.kinkId,
                answer: answer,
                role: item.hasRoleVariant ? role : nil
            )
            awaitingRoleFor = nil
            advance(with: updated)
        } catch {
            stage = .failed(error.localizedDescription)
        }
    }

    private func advance(with detail: SessionDetail) {
        currentIndex += 1
        if detail.status == .completed {
            pollTask?.cancel()
            stage = .completed
        } else if currentIndex >= items.count {
            stage = .waitingForPartner
            startPolling()
        }
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                if Task.isCancelled { return }
                do {
                    let detail = try await api.sessionDetail(id: sessionId)
                    if detail.status == .completed {
                        stage = .completed
                        return
                    }
                } catch {
                    // Transient poll failures are silent - the user can still see the
                    // waiting screen and the next tick will retry.
                }
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
    }
}
