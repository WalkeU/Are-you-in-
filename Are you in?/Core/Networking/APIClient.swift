import Foundation

/// Talks to the Are You In? backend. Serializes concurrent 401s into a single
/// token refresh so a burst of requests doesn't trigger a refresh storm.
actor APIClient {
    static let shared = APIClient()

    private let baseURL = AppConfig.apiBaseURL
    private let session: URLSession
    private let tokenStore = TokenStore.shared
    private var inFlightRefresh: Task<Void, Error>?

    /// Broadcasts when the refresh token itself is rejected, so the app can route back
    /// to onboarding without every call site needing to know about auth plumbing.
    static let didLogOut = Notification.Name("APIClient.didLogOut")

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        session = URLSession(configuration: config)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = isoFormatterWithFractionalSeconds.date(from: string) { return date }
            if let date = isoFormatter.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }
        return decoder
    }()

    private static let isoFormatterWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    // MARK: - Public API

    func get<Response: Decodable>(_ path: String, authorized: Bool = true) async throws -> Response {
        try await send(path: path, method: "GET", body: Optional<Empty>.none, authorized: authorized)
    }

    func post<Response: Decodable>(_ path: String, authorized: Bool = true) async throws -> Response {
        try await send(path: path, method: "POST", body: Optional<Empty>.none, authorized: authorized)
    }

    func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body, authorized: Bool = true) async throws -> Response {
        try await send(path: path, method: "POST", body: body, authorized: authorized)
    }

    func postNoContent<Body: Encodable>(_ path: String, body: Body, authorized: Bool = true) async throws {
        let _: EmptyResponse = try await send(path: path, method: "POST", body: body, authorized: authorized)
    }

    // MARK: - Core

    private struct Empty: Encodable {}
    private struct EmptyResponse: Decodable {}

    private func send<Body: Encodable, Response: Decodable>(
        path: String,
        method: String,
        body: Body?,
        authorized: Bool,
        isRetry: Bool = false
    ) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body, !(body is Empty) {
            request.httpBody = try Self.encoder.encode(body)
        }

        if authorized {
            guard let token = await tokenStore.accessToken else {
                throw APIError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport(URLError(.badServerResponse))
        }

        if http.statusCode == 204 {
            if Response.self == EmptyResponse.self {
                // swiftlint:disable:next force_cast
                return EmptyResponse() as! Response
            }
        }

        if http.statusCode == 401, authorized, !isRetry {
            try await refreshIfNeeded()
            return try await send(path: path, method: method, body: body, authorized: authorized, isRetry: true)
        }

        guard (200..<300).contains(http.statusCode) else {
            if let errorBody = try? Self.decoder.decode(APIErrorBody.self, from: data) {
                throw APIError.server(status: http.statusCode, code: errorBody.error.code, message: errorBody.error.message)
            }
            throw APIError.server(status: http.statusCode, code: "UNKNOWN", message: "Ismeretlen hiba történt.")
        }

        if data.isEmpty, Response.self == EmptyResponse.self {
            // swiftlint:disable:next force_cast
            return EmptyResponse() as! Response
        }

        do {
            return try Self.decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    private func refreshIfNeeded() async throws {
        if let existing = inFlightRefresh {
            return try await existing.value
        }

        let task = Task<Void, Error> {
            guard let refreshToken = await tokenStore.refreshToken else {
                throw APIError.unauthorized
            }
            do {
                let tokens: AuthTokens = try await send(
                    path: "auth/refresh",
                    method: "POST",
                    body: RefreshBody(refreshToken: refreshToken),
                    authorized: false
                )
                await tokenStore.save(tokens)
            } catch {
                await tokenStore.clear()
                NotificationCenter.default.post(name: Self.didLogOut, object: nil)
                throw APIError.unauthorized
            }
        }
        inFlightRefresh = task
        defer { inFlightRefresh = nil }
        try await task.value
    }

    private struct RefreshBody: Encodable {
        let refreshToken: String
    }
}
