import Foundation
import SwiftData

enum AgentPermission: String, Codable, CaseIterable {
    case read = "Read"
    case readWrite = "Read & Write"
}

@Model
final class AgentGrant {
    var id: UUID
    var agentName: String
    var permission: AgentPermission
    var grantedAt: Date
    var entry: Entry?

    init(agentName: String, permission: AgentPermission = .read) {
        self.id = UUID()
        self.agentName = agentName
        self.permission = permission
        self.grantedAt = Date()
    }
}
