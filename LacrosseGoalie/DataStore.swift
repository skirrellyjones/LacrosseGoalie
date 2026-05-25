import Foundation
import SwiftUI
import Combine
import UIKit

/// Manages all game data and persists it to a JSON file in the app's Documents folder.
@MainActor
class DataStore: ObservableObject {

    @Published var seasons: [Season] = []

    /// Whether to save and show game history. Persisted via UserDefaults.
    @Published var historyEnabled: Bool {
        didSet { UserDefaults.standard.set(historyEnabled, forKey: "historyEnabled") }
    }

    /// Whether to show the cage grid and track shot placement. Persisted via UserDefaults.
    @Published var shotLocationEnabled: Bool {
        didSet { UserDefaults.standard.set(shotLocationEnabled, forKey: "shotLocationEnabled") }
    }

    /// Whether to force dark mode regardless of system setting. Persisted via UserDefaults.
    @Published var darkModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(darkModeEnabled, forKey: "darkModeEnabled")
            applyColorScheme()
        }
    }

    private let saveURL: URL

    init() {
        historyEnabled = UserDefaults.standard.bool(forKey: "historyEnabled")
        shotLocationEnabled = UserDefaults.standard.object(forKey: "shotLocationEnabled") as? Bool ?? true
        darkModeEnabled = UserDefaults.standard.bool(forKey: "darkModeEnabled")

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        saveURL = docs.appendingPathComponent("seasons.json")

        load()
        applyColorScheme()
    }

    // MARK: - Color Scheme

    /// Sets overrideUserInterfaceStyle on every window so dark mode applies
    /// instantly across sheets and full-screen covers, not just the root view.
    func applyColorScheme() {
        let style: UIUserInterfaceStyle = darkModeEnabled ? .dark : .unspecified
        for scene in UIApplication.shared.connectedScenes {
            guard let ws = scene as? UIWindowScene else { continue }
            for window in ws.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
    }

    // MARK: - Persistence

    func save() {
        do {
            let data = try JSONEncoder().encode(seasons)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            print("Failed to save seasons: \(error)")
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let loaded = try? JSONDecoder().decode([Season].self, from: data)
        else { return }
        seasons = loaded
    }

    // MARK: - Season CRUD

    func addSeason(_ season: Season) {
        seasons.append(season)
        if historyEnabled { save() }
    }

    func deleteSeason(at offsets: IndexSet) {
        seasons.remove(atOffsets: offsets)
        save()
    }

    func clearAllHistory() {
        seasons = []
        save()
    }

    // MARK: - Game CRUD

    func addGame(_ game: Game, toSeasonId id: UUID) {
        guard let idx = seasons.firstIndex(where: { $0.id == id }) else { return }
        seasons[idx].games.append(game)
        if historyEnabled { save() }
    }

    func deleteGame(id gameId: UUID, fromSeasonId seasonId: UUID) {
        guard let sIdx = seasons.firstIndex(where: { $0.id == seasonId }) else { return }
        seasons[sIdx].games.removeAll { $0.id == gameId }
        save()
    }

    // MARK: - CSV Export

    func exportCSV(for season: Season) -> String {
        let zones = CageZone.allCases
        let zoneHeaders = zones.flatMap { ["\($0.label)-Saves", "\($0.label)-Goals"] }

        let header = (["Date", "Opponent", "Saves", "Goals Against", "Save%",
                        "Ground Balls", "Interceptions",
                        "Clear Attempts", "Successful Clears", "Clear%"] + zoneHeaders)
            .joined(separator: ",")

        var rows: [String] = [header]

        for game in season.games.sorted(by: { $0.date < $1.date }) {
            let zoneCols = zones.flatMap { zone in
                ["\(game.shotCount(zone: zone, outcome: .save))",
                 "\(game.shotCount(zone: zone, outcome: .goal))"]
            }
            let row = ([
                "\"\(game.formattedDate)\"",
                "\"\(game.opponent)\"",
                "\(game.totalSaves)",
                "\(game.totalGoalsAgainst)",
                String(format: "%.1f", game.savePercentage),
                "\(game.groundBalls)",
                "\(game.interceptions)",
                "\(game.clearAttempts)",
                "\(game.successfulClears)",
                String(format: "%.1f", game.clearPercentage)
            ] + zoneCols).joined(separator: ",")
            rows.append(row)
        }

        // Season totals row
        let totalZoneCols = zones.flatMap { zone -> [String] in
            let saves = season.games.reduce(0) { $0 + $1.shotCount(zone: zone, outcome: .save) }
            let goals = season.games.reduce(0) { $0 + $1.shotCount(zone: zone, outcome: .goal) }
            return ["\(saves)", "\(goals)"]
        }
        let totals = ([
            "\"SEASON TOTAL\"",
            "\"\(season.name)\"",
            "\(season.totalSaves)",
            "\(season.totalGoalsAgainst)",
            String(format: "%.1f", season.savePercentage),
            "\(season.totalGroundBalls)",
            "\(season.totalInterceptions)",
            "\(season.totalClearAttempts)",
            "\(season.totalSuccessfulClears)",
            String(format: "%.1f", season.clearPercentage)
        ] + totalZoneCols).joined(separator: ",")
        rows.append(totals)

        return rows.joined(separator: "\n")
    }
}
