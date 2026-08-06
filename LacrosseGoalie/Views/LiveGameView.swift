import SwiftUI

/// Bundles everything the shot log sheet needs into one value.
/// Using .sheet(item:) guarantees a fresh ShotLogSheet instance
/// every time — no stale @State from a previous presentation.
struct ShotLogContext: Identifiable {
    let id = UUID()
    let zone: CageZone?
    let preselectedOutcome: ShotOutcome
    let showOutcomePicker: Bool
    let half: Int
}

/// The main in-game tracking screen.
struct LiveGameView: View {
    @EnvironmentObject var store: DataStore
    @State var game: Game
    var onComplete: (Game) -> Void

    @State private var shotLogContext: ShotLogContext?
    @State private var showingEndGameAlert = false
    @State private var showingHalfAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Live stats across the top
                    LiveStatsBar(game: game)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Opponent label + half indicator
                    HStack {
                        Text("vs \(game.opponent)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(game.currentHalf == 1 ? "1st Half" : "2nd Half")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        if game.currentHalf == 1 {
                            Button("→ 2nd Half") { showingHalfAlert = true }
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal)

                    // ── Shot entry: cage grid OR simple buttons ──────────────
                    if store.shotLocationEnabled {
                        Text("Tap the zone where the shot went →")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        CageGridView(game: game) { zone in
                            shotLogContext = ShotLogContext(
                                zone: zone,
                                preselectedOutcome: .save,
                                showOutcomePicker: true,
                                half: game.currentHalf
                            )
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
                                if store.expressModeEnabled {
                                    game.shots.append(
                                        Shot(zone: nil, outcome: .save, type: .outside, half: game.currentHalf)
                                    )
                                } else {
                                    shotLogContext = ShotLogContext(
                                        zone: nil,
                                        preselectedOutcome: .save,
                                        showOutcomePicker: false,
                                        half: game.currentHalf
                                    )
                                }
                            }
                            ShotButton(label: "Goal Against", icon: "xmark.circle.fill", color: .red) {
                                if store.expressModeEnabled {
                                    game.shots.append(
                                        Shot(zone: nil, outcome: .goal, type: .outside, half: game.currentHalf)
                                    )
                                } else {
                                    shotLogContext = ShotLogContext(
                                        zone: nil,
                                        preselectedOutcome: .goal,
                                        showOutcomePicker: false,
                                        half: game.currentHalf
                                    )
                                }
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        game.shots.removeLast()
                    } label: {
                        Label("Undo Shot", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(game.shots.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("End Game") { showingEndGameAlert = true }
                        .foregroundColor(.red)
                }
            }
        }
        .sheet(item: $shotLogContext) { context in
            ShotLogSheet(
                zone: context.zone,
                showOutcomePicker: context.showOutcomePicker,
                preselectedOutcome: context.preselectedOutcome,
                half: context.half
            ) { shot in
                game.shots.append(shot)
                shotLogContext = nil
            }
        }
        .alert("Start 2nd Half?", isPresented: $showingHalfAlert) {
            Button("Start 2nd Half") { game.currentHalf = 2 }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All future shots and clears will be logged to the 2nd half.")
        }
        .alert("End Game?", isPresented: $showingEndGameAlert) {
            Button("End Game", role: .destructive) {
                game.isCompleted = true
                onComplete(game)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let savePct = String(format: "%.1f", game.savePercentage)
            Text("Final: Saves \(game.totalSaves) · Goals \(game.totalGoalsAgainst) · Sv% \(savePct)%")
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
            StatPill(label: "Saves", value: "\(game.totalSaves)", color: .green)
            StatPill(label: "Goals", value: "\(game.totalGoalsAgainst)", color: .red)
            StatPill(label: "Sv%", value: String(format: "%.1f%%", game.savePercentage), color: .blue)
            StatPill(label: "Clr%", value: String(format: "%.0f%%", game.clearPercentage), color: .teal)
            StatPill(label: "GBs", value: "\(game.groundBalls)", color: .orange)
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
                let clearPct = String(format: "%.0f%%", game.clearPercentage)
                Text("\(game.successfulClears) / \(game.clearAttempts)  (\(clearPct))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Button {
                    game.clears.removeLast()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.subheadline)
                        .foregroundColor(game.clears.isEmpty ? .secondary.opacity(0.3) : .secondary)
                }
                .disabled(game.clears.isEmpty)
            }

            HStack(spacing: 10) {
                Button {
                    game.clears.append(Clear(wasSuccessful: true, half: game.currentHalf))
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
                    game.clears.append(Clear(wasSuccessful: false, half: game.currentHalf))
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
                Text("Passes cut off")
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
