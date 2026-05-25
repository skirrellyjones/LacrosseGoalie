import SwiftUI

struct SeasonStatsView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Season totals card
                GroupBox {
                    StatRow("Games Played",  "\(store.games.count)")
                    StatRow("Total Saves",   "\(store.seasonSaves)")
                    StatRow("Goals Against", "\(store.seasonGoalsAgainst)")
                    StatRow("Save %",        String(format: "%.1f%%", store.seasonSavePct))
                    StatRow("Ground Balls",  "\(store.seasonGroundBalls)")
                    StatRow("Clear %",       String(format: "%.1f%%", store.seasonClearPct))
                } label: {
                    Text("Season Totals").font(.headline)
                }

                // Save % per game bar chart
                if store.games.count > 1 {
                    GroupBox {
                        SavePctChart(games: store.games.sorted { $0.date < $1.date })
                    } label: {
                        Text("Save % by Game").font(.headline)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Season Stats")
    }
}

// MARK: - Save % Bar Chart

struct SavePctChart: View {
    let games: [Game]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(games) { game in
                HStack(spacing: 8) {
                    // Opponent label
                    Text(game.opponent)
                        .font(.caption)
                        .lineLimit(1)
                        .frame(width: 72, alignment: .leading)

                    // Bar
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

                    // Value
                    Text(String(format: "%.0f%%", game.savePercentage))
                        .font(.caption.bold())
                        .foregroundColor(barColor(pct: game.savePercentage))
                        .frame(width: 38, alignment: .trailing)
                }
            }

            // Reference line at 60% (a solid benchmark for lacrosse goalies)
            HStack(spacing: 8) {
                Text("60% goal")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 72, alignment: .leading)
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.green.opacity(0.5))
                        .frame(width: 1, height: 22)
                        .offset(x: geo.size.width * 0.6)
                }
                .frame(height: 22)
                Spacer().frame(width: 38)
            }
        }
    }

    private func barColor(pct: Double) -> Color {
        if pct >= 60 { return .green }
        if pct >= 45 { return .orange }
        return .red
    }
}
