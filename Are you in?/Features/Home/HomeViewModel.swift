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
    /// Guards against the background poll racing a manual load (e.g. right after
    /// starting a session) - whichever request happened to land second would
    /// otherwise clobber the other's result, flashing a stale error or state.
    private var isLoadInFlight = false

    func load(showsLoading: Bool = true) async {
        guard !isLoadInFlight else { return }
        isLoadInFlight = true
        if showsLoading {
            isLoading = true
        }
        defer {
            isLoadInFlight = false
            if showsLoading { isLoading = false }
        }
        do {
            try await fetchAndApply()
            errorMessage = nil
        } catch {
            // A cancelled request (e.g. this exact load got superseded/stopped) isn't a
            // real failure - surfacing it as an error banner would just be noise.
            if !Task.isCancelled { errorMessage = error.localizedDescription }
        }
    }

    private func fetchAndApply() async throws {
        async let pending = api.pendingSessions()
        async let active = api.activeSessions()
        let (pendingList, activeList) = try await (pending, active)

        incomingInvite = pendingList.first
        // My own view of a round I'm part of - either one I started (still pending
        // partner's accept) or one that's already active.
        mySessionSummary = activeList.first
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

    func startSession(
        itemCount: Int,
        maxIntensity: KinkIntensity,
        exactIntensity: Bool,
        initiatorId: String,
        partnerId: String
    ) async -> SessionDetail? {
        errorMessage = nil
        isLoading = true
        stopPolling()
        defer {
            isLoading = false
            startPolling()
        }
        do {
            let session = try await api.createSession(
                itemCount: itemCount,
                maxIntensity: maxIntensity,
                exactIntensity: exactIntensity
            )
            // Build the "waiting" state straight from the create response instead of
            // firing a second fetch afterward - a background poll response dispatched
            // just before the round existed could otherwise land after that fetch and
            // stomp the correct state back to nothing, which is what was leaving the
            // start screen showing instead of the waiting card.
            mySessionSummary = SessionSummary(
                id: session.id,
                initiatorId: initiatorId,
                partnerId: partnerId,
                itemCount: session.itemCount,
                status: session.status,
                createdAt: session.createdAt
            )
            errorMessage = nil
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
