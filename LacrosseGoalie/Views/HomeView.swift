import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: DataStore
    @Binding var activeGame: Game?

    @State private var showingSetup = false
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 32) {

            // MARK: - Header
            VStack(spacing: 10) {
                Image(systemName: "figure.lacrosse")
                    .font(.system(size: 70))
                    .foregroundColor(.green)
                Text("Lacrosse Goalie")
                    .font(.largeTitle.bold())
                Text("Stat Tracker")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 50)

            Spacer()

            // MARK: - Actions
            VStack(spacing: 14) {

                // Always visible: start a new game
                Button {
                    showingSetup = true
                } label: {
                    Label("New Game", systemImage: "plus.circle.fill")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }

                // Only shown when history is enabled
                if store.historyEnabled {
                    NavigationLink {
                        SeasonListView()
                    } label: {
                        Label("My Seasons", systemImage: "calendar.badge.clock")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showingSetup) {
            GameSetupView { newGame in
                activeGame = newGame
                showingSetup = false
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}
