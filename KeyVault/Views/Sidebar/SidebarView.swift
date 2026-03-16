import SwiftUI
import SwiftData

enum SidebarFilter: Hashable {
    case all
    case provider(String)
    case tag(String)
    case type(EntryType)
    case expiringSoon
    case expired
}

struct SidebarView: View {
    @Query(sort: \Entry.name) private var entries: [Entry]
    @Binding var selection: SidebarFilter
    @Binding var searchText: String

    var body: some View {
        List(selection: $selection) {
            Section("Library") {
                Label("All Entries", systemImage: "tray.full.fill")
                    .tag(SidebarFilter.all)
                    .badge(entries.count)

                Label("Expiring Soon", systemImage: "exclamationmark.triangle.fill")
                    .tag(SidebarFilter.expiringSoon)
                    .badge(entries.filter(\.isExpiringSoon).count)
                    .foregroundStyle(entries.contains(where: \.isExpiringSoon) ? .orange : .secondary)

                Label("Expired", systemImage: "xmark.circle.fill")
                    .tag(SidebarFilter.expired)
                    .badge(entries.filter(\.isExpired).count)
                    .foregroundStyle(entries.contains(where: \.isExpired) ? .red : .secondary)
            }

            if !uniqueTypes.isEmpty {
                Section("Types") {
                    ForEach(uniqueTypes, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(SidebarFilter.type(type))
                            .badge(entries.filter { $0.type == type }.count)
                    }
                }
            }

            if !uniqueProviders.isEmpty {
                Section("Providers") {
                    ForEach(uniqueProviders, id: \.self) { provider in
                        Label(provider, systemImage: "building.2.fill")
                            .tag(SidebarFilter.provider(provider))
                            .badge(entries.filter { $0.provider == provider }.count)
                    }
                }
            }

            if !uniqueTags.isEmpty {
                Section("Tags") {
                    ForEach(uniqueTags, id: \.self) { tag in
                        Label(tag, systemImage: "tag.fill")
                            .tag(SidebarFilter.tag(tag))
                            .badge(entries.filter { $0.tags.contains(tag) }.count)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchText, prompt: "Search entries...")
    }

    private var uniqueProviders: [String] {
        Array(Set(entries.map(\.provider))).sorted()
    }

    private var uniqueTags: [String] {
        Array(Set(entries.flatMap(\.tags))).sorted()
    }

    private var uniqueTypes: [EntryType] {
        Array(Set(entries.map(\.type))).sorted { $0.rawValue < $1.rawValue }
    }
}
