import Foundation
import SwiftUI
import Combine

/// Manages all game data and persists it to a JSON file in the app's Documents folder.
class DataStore: ObservableObject {

    @Published var games: [Game] = []

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
        didSet { UserDefaults.standard.set(darkModeEnabled, forKey: "darkModeEnabled") }
    }

    private let saveURL: URL

    init() {
        historyEnabled = UserDefaults.standard.bool(forKey: "historyEnabled")
        // Shot location defaults to ON
        shotLocationEnabled = UserDefaults.standard.object(forKey: "shotLocationEnabled") as? Bool ?? true
        darkModeEnabled = UserDefaults.standard.bool(forKey: "darkModeEnabled")

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        saveURL = docs.appendingPathComponent("games.json")

        load()
    }

    // MARK: - Persistence

    func save() {
        do {
            let data = try JSONEncoder().encode(games)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            print("Failed to save games: \(error)")
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let loaded = try? JSONDecoder().decode([Game].self, from: data)
        else { return }
        games = loaded
    }

    // MARK: - CRUD

    func addGame(_ game: Game) {
        games.append(game)
        if historyEnabled { save() }
    }

    func deleteGame(at offsets: IndexSet) {
        games.remove(atOffsets: offsets)
        save()
    }

    func clearAllHistory() {
        games = []
        save()
    }

    // MARK: - Season Aggregates

    var seasonSaves: Int           { games.reduce(0) { $0 + $1.totalSaves } }
    var seasonGoalsAgainst: Int    { games.reduce(0) { $0 + $1.totalGoalsAgainst } }
    var seasonShots: Int           { games.reduce(0) { $0 + $1.totalShots } }
    var seasonGroundBalls: Int     { games.reduce(0) { $0 + $1.groundBalls } }
    var seasonInterceptions: Int   { games.reduce(0) { $0 + $1.interceptions } }
    var seasonClearAttempts: Int   { games.reduce(0) { $0 + $1.clearAttempts } }
    var seasonSuccessfulClears: Int { games.reduce(0) { $0 + $1.successfulClears } }

    var seasonSavePct: Double {
        guard seasonShots > 0 else { return 0 }
        return Double(seasonSaves) / Double(seasonShots) * 100
    }

    var seasonClearPct: Double {
        guard seasonClearAttempts > 0 else { return 0 }
        return Double(seasonSuccessfulClears) / Double(seasonClearAttempts) * 100
    }
}
