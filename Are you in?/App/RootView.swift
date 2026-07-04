import SwiftUI

struct RootView: View {
    @State private var appState = AppState()

    var body: some View {
        Group {
            switch appState.phase {
            case .bootstrapping:
                FullScreenLoading()
            case .loggedOut:
                NameEntryView()
            case .awaitingPartner(let user):
                PairingView(user: user)
            case .ready(let user, let partner):
                MainContainerView(user: user, partner: partner)
            }
        }
        .environment(appState)
        .task {
            await appState.bootstrap()
            #if DEBUG
            await UITestHarness.runOnboarding(appState: appState)
            #endif
        }
    }
}

struct MainContainerView: View {
    let user: User
    let partner: PartnerSummary
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(user: user, partner: partner, path: $path)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .game(let sessionId):
                        GameView(sessionId: sessionId, partnerName: partner.name, path: $path)
                    case .results(let sessionId):
                        ResultsView(sessionId: sessionId, partnerName: partner.name, path: $path)
                    case .history:
                        HistoryView()
                    }
                }
        }
        .tint(Theme.Color.accent)
    }
}

#Preview {
    RootView()
}
