import Foundation
import CryptoKit
import SwiftData

/// Encrypted backup and restore of vault data.
@MainActor
final class ExportService {
    private let modelContext: ModelContext
    private let key: SymmetricKey

    init(modelContext: ModelContext, key: SymmetricKey) {
        self.modelContext = modelContext
        self.key = key
    }

    struct ExportableEntry: Codable {
        let name: String
        let provider: String
        let type: String
        let fields: [ExportableField]
        let agentAccess: [ExportableGrant]
        let expiresAt: Date?
        let tags: [String]
        let notes: String
        let createdAt: Date
        let updatedAt: Date
    }

    struct ExportableField: Codable {
        let label: String
        let value: String
        let isSensitive: Bool
    }

    struct ExportableGrant: Codable {
        let agentName: String
        let permission: String
        let grantedAt: Date
    }

    struct VaultExport: Codable {
        let version: Int
        let exportedAt: Date
        let entries: [ExportableEntry]
    }

    /// Export all entries as an encrypted JSON file.
    func exportEncrypted() throws -> Data {
        let descriptor = FetchDescriptor<Entry>()
        let entries = try modelContext.fetch(descriptor)

        let exportable = try entries.map { entry -> ExportableEntry in
            let fields = try entry.fields.sorted(by: { $0.sortOrder < $1.sortOrder }).map { field -> ExportableField in
                let value = try VaultCrypto.decryptField(field, using: key)
                return ExportableField(label: field.label, value: value, isSensitive: field.isSensitive)
            }

            let grants = entry.agentAccess.map { grant in
                ExportableGrant(agentName: grant.agentName, permission: grant.permission.rawValue, grantedAt: grant.grantedAt)
            }

            return ExportableEntry(
                name: entry.name,
                provider: entry.provider,
                type: entry.type.rawValue,
                fields: fields,
                agentAccess: grants,
                expiresAt: entry.expiresAt,
                tags: entry.tags,
                notes: entry.notes,
                createdAt: entry.createdAt,
                updatedAt: entry.updatedAt
            )
        }

        let export = VaultExport(version: 1, exportedAt: Date(), entries: exportable)
        let jsonData = try JSONEncoder().encode(export)

        // Encrypt the entire JSON blob
        let payload = try VaultCrypto.encrypt(String(data: jsonData, encoding: .utf8)!, using: key)
        let container = EncryptedContainer(
            ciphertext: payload.ciphertext,
            nonce: payload.nonce,
            tag: payload.tag
        )
        return try JSONEncoder().encode(container)
    }

    /// Import entries from an encrypted backup file.
    func importEncrypted(data: Data) throws {
        let container = try JSONDecoder().decode(EncryptedContainer.self, from: data)
        let jsonString = try VaultCrypto.decrypt(
            ciphertext: container.ciphertext,
            nonce: container.nonce,
            tag: container.tag,
            using: key
        )

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw ExportError.invalidData
        }

        let export = try JSONDecoder().decode(VaultExport.self, from: jsonData)
        let service = VaultService(modelContext: modelContext, key: key)

        for exportEntry in export.entries {
            let entryType = EntryType(rawValue: exportEntry.type) ?? .custom
            let fieldValues = exportEntry.fields.map {
                (label: $0.label, value: $0.value, isSensitive: $0.isSensitive)
            }
            let grants = exportEntry.agentAccess.map {
                (name: $0.agentName, permission: AgentPermission(rawValue: $0.permission) ?? .read)
            }

            _ = try service.createEntry(
                name: exportEntry.name,
                provider: exportEntry.provider,
                type: entryType,
                fieldValues: fieldValues,
                agentGrants: grants,
                expiresAt: exportEntry.expiresAt,
                tags: exportEntry.tags,
                notes: exportEntry.notes
            )
        }
    }

    struct EncryptedContainer: Codable {
        let ciphertext: Data
        let nonce: Data
        let tag: Data
    }
}

enum ExportError: LocalizedError {
    case invalidData

    var errorDescription: String? {
        switch self {
        case .invalidData: return "Invalid export data"
        }
    }
}
