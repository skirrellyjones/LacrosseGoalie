import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    // activeGame drives the full-screen live tracking view
    @State private var activeGame: Game? = nil

    var body: some View {
        NavigationStack {
            HomeView(activeGame: $activeGame)
        }
        // Full-screen cover so the live game takes over the whole screen
        .fullScreenCover(item: $activeGame) { game in
            LiveGameView(game: game) { completedGame in
                store.addGame(completedGame)
                activeGame = nil
            }
        }
    }
}
