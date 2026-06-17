import SwiftUI
import UIKit

struct GameSummaryView: View {
    let game: Game

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Header
                VStack(spacing: 4) {
                    Text("vs \(game.opponent)")
                        .font(.title2.bold())
                    Text(game.formattedDate)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%  Save Percentage", game.savePercentage))
                        .font(.title3.bold())
                        .foregroundColor(savePctColor(game.savePercentage))
                }
                .padding(.top)

                // Overall stats card
                statsCard("Overall") {
                    StatRow("Saves",          "\(game.totalSaves)")
                    StatRow("Goals Against",  "\(game.totalGoalsAgainst)")
                    StatRow("Save %",         String(format: "%.1f%%", game.savePercentage))
                    StatRow("Ground Balls",   "\(game.groundBalls)")
                    StatRow("Interceptions",  "\(game.interceptions)")
                    StatRow("Clear %",        String(format: "%.1f%%  (\(game.successfulClears)/\(game.clearAttempts))", game.clearPercentage))
                }

                // Per-half breakdown — only shown when 2nd-half shots exist
                if game.shots.contains(where: { $0.half == 2 }) {
                    statsCard("1st Half") {
                        StatRow("Saves",    "\(game.saves(half: 1))")
                        StatRow("Goals",    "\(game.goalsAgainst(half: 1))")
                        StatRow("Save %",   String(format: "%.1f%%", game.savePct(half: 1)))
                    }
                    statsCard("2nd Half") {
                        StatRow("Saves",    "\(game.saves(half: 2))")
                        StatRow("Goals",    "\(game.goalsAgainst(half: 2))")
                        StatRow("Save %",   String(format: "%.1f%%", game.savePct(half: 2)))
                    }
                }

                // Shot placement heatmap — only shown when zone data exists
                if game.shots.contains(where: { $0.zone != nil }) {
                    GroupBox {
                        VStack(spacing: 10) {
                            MiniCageView(game: game)

                            HStack(spacing: 20) {
                                Label("Saves", systemImage: "circle.fill").foregroundColor(.green)
                                Label("Goals", systemImage: "circle.fill").foregroundColor(.red)
                            }
                            .font(.caption)
                        }
                    } label: {
                        Text("Shot Placement").font(.headline)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Game Summary")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    shareSummary()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    private func shareSummary() {
        var lines = ["vs \(game.opponent) | \(game.formattedDate)"]
        lines.append(String(format: "Save %%: %.1f%% (%d saves, %d goals)", game.savePercentage, game.totalSaves, game.totalGoalsAgainst))
        if game.clearAttempts > 0 {
            lines.append(String(format: "Clear %%: %.0f%% (%d/%d)", game.clearPercentage, game.successfulClears, game.clearAttempts))
        }
        lines.append("Ground Balls: \(game.groundBalls) | Interceptions: \(game.interceptions)")
        if game.shots.contains(where: { $0.half == 2 }) {
            lines.append(String(format: "1st Half: %dS %dGA (%.1f%%) | 2nd Half: %dS %dGA (%.1f%%)",
                game.saves(half: 1), game.goalsAgainst(half: 1), game.savePct(half: 1),
                game.saves(half: 2), game.goalsAgainst(half: 2), game.savePct(half: 2)))
        }
        let text = lines.joined(separator: "\n")
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else { return }
        var top = root
        while let next = top.presentedViewController { top = next }
        top.present(av, animated: true)
    }

    @ViewBuilder
    private func statsCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        GroupBox {
            content()
        } label: {
            Text(title).font(.headline)
        }
    }

    private func savePctColor(_ pct: Double) -> Color {
        if pct >= 60 { return .green }
        if pct >= 45 { return .orange }
        return .red
    }
}

// MARK: - Shared Stat Row

struct StatRow: View {
    let label: String
    let value: String

    init(_ label: String, _ value: String) {
        self.label = label
        self.value = value
    }

    var body: some View {
        HStack {
            Text(label).foregroundColor(.primary)
            Spacer()
            Text(value).bold()
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Mini Read-Only Cage (used in summary + season stats)

struct MiniCageView: View {
    let game: Game

    private let rows: [[CageZone]] = [
        [.topLeft, .topCenter, .topRight],
        [.midLeft, .midCenter, .midRight],
        [.botLeft, .botCenter, .botRight]
    ]

    var body: some View {
        VStack(spacing: 2) {
            ForEach(rows.indices, id: \.self) { rowIdx in
                HStack(spacing: 2) {
                    ForEach(rows[rowIdx], id: \.self) { zone in
                        let saves = game.shotCount(zone: zone, outcome: .save)
                        let goals = game.shotCount(zone: zone, outcome: .goal)
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(miniCellColor(saves: saves, goals: goals))
                                .frame(height: 48)
                            VStack(spacing: 2) {
                                Text(zone.label)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                if saves + goals > 0 {
                                    Text("\(saves)S \(goals)G")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func miniCellColor(saves: Int, goals: Int) -> Color {
        let total = saves + goals
        if total == 0 { return Color.gray.opacity(0.3) }
        if goals > saves  { return .red.opacity(0.7) }
        if saves > goals  { return .green.opacity(0.65) }
        return .yellow.opacity(0.6)
    }
}
