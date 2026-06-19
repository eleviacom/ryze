import SwiftUI

@main
struct RyzeApp: App {
    @StateObject private var game = GameModel()
    @StateObject private var bank = BankModel()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(game).environmentObject(bank).preferredColorScheme(.dark)
                .onAppear { bank.game = game }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var game: GameModel
    var body: some View {
        Group {
            let v = ProcessInfo.processInfo.environment["RYZE_VIEW"]
            if v == "profile" { ProfileSheet().environmentObject(game) }
            else if v == "plans" { PlansView().environmentObject(game) }
            else if game.onboarded { MainTabView() } else { OnboardingFlow() }
        }
        .animation(.easeInOut, value: game.onboarded)
        .fontDesign(.rounded).monospacedDigit()
    }
}
