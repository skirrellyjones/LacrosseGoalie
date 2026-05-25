import SwiftUI

/// The main in-game tracking screen.
struct LiveGameView: View {
    @EnvironmentObject var store: DataStore
    @State var game: Game
    var onComplete: (Game) -> Void

    @State private var selectedZone: CageZone? = nil
    @State private var preselectedOutcome: ShotOutcome = .save
    @State private var showingShotLog = false
    @State private var showingEndGameAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Live stats across the top
                    LiveStatsBar(game: game)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Opponent label
                    Text("vs \(game.opponent)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    // ── Shot entry: cage grid OR simple buttons ──────────────
                    if store.shotLocationEnabled {
                        Text("Tap the zone where the shot went →")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        CageGridView(game: game) { zone in
                            selectedZone = zone
                            preselectedOutcome = .save
                            showingShotLog = true
                        }
                        .padding(.horizontal)

                    } else {
                        Text("Log a shot:")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            ShotButton(label: "Save", icon: "hand.raised.fill", color: .green) {
                                selectedZone = nil
                                preselectedOutcome = .save
                                showingShotLog = true
                            }
                            ShotButton(label: "Goal Against", icon: "xmark.circle.fill", color: .red) {
                                selectedZone = nil
                                preselectedOutcome = .goal
                                showingShotLog = true
                            }
                        }
                        .padding(.horizontal)
                    }
                    // ────────────────────────────────────────────────────────

                    Divider().padding(.top, 4)

                    VStack(spacing: 14) {
                        ClearTrackingView(game: $game)
                        GroundBallView(game: $game)
                        InterceptionView(game: $game)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Live Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("End Game") { showingEndGameAlert = true }
                        .foregroundColor(.red)
                }
            }
        }
        .sheet(isPresented: $showingShotLog) {
            ShotLogSheet(
                zone: selectedZone,
                showOutcomePicker: store.shotLocationEnabled, // cage tap = user picks outcome in sheet; button tap = already chosen
                preselectedOutcome: preselectedOutcome
            ) { shot in
                game.shots.append(shot)
                showingShotLog = false
            }
        }
        .alert("End Game?", isPresented: $showingEndGameAlert) {
            Button("End Game", role: .destructive) {
                game.isCompleted = true
                onComplete(game)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Final: Saves \(game.totalSaves) · Goals \(game.totalGoalsAgainst) · Sv% \(String(format: "%.1f", game.savePercentage))%")
        }
    }
}

// MARK: - Simple Save / Goal Button (used when location tracking is off)

private struct ShotButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                Text(label)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.35), lineWidth: 1.5)
            )
            .cornerRadius(16)
        }
    }
}

// MARK: - Live Stats Bar

struct LiveStatsBar: View {
    let game: Game

    var body: some View {
        HStack(spacing: 0) {
            StatPill(label: "Saves",  value: "\(game.totalSaves)",                            color: .green)
            StatPill(label: "Goals",  value: "\(game.totalGoalsAgainst)",                     color: .red)
            StatPill(label: "Sv%",    value: String(format: "%.1f%%", game.savePercentage),   color: .blue)
            StatPill(label: "Clr%",   value: String(format: "%.0f%%", game.clearPercentage),  color: .teal)
            StatPill(label: "GBs",    value: "\(game.groundBalls)",                           color: .orange)
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Clear Tracking

struct ClearTrackingView: View {
    @Binding var game: Game

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Clears")
                    .font(.headline)
                Spacer()
                Text("\(game.successfulClears) / \(game.clearAttempts)  (\(String(format: "%.0f%%", game.clearPercentage)))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    game.clears.append(Clear(wasSuccessful: true, half: 1))
                } label: {
                    Label("Clear ✓", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                }

                Button {
                    game.clears.append(Clear(wasSuccessful: false, half: 1))
                } label: {
                    Label("Clear ✗", systemImage: "xmark.circle.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

// MARK: - Interceptions

struct InterceptionView: View {
    @Binding var game: Game

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Interceptions")
                    .font(.headline)
                Text("Passes or shots cut off")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 20) {
                Button {
                    if game.interceptions > 0 { game.interceptions -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(game.interceptions > 0 ? .secondary : .secondary.opacity(0.3))
                }
                .disabled(game.interceptions == 0)

                Text("\(game.interceptions)")
                    .font(.title.bold())
                    .frame(minWidth: 36)

                Button {
                    game.interceptions += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

// MARK: - Ground Balls

struct GroundBallView: View {
    @Binding var game: Game

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ground Balls")
                    .font(.headline)
                Text("Loose balls secured outside crease")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 20) {
                Button {
                    if game.groundBalls > 0 { game.groundBalls -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(game.groundBalls > 0 ? .secondary : .secondary.opacity(0.3))
                }
                .disabled(game.groundBalls == 0)

                Text("\(game.groundBalls)")
                    .font(.title.bold())
                    .frame(minWidth: 36)

                Button {
                    game.groundBalls += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}
