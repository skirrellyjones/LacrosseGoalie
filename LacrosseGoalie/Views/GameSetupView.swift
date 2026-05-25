import SwiftUI

struct GameSetupView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var opponent = ""

    /// Called when the user taps "Start Game" — passes back a fresh Game
    var onStart: (Game) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Opponent Name", text: $opponent)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Game Info")
                } footer: {
                    Text("You can leave this blank if you don't know the opponent yet.")
                }

                Section {
                    Button {
                        let name = opponent.trimmingCharacters(in: .whitespaces)
                        let game = Game(opponent: name.isEmpty ? "Unknown Opponent" : name)
                        onStart(game)
                    } label: {
                        HStack {
                            Spacer()
                            Label("Start Game", systemImage: "play.circle.fill")
                                .font(.headline)
                                .foregroundColor(.green)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("New Game")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
