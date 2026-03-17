import SwiftUI

struct FieldRow: View {
    let field: VaultSecureField
    let decryptedValue: String?
    let isVisible: Bool
    let isCopied: Bool
    let onToggleVisibility: () -> Void
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(field.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if field.isSensitive {
                    if isVisible, let value = decryptedValue {
                        Text(value)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    } else {
                        Text("••••••••••••••••")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    if let value = decryptedValue {
                        Text(value)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    } else {
                        Text("Loading...")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            HStack(spacing: 4) {
                if field.isSensitive {
                    Button {
                        onToggleVisibility()
                    } label: {
                        Image(systemName: isVisible ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                    .help(isVisible ? "Hide" : "Reveal")
                }

                Button {
                    onCopy()
                } label: {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(isCopied ? .green : .primary)
                .help("Copy (auto-clears in 30s)")
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
