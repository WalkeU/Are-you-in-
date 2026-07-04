import Foundation
import Observation

enum AuthPhase: Equatable {
    case bootstrapping
    case loggedOut
    case awaitingPartner(User)
    case ready(User, PartnerSummary)
}

/// Single source of truth for "who am I / am I paired" - drives which flow `RootView`
/// shows. Screens read/write through here instead of each owning their own copy of the
/// session, so pairing or logging out anywhere immediately updates the whole app.
@Observable
@MainActor
final class AppState {
    private(set) var phase: AuthPhase = .bootstrapping
    var errorMessage: String?

    private let api = APIClient.shared
    private let tokenStore = TokenStore.shared

    init() {
        Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(named: APIClient.didLogOut)
            for await _ in notifications {
                self?.phase = .loggedOut
            }
        }
    }

    func bootstrap() async {
        guard await tokenStore.isAuthenticated else {
            phase = .loggedOut
            return
        }
        await refreshProfile()
    }

    func refreshProfile() async {
        do {
            let me = try await api.me()
            if let partner = me.partner {
                phase = .ready(me.user, partner)
            } else {
                phase = .awaitingPartner(me.user)
            }
        } catch {
            phase = .loggedOut
        }
    }

    func register(name: String) async {
        errorMessage = nil
        do {
            let response = try await api.register(name: name)
            await tokenStore.save(AuthTokens(accessToken: response.accessToken, refreshToken: response.refreshToken))
            phase = .awaitingPartner(response.user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func pair(inviteCode: String) async -> Bool {
        errorMessage = nil
        do {
            _ = try await api.pair(inviteCode: inviteCode)
            await refreshProfile()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func logout() async {
        if let refreshToken = await tokenStore.refreshToken {
            try? await api.logout(refreshToken: refreshToken)
        }
        await tokenStore.clear()
        phase = .loggedOut
    }
}
