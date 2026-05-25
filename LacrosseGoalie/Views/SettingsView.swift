import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss

    @State private var showingClearConfirm = false

    var body: some View {
        NavigationStack {
            Form {

                // History toggle
                Section {
                    Toggle("Dark Mode", isOn: $store.darkModeEnabled)
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Override your system theme and force dark mode across the app.")
                }

                Section {
                    Toggle("Track Shot Location", isOn: $store.shotLocationEnabled)
                    if !store.shotLocationEnabled {
                        Toggle("Express Mode", isOn: $store.expressModeEnabled)
                    }
                } header: {
                    Text("Shot Tracking")
                } footer: {
                    if store.shotLocationEnabled {
                        Text("The goal cage grid is shown during games. Tap a zone to log where the shot went.")
                    } else if store.expressModeEnabled {
                        Text("Tap Save or Goal Against to log a shot instantly — no prompt, no shot type.")
                    } else {
                        Text("Shot location is not tracked. Tap Save or Goal Against to log shots.")
                    }
                }

                Section {
                    Toggle("Track Season History", isOn: $store.historyEnabled)
                } header: {
                    Text("History")
                } footer: {
                    Text(store.historyEnabled
                        ? "Games are saved after completion. View season-wide stats from the Home screen."
                        : "Game data is discarded after each game. Turn this on to track your season.")
                }

                // Danger zone — only visible when history is on and there's data
                if store.historyEnabled && !store.seasons.isEmpty {
                    Section {
                        Button("Clear All Season History", role: .destructive) {
                            showingClearConfirm = true
                        }
                    } header: {
                        Text("Danger Zone")
                    } footer: {
                        let gameCount = store.seasons.reduce(0) { $0 + $1.games.count }
                        Text("This permanently deletes all \(store.seasons.count) season(s) and \(gameCount) game(s). Cannot be undone.")
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Sport")
                        Spacer()
                        Text("Women's Lacrosse").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Clear all \(store.seasons.count) season(s)?",
                isPresented: $showingClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Clear History", role: .destructive) {
                    store.clearAllHistory()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
        }
    }
}
