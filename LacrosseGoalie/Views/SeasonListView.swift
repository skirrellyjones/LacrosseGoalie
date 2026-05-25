import SwiftUI

struct SeasonListView: View {
    @EnvironmentObject var store: DataStore
    @State private var showingNewSeason = false
    @State private var newSeasonName = ""

    var sortedSeasons: [Season] {
        store.seasons.sorted { $0.createdDate > $1.createdDate }
    }

    var body: some View {
        Group {
            if store.seasons.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 52))
                        .foregroundColor(.secondary)
                    Text("No Seasons Yet")
                        .font(.title2.bold())
                    Text("Seasons are created when you save a completed game.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                }
            } else {
                List {
                    ForEach(sortedSeasons) { season in
                        NavigationLink {
                            SeasonDetailView(season: season)
                        } label: {
                            SeasonRowView(season: season)
                        }
                    }
                    .onDelete { offsets in
                        // Map sorted offsets back to store indices
                        let ids = offsets.map { sortedSeasons[$0].id }
                        store.seasons.removeAll { ids.contains($0.id) }
                        store.save()
                    }
                }
            }
        }
        .navigationTitle("My Seasons")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewSeason = true
                } label: {
                    Label("New Season", systemImage: "plus")
                }
            }
            if !store.seasons.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
        }
        .sheet(isPresented: $showingNewSeason) {
            NewSeasonSheet { name in
                store.addSeason(Season(name: name))
                showingNewSeason = false
            }
        }
    }
}

// MARK: - Season Row

struct SeasonRowView: View {
    let season: Season

    var body: some View {
        HStack(spacing: 14) {
            // Save % ring
            ZStack {
                Circle()
                    .stroke(pctColor(season.savePercentage).opacity(0.2), lineWidth: 4)
                    .frame(width: 52, height: 52)
                Circle()
                    .trim(from: 0, to: CGFloat(min(season.savePercentage / 100, 1)))
                    .stroke(pctColor(season.savePercentage), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                Text(season.games.isEmpty ? "–" : String(format: "%.0f%%", season.savePercentage))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(pctColor(season.savePercentage))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(season.name)
                    .font(.headline)
                Text("\(season.games.count) game\(season.games.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if !season.games.isEmpty {
                    Text("\(season.totalSaves)S · \(season.totalGoalsAgainst)GA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func pctColor(_ pct: Double) -> Color {
        if pct >= 60 { return .green }
        if pct >= 45 { return .orange }
        return .red
    }
}

// MARK: - New Season Sheet

struct NewSeasonSheet: View {
    @Environment(\.dismiss) var dismiss
    var onCreate: (String) -> Void
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. Fall 2025, JV 2025-26", text: $name)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Season Name")
                }

                Section {
                    Button("Create Season") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        onCreate(trimmed)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.green)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("New Season")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
