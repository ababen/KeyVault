import Foundation

struct FieldTemplate {
    let label: String
    let isSensitive: Bool
}

struct EntryTemplate: Identifiable {
    let id = UUID()
    let type: EntryType
    let fields: [FieldTemplate]

    static let all: [EntryTemplate] = [
        EntryTemplate(
            type: .apiKey,
            fields: [
                FieldTemplate(label: "API Key", isSensitive: true)
            ]
        ),
        EntryTemplate(
            type: .oauth,
            fields: [
                FieldTemplate(label: "Client ID", isSensitive: false),
                FieldTemplate(label: "Client Secret", isSensitive: true),
                FieldTemplate(label: "Token URL", isSensitive: false),
                FieldTemplate(label: "Scope", isSensitive: false),
                FieldTemplate(label: "Access Token", isSensitive: true),
                FieldTemplate(label: "Refresh Token", isSensitive: true)
            ]
        ),
        EntryTemplate(
            type: .serviceAccount,
            fields: [
                FieldTemplate(label: "Project ID", isSensitive: false),
                FieldTemplate(label: "Client Email", isSensitive: false),
                FieldTemplate(label: "Private Key", isSensitive: true)
            ]
        ),
        EntryTemplate(
            type: .awsIAM,
            fields: [
                FieldTemplate(label: "Access Key ID", isSensitive: false),
                FieldTemplate(label: "Secret Access Key", isSensitive: true),
                FieldTemplate(label: "Region", isSensitive: false)
            ]
        ),
        EntryTemplate(
            type: .custom,
            fields: []
        )
    ]

    static func template(for type: EntryType) -> EntryTemplate {
        all.first { $0.type == type } ?? all.last!
    }
}
