import Foundation
import SwiftData
import CryptoKit

/// Service for CRUD operations on vault entries with encryption.
@MainActor
final class VaultService {
    private let modelContext: ModelContext
    private let key: SymmetricKey

    init(modelContext: ModelContext, key: SymmetricKey) {
        self.modelContext = modelContext
        self.key = key
    }

    // MARK: - Entry CRUD

    func createEntry(
        name: String,
        provider: String,
        type: EntryType,
        fieldValues: [(label: String, value: String, isSensitive: Bool)],
        agentGrants: [(name: String, permission: AgentPermission)] = [],
        expiresAt: Date? = nil,
        tags: [String] = [],
        notes: String = ""
    ) throws -> Entry {
        let entry = Entry(
            name: name,
            provider: provider,
            type: type,
            expiresAt: expiresAt,
            tags: tags,
            notes: notes
        )

        for (index, fieldValue) in fieldValues.enumerated() {
            let field = SecureField(
                label: fieldValue.label,
                isSensitive: fieldValue.isSensitive,
                sortOrder: index
            )
            try VaultCrypto.encryptField(fieldValue.value, into: field, using: key)
            field.entry = entry
            entry.fields.append(field)
        }

        for grant in agentGrants {
            let agentGrant = AgentGrant(agentName: grant.name, permission: grant.permission)
            agentGrant.entry = entry
            entry.agentAccess.append(agentGrant)
        }

        modelContext.insert(entry)
        try modelContext.save()
        return entry
    }

    func updateEntry(_ entry: Entry, name: String, provider: String, type: EntryType,
                     expiresAt: Date?, tags: [String], notes: String) throws {
        entry.name = name
        entry.provider = provider
        entry.type = type
        entry.expiresAt = expiresAt
        entry.tags = tags
        entry.notes = notes
        entry.updatedAt = Date()
        try modelContext.save()
    }

    func deleteEntry(_ entry: Entry) throws {
        modelContext.delete(entry)
        try modelContext.save()
    }

    // MARK: - Field Operations

    func addField(to entry: Entry, label: String, value: String, isSensitive: Bool) throws {
        let field = SecureField(
            label: label,
            isSensitive: isSensitive,
            sortOrder: entry.fields.count
        )
        try VaultCrypto.encryptField(value, into: field, using: key)
        field.entry = entry
        entry.fields.append(field)
        entry.updatedAt = Date()
        try modelContext.save()
    }

    func updateFieldValue(_ field: SecureField, newValue: String) throws {
        try VaultCrypto.encryptField(newValue, into: field, using: key)
        field.entry?.updatedAt = Date()
        try modelContext.save()
    }

    func decryptFieldValue(_ field: SecureField) throws -> String {
        try VaultCrypto.decryptField(field, using: key)
    }

    func deleteField(_ field: SecureField) throws {
        field.entry?.updatedAt = Date()
        modelContext.delete(field)
        try modelContext.save()
    }

    // MARK: - Agent Grant Operations

    func grantAccess(to entry: Entry, agentName: String, permission: AgentPermission) throws {
        let grant = AgentGrant(agentName: agentName, permission: permission)
        grant.entry = entry
        entry.agentAccess.append(grant)
        entry.updatedAt = Date()
        try modelContext.save()
    }

    func revokeAccess(_ grant: AgentGrant) throws {
        grant.entry?.updatedAt = Date()
        modelContext.delete(grant)
        try modelContext.save()
    }
}
