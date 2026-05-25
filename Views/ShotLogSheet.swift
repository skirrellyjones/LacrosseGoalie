import SwiftUI

/// Bottom sheet for logging a shot.
/// - When shot location is ON:  `zone` is set, outcome defaults to .save
/// - When shot location is OFF: `zone` is nil, outcome is pre-selected by whichever button was tapped
struct ShotLogSheet: View {
    @Environment(\.dismiss) var dismiss

    let zone: CageZone?      // nil when shot-location tracking is off
    let half: Int
    var onLog: (Shot) -> Void

    @State private var outcome: ShotOutcome
    @State private var type: ShotType = .outside

    /// Use this init to pre-select the outcome (e.g. when the user tapped "Save" or "Goal" directly)
    init(zone: CageZone?, half: Int, preselectedOutcome: ShotOutcome = .save, onLog: @escaping (Shot) -> Void) {
        self.zone = zone
        self.half = half
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
                        Text("· Half \(half)")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    Divider()
                }

                // Outcome selector (always shown)
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

                Spacer()

                // Log button
                Button {
                    let shot = Shot(zone: zone, outcome: outcome, type: type, half: half)
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
            .navigationTitle(zone != nil ? "Log Shot" : "Log Shot · Half \(half)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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
