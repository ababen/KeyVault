import SwiftUI
import SwiftData

/// Sheet for adding agent access to an entry.
struct AddAgentAccessView: View {
    let entry: Entry
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Agent.name) private var agents: [Agent]

    @State private var agentName = ""
    @State private var permission: AgentPermission = .read
    @State private var showNewAgent = false

    private var existingAgentNames: Set<String> {
        Set(entry.agentAccess.map(\.agentName))
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Grant Agent Access")
                .font(.headline)

            if agents.isEmpty {
                Text("No agents registered yet. Enter an agent name below.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TextField("Agent Name", text: $agentName)
                .textFieldStyle(.roundedBorder)

            if !agents.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Or select an existing agent:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(agents.filter { !existingAgentNames.contains($0.name) }) { agent in
                        Button {
                            agentName = agent.name
                        } label: {
                            HStack {
                                Image(systemName: "cpu")
                                Text(agent.name)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            Picker("Permission", selection: $permission) {
                ForEach(AgentPermission.allCases, id: \.self) { perm in
                    Text(perm.rawValue).tag(perm)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Grant Access") {
                    grantAccess()
                }
                .buttonStyle(.borderedProminent)
                .disabled(agentName.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.return)
            }
        }
        .padding(20)
        .frame(width: 360)
    }

    private func grantAccess() {
        guard let key = appState.encryptionKey else { return }
        let service = VaultService(modelContext: modelContext, key: key)
        try? service.grantAccess(to: entry, agentName: agentName.trimmingCharacters(in: .whitespaces), permission: permission)

        // Auto-register the agent if it's new
        if !agents.contains(where: { $0.name == agentName }) {
            let agent = Agent(name: agentName.trimmingCharacters(in: .whitespaces))
            modelContext.insert(agent)
            try? modelContext.save()
        }

        dismiss()
    }
}
