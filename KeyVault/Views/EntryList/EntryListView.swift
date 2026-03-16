import SwiftUI
import SwiftData

struct EntryListView: View {
    let filter: SidebarFilter
    let searchText: String
    @Binding var selectedEntry: Entry?
    @Query(sort: \Entry.name) private var allEntries: [Entry]

    var body: some View {
        List(selection: $selectedEntry) {
            ForEach(filteredEntries) { entry in
                EntryRow(entry: entry)
                    .tag(entry)
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .overlay {
            if filteredEntries.isEmpty {
                ContentUnavailableView {
                    Label("No Entries", systemImage: "key.slash")
                } description: {
                    Text(searchText.isEmpty
                         ? "Add your first API key with ⌘N"
                         : "No entries match your search")
                }
            }
        }
    }

    private var filteredEntries: [Entry] {
        var result = allEntries

        // Apply sidebar filter
        switch filter {
        case .all:
            break
        case .provider(let provider):
            result = result.filter { $0.provider == provider }
        case .tag(let tag):
            result = result.filter { $0.tags.contains(tag) }
        case .type(let type):
            result = result.filter { $0.type == type }
        case .expiringSoon:
            result = result.filter(\.isExpiringSoon)
        case .expired:
            result = result.filter(\.isExpired)
        }

        // Apply search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.provider.lowercased().contains(query) ||
                $0.tags.contains(where: { $0.lowercased().contains(query) }) ||
                $0.notes.lowercased().contains(query)
            }
        }

        return result
    }
}

struct EntryRow: View {
    let entry: Entry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.type.icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(entry.provider)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(entry.type.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(.quaternary)
                        .clipShape(Capsule())
                }
            }

            Spacer()

            if !entry.agentAccess.isEmpty {
                HStack(spacing: 2) {
                    Image(systemName: "cpu")
                        .font(.caption2)
                    Text("\(entry.agentAccess.count)")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }

            expiryBadge
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var expiryBadge: some View {
        switch entry.expiryStatus {
        case .expired:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .help("Expired")
        case .expiringSoon:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .help("Expiring \(entry.expiresAt?.relativeDisplay ?? "")")
        case .active:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .help("Expires \(entry.expiresAt?.shortDisplay ?? "")")
        case .noExpiry:
            EmptyView()
        }
    }
}
