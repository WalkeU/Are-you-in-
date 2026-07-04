import Foundation

/// Holds the current auth token pair in memory and mirrors it to the Keychain so
/// sessions survive app relaunches. Actor-isolated since refresh can race concurrent
/// requests hitting 401 at the same time.
actor TokenStore {
    static let shared = TokenStore()

    private let keychain = KeychainStore()
    private let accessKey = "accessToken"
    private let refreshKey = "refreshToken"

    private(set) var accessToken: String?
    private(set) var refreshToken: String?

    private init() {
        accessToken = keychain.get(accessKey)
        refreshToken = keychain.get(refreshKey)
    }

    var isAuthenticated: Bool { refreshToken != nil }

    func save(_ tokens: AuthTokens) {
        accessToken = tokens.accessToken
        refreshToken = tokens.refreshToken
        keychain.set(tokens.accessToken, for: accessKey)
        keychain.set(tokens.refreshToken, for: refreshKey)
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
        keychain.remove(accessKey)
        keychain.remove(refreshKey)
    }
}
