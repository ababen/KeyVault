import SwiftUI

/// Quick picker for choosing an entry template when creating new entries.
struct TemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (EntryType) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Choose a Template")
                .font(.headline)

            Text("Select the type of credential you want to store")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(EntryTemplate.all) { template in
                    Button {
                        onSelect(template.type)
                        dismiss()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: template.type.icon)
                                .font(.title2)
                            Text(template.type.rawValue)
                                .font(.callout)
                                .fontWeight(.medium)
                            Text(fieldSummary(for: template))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .padding(12)
                        .background(.quaternary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button("Cancel") { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
        .padding(20)
        .frame(width: 380)
    }

    private func fieldSummary(for template: EntryTemplate) -> String {
        if template.fields.isEmpty { return "Custom fields" }
        return template.fields.map(\.label).joined(separator: ", ")
    }
}
