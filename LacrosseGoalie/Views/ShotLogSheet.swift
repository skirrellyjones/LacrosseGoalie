import SwiftUI

/// Bottom sheet for logging a shot.
/// - When shot location is ON:  `zone` is set, outcome selector is shown (user picks Save/Goal here)
/// - When shot location is OFF: `zone` is nil, outcome was already chosen — selector is hidden
struct ShotLogSheet: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss

    let zone: CageZone?              // nil when shot-location tracking is off
    let showOutcomePicker: Bool      // false when user already tapped Save/Goal button
    let preselectedOutcome: ShotOutcome
    var onLog: (Shot) -> Void

    @State private var outcome: ShotOutcome
    @State private var type: ShotType = .outside

    init(zone: CageZone?, showOutcomePicker: Bool, preselectedOutcome: ShotOutcome = .save, onLog: @escaping (Shot) -> Void) {
        self.zone = zone
        self.showOutcomePicker = showOutcomePicker
        self.preselectedOutcome = preselectedOutcome
        self._outcome = State(initialValue: preselectedOutcome)
        self.onLog = onLog
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Zone badge — only shown when location tracking is on
                if let zone {
                    HStack {
                        Image(systemName: "scope")
                            .foregroundColor(.secondary)
                        Text("Zone: \(zone.label)")
                            .font(.headline)
                    }
                    .padding()
                    Divider()
                }

                // Outcome selector — only shown when location is ON (cage grid tap)
                // Hidden when location is OFF because the user already chose Save or Goal
                if showOutcomePicker {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Outcome")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            OutcomeButton(
                                label: "Save",
                                icon: "hand.raised.fill",
                                color: .green,
                                isSelected: outcome == .save
                            ) { outcome = .save }

                            OutcomeButton(
                                label: "Goal Against",
                                icon: "xmark.circle.fill",
                                color: .red,
                                isSelected: outcome == .goal
                            ) { outcome = .goal }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 16)

                    Divider().padding(.vertical, 14)
                }

                // Shot type selector
                VStack(alignment: .leading, spacing: 10) {
                    Text("Shot Type")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    VStack(spacing: 8) {
                        ForEach(ShotType.allCases, id: \.self) { t in
                            Button {
                                type = t
                            } label: {
                                HStack {
                                    Text(t.rawValue)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: type == t ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(type == t ? .green : .secondary)
                                }
                                .padding()
                                .background(type == t
                                    ? Color.green.opacity(0.08)
                                    : Color(.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top, showOutcomePicker ? 0 : 16)

                Spacer()

                // Log button
                Button {
                    let shot = Shot(zone: zone, outcome: outcome, type: type, half: 1)
                    onLog(shot)
                } label: {
                    HStack {
                        Image(systemName: outcome == .save ? "hand.raised.fill" : "xmark.circle.fill")
                        Text("Log \(outcome.rawValue)")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(outcome == .save ? Color.green : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Log Shot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            // SwiftUI reuses the sheet view between presentations, so @State
            // doesn't re-initialize automatically. Force-sync on every appearance.
            outcome = preselectedOutcome
        }
    }
}

// MARK: - Outcome Button

private struct OutcomeButton: View {
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                Text(label)
                    .font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? color.opacity(0.18) : Color(.secondarySystemGroupedBackground))
            .foregroundColor(isSelected ? color : .secondary)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .cornerRadius(14)
        }
    }
}
