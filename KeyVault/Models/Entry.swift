import Foundation
import SwiftData

enum EntryType: String, Codable, CaseIterable, Identifiable {
    case apiKey = "API Key"
    case oauth = "OAuth 2.0"
    case serviceAccount = "Service Account"
    case awsIAM = "AWS IAM"
    case custom = "Custom"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .apiKey: return "key.fill"
        case .oauth: return "arrow.triangle.2.circlepath"
        case .serviceAccount: return "person.badge.key.fill"
        case .awsIAM: return "cloud.fill"
        case .custom: return "square.grid.2x2.fill"
        }
    }
}

@Model
final class Entry {
    var id: UUID
    var name: String
    var provider: String
    var type: EntryType
    @Relationship(deleteRule: .cascade) var fields: [SecureField]
    @Relationship(deleteRule: .cascade) var agentAccess: [AgentGrant]
    var expiresAt: Date?
    var tags: [String]
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        name: String,
        provider: String,
        type: EntryType,
        fields: [SecureField] = [],
        agentAccess: [AgentGrant] = [],
        expiresAt: Date? = nil,
        tags: [String] = [],
        notes: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.provider = provider
        self.type = type
        self.fields = fields
        self.agentAccess = agentAccess
        self.expiresAt = expiresAt
        self.tags = tags
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt < Date()
    }

    var isExpiringSoon: Bool {
        guard let expiresAt else { return false }
        let sevenDays = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return expiresAt < sevenDays && !isExpired
    }

    var expiryStatus: ExpiryStatus {
        if isExpired { return .expired }
        if isExpiringSoon { return .expiringSoon }
        if expiresAt != nil { return .active }
        return .noExpiry
    }
}

enum ExpiryStatus {
    case expired, expiringSoon, active, noExpiry

    var color: String {
        switch self {
        case .expired: return "red"
        case .expiringSoon: return "orange"
        case .active: return "green"
        case .noExpiry: return "secondary"
        }
    }

    var label: String {
        switch self {
        case .expired: return "Expired"
        case .expiringSoon: return "Expiring Soon"
        case .active: return "Active"
        case .noExpiry: return "No Expiry"
        }
    }
}
