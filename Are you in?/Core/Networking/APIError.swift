import Foundation

struct APIErrorBody: Decodable {
    struct Inner: Decodable {
        let code: String
        let message: String
    }
    let error: Inner
}

enum APIError: Error, LocalizedError, Identifiable {
    case unauthorized
    case server(status: Int, code: String, message: String)
    case transport(Error)
    case decoding(Error)

    var id: String { errorDescription ?? "unknown" }

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "A munkameneted lejárt. Kérlek, jelentkezz be újra."
        case .server(_, _, let message):
            return message
        case .transport:
            return "Nem sikerült kapcsolódni a szerverhez. Ellenőrizd az internetkapcsolatot."
        case .decoding:
            return "Váratlan hiba történt az adatok feldolgozása közben."
        }
    }
}
