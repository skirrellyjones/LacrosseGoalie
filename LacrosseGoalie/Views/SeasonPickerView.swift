import SwiftUI

/// Shown after a game ends so the user can assign it to a season.
struct SeasonPickerView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss

    let game: Game
    var onDone: () -> Void

    @State private var showingNewSeason = false
    @State private var newSeasonName = ""

    var body: some View {
        NavigationStack {
            List {
                // Existing seasons — newest first
                if !store.seasons.isEmpty {
                    Section("Save to existing season") {
                        ForEach(store.seasons.sorted { $0.createdDate > $1.createdDate }) { season in
                            Button {
                                store.addGame(game, toSeasonId: season.id)
                                onDone()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(season.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("\(season.games.count) game\(season.games.count == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }

                // Create new season
                Section {
                    if showingNewSeason {
                        VStack(spacing: 12) {
                            TextField("Season name (e.g. Fall 2025)", text: $newSeasonName)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()

                            Button {
                                let name = newSeasonName.trimmingCharacters(in: .whitespaces)
                                guard !name.isEmpty else { return }
                                var season = Season(name: name)
                                season.games.append(game)
                                store.addSeason(season)
                                onDone()
                            } label: {
                                Text("Create & Save Game")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding(10)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .disabled(newSeasonName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Button {
                            showingNewSeason = true
                        } label: {
                            Label("New Season…", systemImage: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                } header: {
                    Text("Or create a new season")
                }
            }
            .navigationTitle("Save Game To Season")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { onDone() }
                }
            }
        }
    }
}
