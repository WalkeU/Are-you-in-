import Foundation

/// Central place for build-time configuration. `apiBaseURL` defaults to a local backend
/// for DEBUG builds (simulator/localhost and raw IPs are exempt from App Transport
/// Security, so no Info.plist changes are needed for local development) and expects a
/// real HTTPS origin to be injected for release builds.
enum AppConfig {
    static let apiBaseURL: URL = {
        if let override = ProcessInfo.processInfo.environment["API_BASE_URL"], let url = URL(string: override) {
            return url
        }
        #if DEBUG
        return URL(string: "http://192.168.0.150:3000/api")!
        #else
        return URL(string: "https://rui.walkegabor.hu/api")!
        #endif
    }()
}
