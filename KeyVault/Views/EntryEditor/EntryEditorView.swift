import SwiftUI
import SwiftData

/// Create or edit a vault entry.
struct EntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState

    /// If editing an existing entry; nil = creating new.
    var entry: Entry?

    @State private var name = ""
    @State private var provider = ""
    @State private var type: EntryType = .apiKey
    @State private var expiresAt: Date?
    @State private var hasExpiry = false
    @State private var tags = ""
    @State private var notes = ""
    @State private var fieldEntries: [FieldEntry] = []
    @State private var error: String?

    struct FieldEntry: Identifiable {
        let id = UUID()
        var label: String
        var value: String
        var isSensitive: Bool
    }

    var isEditing: Bool { entry != nil }

    var body: some View {
        VStack(spacing: 0) {
            // Title
            HStack {
                Text(isEditing ? "Edit Entry" : "New Entry")
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding(16)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Basic info
                    Group {
                        TextField("Name", text: $name)
                            .textFieldStyle(.roundedBorder)

                        TextField("Provider (e.g. OpenAI, GitHub)", text: $provider)
                            .textFieldStyle(.roundedBorder)

                        Picker("Type", selection: $type) {
                            ForEach(EntryType.allCases) { entryType in
                                Label(entryType.rawValue, systemImage: entryType.icon)
                                    .tag(entryType)
                            }
                        }
                        .onChange(of: type) { _, newType in
                            if !isEditing && fieldEntries.isEmpty {
                                applyTemplate(for: newType)
                            }
                        }
                    }

                    // Expiry
                    Toggle("Has Expiration Date", isOn: $hasExpiry)
                    if hasExpiry {
                        DatePicker("Expires", selection: Binding(
                            get: { expiresAt ?? Date() },
                            set: { expiresAt = $0 }
                        ), displayedComponents: .date)
                    }

                    Divider()

                    // Fields
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Fields")
                                .font(.headline)
                            Spacer()
                            Button {
                                fieldEntries.append(FieldEntry(label: "", value: "", isSensitive: true))
                            } label: {
                                Label("Add Field", systemImage: "plus")
                            }
                            .buttonStyle(.borderless)
                        }

                        ForEach($fieldEntries) { $field in
                            HStack(spacing: 8) {
                                TextField("Label", text: $field.label)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 140)

                                if field.isSensitive {
                                    SecureField("Value", text: $field.value)
                                        .textFieldStyle(.roundedBorder)
                                } else {
                                    TextField("Value", text: $field.value)
                                        .textFieldStyle(.roundedBorder)
                                }

                                Toggle("Secret", isOn: $field.isSensitive)
                                    .toggleStyle(.checkbox)
                                    .labelsHidden()
                                    .help("Mark as sensitive")

                                Button {
                                    fieldEntries.removeAll { $0.id == field.id }
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                        }

                        if !isEditing {
                            templateButtons
                        }
                    }

                    Divider()

                    // Tags & Notes
                    TextField("Tags (comma-separated)", text: $tags)
                        .textFieldStyle(.roundedBorder)

                    TextField("Notes", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                .padding(16)
            }

            Divider()

            // Actions
            HStack {
                if let error {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(isEditing ? "Save" : "Create") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .keyboardShortcut(.return)
            }
            .padding(16)
        }
        .frame(width: 560, minHeight: 500)
        .onAppear { loadEntry() }
    }

    @ViewBuilder
    private var templateButtons: some View {
        if fieldEntries.isEmpty {
            HStack {
                Text("Quick fill:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(EntryTemplate.all.filter { $0.type != .custom }) { template in
                    Button(template.type.rawValue) {
                        type = template.type
                        applyTemplate(for: template.type)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    private func applyTemplate(for type: EntryType) {
        let template = EntryTemplate.template(for: type)
        fieldEntries = template.fields.map { FieldEntry(label: $0.label, value: "", isSensitive: $0.isSensitive) }
    }

    private func loadEntry() {
        guard let entry else {
            applyTemplate(for: type)
            return
        }
        name = entry.name
        provider = entry.provider
        type = entry.type
        hasExpiry = entry.expiresAt != nil
        expiresAt = entry.expiresAt
        tags = entry.tags.joined(separator: ", ")
        notes = entry.notes

        // Decrypt existing field values for editing
        guard let key = appState.encryptionKey else { return }
        let service = VaultService(modelContext: modelContext, key: key)
        fieldEntries = entry.fields.sorted(by: { $0.sortOrder < $1.sortOrder }).compactMap { field in
            let value = (try? service.decryptFieldValue(field)) ?? ""
            return FieldEntry(label: field.label, value: value, isSensitive: field.isSensitive)
        }
    }

    private func save() {
        guard let key = appState.encryptionKey else {
            error = "Vault is locked"
            return
        }
        let service = VaultService(modelContext: modelContext, key: key)
        let parsedTags = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

        do {
            if let entry {
                // Update existing
                try service.updateEntry(
                    entry,
                    name: name.trimmingCharacters(in: .whitespaces),
                    provider: provider.trimmingCharacters(in: .whitespaces),
                    type: type,
                    expiresAt: hasExpiry ? expiresAt : nil,
                    tags: parsedTags,
                    notes: notes
                )
                // Re-encrypt fields: delete old, add new
                for field in entry.fields {
                    try service.deleteField(field)
                }
                for fieldEntry in fieldEntries where !fieldEntry.label.isEmpty {
                    try service.addField(
                        to: entry,
                        label: fieldEntry.label,
                        value: fieldEntry.value,
                        isSensitive: fieldEntry.isSensitive
                    )
                }
            } else {
                // Create new
                let fieldValues = fieldEntries
                    .filter { !$0.label.isEmpty }
                    .map { (label: $0.label, value: $0.value, isSensitive: $0.isSensitive) }

                _ = try service.createEntry(
                    name: name.trimmingCharacters(in: .whitespaces),
                    provider: provider.trimmingCharacters(in: .whitespaces),
                    type: type,
                    fieldValues: fieldValues,
                    expiresAt: hasExpiry ? expiresAt : nil,
                    tags: parsedTags,
                    notes: notes
                )
            }
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
