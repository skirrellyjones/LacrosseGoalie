import Foundation

// MARK: - Enums

enum CageZone: String, CaseIterable, Codable, Hashable {
    case topLeft = "TL", topCenter = "TC", topRight = "TR"
    case midLeft = "ML", midCenter = "MC", midRight = "MR"
    case botLeft = "BL", botCenter = "BC", botRight = "BR"

    var label: String { rawValue }

    var row: Int {
        switch self {
        case .topLeft, .topCenter, .topRight: return 0
        case .midLeft, .midCenter, .midRight: return 1
        case .botLeft, .botCenter, .botRight: return 2
        }
    }

    var col: Int {
        switch self {
        case .topLeft, .midLeft, .botLeft: return 0
        case .topCenter, .midCenter, .botCenter: return 1
        case .topRight, .midRight, .botRight: return 2
        }
    }
}

enum ShotOutcome: String, CaseIterable, Codable {
    case save = "Save"
    case goal = "Goal Against"
}

enum ShotType: String, CaseIterable, Codable {
    case eightMeter = "8-Meter Arc"
    case insideCrease = "Inside / Near Crease"
    case outside = "Outside / Far Shot"
}

// MARK: - Models

struct Shot: Identifiable, Codable {
    var id = UUID()
    var timestamp = Date()
    var zone: CageZone?   // nil when shot-location tracking is turned off
    var outcome: ShotOutcome
    var type: ShotType
    var half: Int
}

struct Clear: Identifiable, Codable {
    var id = UUID()
    var wasSuccessful: Bool
    var half: Int
}

struct Game: Identifiable, Codable {
    var id = UUID()
    var date = Date()
    var opponent: String
    var currentHalf: Int = 1
    var shots: [Shot] = []
    var clears: [Clear] = []
    var groundBalls: Int = 0
    var isCompleted: Bool = false

    // MARK: - Overall Stats

    var totalSaves: Int { shots.filter { $0.outcome == .save }.count }
    var totalGoalsAgainst: Int { shots.filter { $0.outcome == .goal }.count }
    var totalShots: Int { shots.count }

    var savePercentage: Double {
        guard totalShots > 0 else { return 0 }
        return Double(totalSaves) / Double(totalShots) * 100
    }

    var clearAttempts: Int { clears.count }
    var successfulClears: Int { clears.filter { $0.wasSuccessful }.count }
    var clearPercentage: Double {
        guard clearAttempts > 0 else { return 0 }
        return Double(successfulClears) / Double(clearAttempts) * 100
    }

    // MARK: - Per-Half Stats

    func saves(half: Int) -> Int {
        shots.filter { $0.half == half && $0.outcome == .save }.count
    }

    func goalsAgainst(half: Int) -> Int {
        shots.filter { $0.half == half && $0.outcome == .goal }.count
    }

    func savePct(half: Int) -> Double {
        let halfShots = shots.filter { $0.half == half }
        guard !halfShots.isEmpty else { return 0 }
        return Double(halfShots.filter { $0.outcome == .save }.count) / Double(halfShots.count) * 100
    }

    // MARK: - Zone Stats (for heatmap)

    func shotCount(zone: CageZone, outcome: ShotOutcome? = nil) -> Int {
        shots.filter { s in
            s.zone == zone && (outcome == nil || s.outcome == outcome)
        }.count
    }

    // MARK: - Formatting

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}
