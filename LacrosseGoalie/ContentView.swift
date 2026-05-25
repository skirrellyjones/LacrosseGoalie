import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    @State private var activeGame: Game? = nil
    @State private var pendingGame: Game? = nil  // waiting for season assignment

    var body: some View {
        NavigationStack {
            HomeView(activeGame: $activeGame)
        }
        .fullScreenCover(item: $activeGame) { game in
            LiveGameView(game: game) { completedGame in
                activeGame = nil
                if store.historyEnabled {
                    pendingGame = completedGame  // trigger season picker
                }
            }
        }
        .sheet(item: $pendingGame) { game in
            SeasonPickerView(game: game) {
                pendingGame = nil
            }
        }
        .preferredColorScheme(store.darkModeEnabled ? .dark : nil)
    }
}
