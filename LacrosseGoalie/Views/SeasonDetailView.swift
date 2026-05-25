import SwiftUI
import UIKit

struct SeasonDetailView: View {
    @EnvironmentObject var store: DataStore
    let season: Season

    /// Live copy from store so UI updates after games are deleted
    var liveSeason: Season {
        store.seasons.first { $0.id == season.id } ?? season
    }

    var sortedGames: [Game] {
        liveSeason.games.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Stats Card
                GroupBox {
                    StatRow("Games Played",   "\(liveSeason.games.count)")
                    StatRow("Saves",          "\(liveSeason.totalSaves)")
                    StatRow("Goals Against",  "\(liveSeason.totalGoalsAgainst)")
                    StatRow("Save %",         String(format: "%.1f%%", liveSeason.savePercentage))
                    StatRow("Ground Balls",   "\(liveSeason.totalGroundBalls)")
                    StatRow("Interceptions",  "\(liveSeason.totalInterceptions)")
                    StatRow("Clear %",        String(format: "%.1f%%  (\(liveSeason.totalSuccessfulClears)/\(liveSeason.totalClearAttempts))", liveSeason.clearPercentage))
                } label: {
                    Text("Season Stats").font(.headline)
                }

                // Save % bar chart
                if liveSeason.games.count > 1 {
                    GroupBox {
                        SavePctChart(games: sortedGames.reversed())
                    } label: {
                        Text("Save % by Game").font(.headline)
                    }
                }

                // Game list
                if !liveSeason.games.isEmpty {
                    GroupBox {
                        VStack(spacing: 0) {
                            ForEach(sortedGames) { game in
                                NavigationLink {
                                    GameSummaryView(game: game)
                                } label: {
                                    GameRowView(game: game)
                                }
                                if game.id != sortedGames.last?.id {
                                    Divider()
                                }
                            }
                        }
                    } label: {
                        Text("Games").font(.headline)
                    }
                } else {
                    Text("No games yet in this season.")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle(liveSeason.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    exportCSV()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(liveSeason.games.isEmpty)
            }
        }
    }

    private func exportCSV() {
        let csv = store.exportCSV(for: liveSeason)
        let fileName = "\(liveSeason.name.replacingOccurrences(of: " ", with: "_")).csv"
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? csv.write(to: tmp, atomically: true, encoding: .utf8)

        let av = UIActivityViewController(activityItems: [tmp], applicationActivities: nil)

        // Walk up to the topmost presented view controller so the share sheet
        // is presented correctly even when inside a NavigationStack.
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else { return }
        var top = root
        while let next = top.presentedViewController { top = next }
        top.present(av, animated: true)
    }
}

// MARK: - Save % Bar Chart (moved from SeasonStatsView)

struct SavePctChart: View {
    let games: [Game]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(games) { game in
                HStack(spacing: 8) {
                    Text(game.opponent)
                        .font(.caption)
                        .lineLimit(1)
                        .frame(width: 72, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.gray.opacity(0.15))
                            RoundedRectangle(cornerRadius: 5)
                                .fill(barColor(pct: game.savePercentage))
                                .frame(width: max(4, geo.size.width * CGFloat(game.savePercentage / 100)))
                        }
                    }
                    .frame(height: 22)

                    Text(String(format: "%.0f%%", game.savePercentage))
                        .font(.caption.bold())
                        .foregroundColor(barColor(pct: game.savePercentage))
                        .frame(width: 38, alignment: .trailing)
                }
            }
        }
    }

    private func barColor(pct: Double) -> Color {
        if pct >= 60 { return .green }
        if pct >= 45 { return .orange }
        return .red
    }
}

// MARK: - Game Row (moved from HistoryView)

struct GameRowView: View {
    let game: Game

    var body: some View {
        HStack(spacing: 12) {
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
        .padding(.vertical, 6)
    }

    private func savePctColor(_ pct: Double) -> Color {
        if pct >= 60 { return .green }
        if pct >= 45 { return .orange }
        return .red
    }
}
