import SwiftUI
import SwiftData

/// Main three-column layout: Sidebar | Entry List | Entry Detail
struct MainView: View {
    @EnvironmentObject private var appState: AppState
    @State private var sidebarFilter: SidebarFilter = .all
    @State private var selectedEntry: Entry?
    @State private var searchText = ""
    @State private var showNewEntry = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $sidebarFilter, searchText: $searchText)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } content: {
            EntryListView(
                filter: sidebarFilter,
                searchText: searchText,
                selectedEntry: $selectedEntry
            )
            .navigationSplitViewColumnWidth(min: 250, ideal: 320, max: 450)
        } detail: {
            if let selectedEntry {
                EntryDetailView(entry: selectedEntry)
            } else {
                ContentUnavailableView {
                    Label("Select an Entry", systemImage: "key")
                } description: {
                    Text("Choose an entry from the list or create a new one with ⌘N")
                }
            }
        }
        .sheet(isPresented: $showNewEntry) {
            EntryEditorView()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewEntry = true
                } label: {
                    Label("New Entry", systemImage: "plus")
                }
                .keyboardShortcut("n")
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    appState.lock()
                } label: {
                    Label("Lock", systemImage: "lock.fill")
                }
                .help("Lock Vault (⇧⌘L)")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newEntry)) { _ in
            showNewEntry = true
        }
        .onAppear {
            appState.autoLock.resetTimer()
        }
    }
}
