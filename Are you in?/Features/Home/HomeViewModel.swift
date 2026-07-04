import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    private(set) var incomingInvite: PendingSession?
    private(set) var mySessionSummary: SessionSummary?
    private(set) var isLoading = false
    var errorMessage: String?

    private let api = APIClient.shared
    private var pollTask: Task<Void, Never>?

    func load(showsLoading: Bool = true) async {
        if showsLoading {
            isLoading = true
        }
        defer { if showsLoading { isLoading = false } }
        do {
            async let pending = api.pendingSessions()
            async let active = api.activeSessions()
            let (pendingList, activeList) = try await (pending, active)

            incomingInvite = pendingList.first
            // My own view of a round I'm part of - either one I started (still pending
            // partner's accept) or one that's already active.
            mySessionSummary = activeList.first
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Keeps the home screen in sync without a manual pull-to-refresh - most relevant
    /// while waiting for a partner to accept/decline an invite or finish their answers.
    func startPolling() {
        stopPolling()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(4))
                if Task.isCancelled { return }
                await self?.load(showsLoading: false)
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    func startSession(itemCount: Int) async -> SessionDetail? {
        errorMessage = nil
        do {
            let session = try await api.createSession(itemCount: itemCount)
            await load()
            return session
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func acceptInvite() async -> String? {
        guard let invite = incomingInvite else { return nil }
        do {
            try await api.acceptSession(id: invite.id)
            await load()
            return invite.id
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func declineInvite() async {
        guard let invite = incomingInvite else { return }
        do {
            try await api.declineSession(id: invite.id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
