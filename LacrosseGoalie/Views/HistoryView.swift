import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: DataStore

    var sortedGames: [Game] {
        store.games.sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if store.games.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "list.bullet.rectangle.portrait")
                        .font(.system(size: 52))
                        .foregroundColor(.secondary)
                    Text("No Games Yet")
                        .font(.title2.bold())
                    Text("Complete a game to see it here.")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(sortedGames) { game in
                        NavigationLink {
                            GameSummaryView(game: game)
                        } label: {
                            GameRowView(game: game)
                        }
                    }
                    .onDelete { offsets in
                        // Convert sorted offsets back to store indices
                        let idsToDelete = offsets.map { sortedGames[$0].id }
                        store.games.removeAll { idsToDelete.contains($0.id) }
                        store.save()
                    }
                }
            }
        }
        .navigationTitle("Game History")
        .toolbar {
            if !store.games.isEmpty {
                EditButton()
            }
        }
    }
}

// MARK: - Game Row

struct GameRowView: View {
    let game: Game

    var body: some View {
        HStack(spacing: 12) {
            // Save % circle
            ZStack {
                Circle()
                    .stroke(savePctColor(game.savePercentage).opacity(0.25), lineWidth: 4)
                    .frame(width: 52, height: 52)
                Circle()
                    .trim(from: 0, to: CGFloat(game.savePercentage / 100))
                    .stroke(savePctColor(game.savePercentage), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                Text(String(format: "%.0f%%", game.savePercentage))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(savePctColor(game.savePercentage))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("vs \(game.opponent)")
                    .font(.headline)
                    .lineLimit(1)
                Text(game.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(game.totalSaves) saves · \(game.totalGoalsAgainst) goals against")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func savePctColor(_ pct: Double) -> Color {
        if pct >= 60 { return .green }
        if pct >= 45 { return .orange }
        return .red
    }
}
