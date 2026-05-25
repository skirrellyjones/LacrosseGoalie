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
                } header: {
                    Text("Shot Tracking")
                } footer: {
                    Text(store.shotLocationEnabled
                        ? "The goal cage grid is shown during games. Tap a zone to log where the shot went."
                        : "Shot location is not tracked. Use the Save / Goal buttons to log shots quickly.")
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
                if store.historyEnabled && !store.games.isEmpty {
                    Section {
                        Button("Clear All Game History", role: .destructive) {
                            showingClearConfirm = true
                        }
                    } header: {
                        Text("Danger Zone")
                    } footer: {
                        Text("This permanently deletes all \(store.games.count) saved game(s). Cannot be undone.")
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
                "Clear all \(store.games.count) game(s)?",
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
