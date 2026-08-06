import SwiftUI

/// The interactive 3×3 goal cage grid. Tap any zone to log a shot there.
struct CageGridView: View {
    let game: Game
    var onTap: (CageZone) -> Void

    // Zones laid out as 3 rows of 3
    private let rows: [[CageZone]] = [
        [.topLeft, .topCenter, .topRight],
        [.midLeft, .midCenter, .midRight],
        [.botLeft, .botCenter, .botRight]
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Top crossbar + posts frame
            HStack(alignment: .top, spacing: 0) {
                // Left post
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 8)

                VStack(spacing: 0) {
                    // Crossbar
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: 8)

                    // Zone grid
                    ForEach(rows.indices, id: \.self) { rowIdx in
                        HStack(spacing: 0) {
                            ForEach(rows[rowIdx], id: \.self) { zone in
                                CageZoneCell(
                                    zone: zone,
                                    saves: game.shotCount(zone: zone, outcome: .save),
                                    goals: game.shotCount(zone: zone, outcome: .goal),
                                    onTap: { onTap(zone) }
                                )
                            }
                        }
                    }
                }

                // Right post
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 8)
            }
            .background(Color(red: 0.05, green: 0.28, blue: 0.05)) // deep field green
            .cornerRadius(4)

            // Ground line
            Rectangle()
                .fill(Color(red: 0.4, green: 0.28, blue: 0.1).opacity(0.7))
                .frame(height: 6)
                .cornerRadius(2)
        }
        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Individual Zone Cell

struct CageZoneCell: View {
    let zone: CageZone
    let saves: Int
    let goals: Int
    let onTap: () -> Void

    private var total: Int { saves + goals }

    /// Color the zone based on what happened there: green = mostly saves, red = mostly goals
    private var fill: Color {
        guard total > 0 else { return Color.white.opacity(0.08) }
        if goals > saves { return Color.red.opacity(0.55) }
        if saves > goals { return Color.green.opacity(0.45) }
        return Color.yellow.opacity(0.45)
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Rectangle()
                    .fill(fill)
                    .border(Color.white.opacity(0.25), width: 1)

                VStack(spacing: 3) {
                    // Zone label (always visible)
                    Text(zone.label)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)

                    // Save / goal counts (only shown once there's data)
                    if total > 0 {
                        HStack(spacing: 5) {
                            if saves > 0 {
                                Text("✓\(saves)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                            if goals > 0 {
                                Text("✗\(goals)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding(6)
            }
        }
        .frame(height: 68)
        .frame(maxWidth: .infinity)
        // Make the tap target feel responsive
        .contentShape(Rectangle())
    }
}
