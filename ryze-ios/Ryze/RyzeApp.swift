import SwiftUI

@main
struct RyzeApp: App {
    @StateObject private var game = GameModel()
    @StateObject private var bank = BankModel()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(game).environmentObject(bank)
                .onAppear { bank.game = game }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var game: GameModel
    @AppStorage("ryze_appearance") private var appearance = "dark"
    var body: some View {
        Group {
            let v = ProcessInfo.processInfo.environment["RYZE_VIEW"]
            if v == "profile" { ProfileSheet() }
            else if v == "plans" { PlansView() }
            else if v == "settings" { NavigationStack { ProfileDetailView(detail: .settings) } }
            else if v == "qr" { QRSheet() }
            else if game.onboarded { MainTabView() } else { OnboardingFlow() }
        }
        .animation(.easeInOut, value: game.onboarded)
        .fontDesign(.rounded).monospacedDigit()
            .preferredColorScheme(appearance == "system" ? nil : (appearance == "light" ? .light : .dark))
    }
}
