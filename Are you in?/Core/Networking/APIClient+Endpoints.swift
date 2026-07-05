import Foundation

/// Domain-shaped convenience wrappers over the generic `APIClient` request methods,
/// mirroring the backend's `/api/*` routes one-to-one.
extension APIClient {
    // Auth
    func register(name: String) async throws -> AuthResponse {
        try await post("auth/register", body: ["name": name], authorized: false)
    }

    func pair(inviteCode: String) async throws -> MeResponse.PairResult {
        try await post("auth/pair", body: ["inviteCode": inviteCode])
    }

    func logout(refreshToken: String) async throws {
        try await postNoContent("auth/logout", body: ["refreshToken": refreshToken], authorized: false)
    }

    // Profile
    func me() async throws -> MeResponse {
        try await get("me")
    }

    // Kinks
    func kinks() async throws -> [Kink] {
        let response: KinksResponse = try await get("kinks")
        return response.kinks
    }

    // Sessions
    func createSession(itemCount: Int, maxIntensity: KinkIntensity, exactIntensity: Bool) async throws -> SessionDetail {
        struct Body: Encodable {
            let itemCount: Int
            let maxIntensity: Int
            let exactIntensity: Bool
        }
        let response: SessionEnvelope<SessionDetail> = try await post(
            "sessions",
            body: Body(itemCount: itemCount, maxIntensity: maxIntensity.rawValue, exactIntensity: exactIntensity)
        )
        return response.session
    }

    func pendingSessions() async throws -> [PendingSession] {
        let response: PendingSessionsResponse = try await get("sessions/pending")
        return response.sessions
    }

    func activeSessions() async throws -> [SessionSummary] {
        let response: ActiveSessionsResponse = try await get("sessions/active")
        return response.sessions
    }

    func sessionDetail(id: String) async throws -> SessionDetail {
        let response: SessionEnvelope<SessionDetail> = try await get("sessions/\(id)")
        return response.session
    }

    func acceptSession(id: String) async throws {
        let _: SessionEnvelope<SessionSummary> = try await post("sessions/\(id)/accept")
    }

    func declineSession(id: String) async throws {
        let _: SessionEnvelope<SessionSummary> = try await post("sessions/\(id)/decline")
    }

    func submitResponse(sessionId: String, kinkId: String, answer: Bool, role: ResponseRole?) async throws -> SessionDetail {
        struct Body: Encodable {
            let kinkId: String
            let answer: Bool
            let role: ResponseRole?
        }
        let response: SessionEnvelope<SessionDetail> = try await post(
            "sessions/\(sessionId)/responses",
            body: Body(kinkId: kinkId, answer: answer, role: role)
        )
        return response.session
    }

    func matches(sessionId: String) async throws -> [MatchResult] {
        let response: MatchesResponse = try await get("sessions/\(sessionId)/matches")
        return response.matches
    }

    // History
    func myResponseHistory() async throws -> [HistoryResponseEntry] {
        let response: HistoryResponsesResponse = try await get("history/my-responses")
        return response.responses
    }

    func matchHistory() async throws -> [HistoryMatchEntry] {
        let response: HistoryMatchesResponse = try await get("history/matches")
        return response.matches
    }
}

// MARK: - Response envelopes

private struct KinksResponse: Decodable { let kinks: [Kink] }
private struct SessionEnvelope<T: Decodable>: Decodable { let session: T }
private struct PendingSessionsResponse: Decodable { let sessions: [PendingSession] }
private struct ActiveSessionsResponse: Decodable { let sessions: [SessionSummary] }
private struct MatchesResponse: Decodable { let matches: [MatchResult] }
private struct HistoryResponsesResponse: Decodable { let responses: [HistoryResponseEntry] }
private struct HistoryMatchesResponse: Decodable { let matches: [HistoryMatchEntry] }

extension MeResponse {
    struct PairResult: Decodable { let user: User }
}
