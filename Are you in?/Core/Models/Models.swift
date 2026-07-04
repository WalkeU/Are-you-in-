import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let inviteCode: String
    let partnerId: String?
    let createdAt: Date
}

struct PartnerSummary: Codable, Equatable {
    let id: String
    let name: String
}

struct MeResponse: Codable {
    let user: User
    let partner: PartnerSummary?
}

struct AuthTokens: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
}

struct AuthResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
}

struct Kink: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let hasRoleVariant: Bool
}

enum ResponseRole: String, Codable, CaseIterable, Identifiable {
    case give = "GIVE"
    case receive = "RECEIVE"
    case both = "BOTH"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .give: return "Adnám"
        case .receive: return "Kapnám"
        case .both: return "Mindkettő"
        }
    }

    var icon: String {
        switch self {
        case .give: return "arrow.up.circle.fill"
        case .receive: return "arrow.down.circle.fill"
        case .both: return "arrow.up.arrow.down.circle.fill"
        }
    }
}

enum SessionStatus: String, Codable {
    case pending = "PENDING"
    case active = "ACTIVE"
    case completed = "COMPLETED"
    case declined = "DECLINED"
    case cancelled = "CANCELLED"
}

struct SessionSummary: Codable, Identifiable, Equatable {
    let id: String
    let initiatorId: String
    let partnerId: String
    let itemCount: Int
    let status: SessionStatus
    let createdAt: Date
}

struct PendingSession: Codable, Identifiable, Equatable {
    let id: String
    let itemCount: Int
    let status: SessionStatus
    let createdAt: Date
    let initiator: PartnerSummary
}

struct SessionItem: Codable, Identifiable, Equatable {
    let kinkId: String
    let name: String
    let description: String
    let hasRoleVariant: Bool
    let myAnswer: Bool?
    let myRole: ResponseRole?

    var id: String { kinkId }

    var isAnswered: Bool { myAnswer != nil }
}

struct SessionDetail: Codable, Identifiable, Equatable {
    let id: String
    let status: SessionStatus
    let itemCount: Int
    let isInitiator: Bool
    let createdAt: Date
    let acceptedAt: Date?
    let completedAt: Date?
    let items: [SessionItem]
    let myProgress: Int
    let partnerProgress: Int

    var unansweredItems: [SessionItem] { items.filter { !$0.isAnswered } }
    var isMineDone: Bool { myProgress >= itemCount }
    var isPartnerDone: Bool { partnerProgress >= itemCount }
}

struct MatchResult: Codable, Identifiable, Equatable {
    let kinkId: String
    let name: String
    let description: String
    let myRole: ResponseRole?
    let partnerRole: ResponseRole?

    var id: String { kinkId }
}

struct HistoryResponseEntry: Codable, Identifiable, Equatable {
    let sessionId: String
    let kinkId: String
    let name: String
    let description: String
    let answer: Bool
    let role: ResponseRole?
    let answeredAt: Date

    var id: String { "\(sessionId)-\(kinkId)" }
}

struct HistoryMatchEntry: Codable, Identifiable, Equatable {
    let kinkId: String
    let name: String
    let description: String
    let sessionId: String
    let matchedAt: Date

    var id: String { "\(sessionId)-\(kinkId)" }
}
