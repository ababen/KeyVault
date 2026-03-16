import Foundation
import SwiftData

@Model
final class Agent {
    var id: UUID
    var name: String
    var agentDescription: String
    var createdAt: Date

    init(name: String, description: String = "") {
        self.id = UUID()
        self.name = name
        self.agentDescription = description
        self.createdAt = Date()
    }
}
