import SwiftUI

@main
struct RyzeApp: App {
    @StateObject private var game = GameModel()
    @StateObject private var bank = BankModel()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(game).environmentObject(bank)
                .onAppear { bank.game = game }
                .onChange(of: scenePhase) { _, p in if p != .active { game.saveState(); bank.saveState() } }
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
            else if v == "analytics" { AnalyticsView() }
            else if v == "exchange" { ExchangeView() }
            else if v == "scan" { ScanPayView() }
            else if v == "split" { SplitBillView() }
            else if v == "bank" { BankTransferView() }
            else if v == "redeem" { RewardsStoreSheet() }
            else if v == "earn" { EarnSheet() }
            else if v == "search" { SearchSheet() }
            else if v == "ordercard" { OrderCardSheet() }
            else if v == "cardlimit" { CardLimitSheet() }
            else if v == "applepay" { ApplePaySheet() }
            else if v == "cardstudio" { CardStudioSheet() }
            else if v == "coupon" { CouponRedeemedSheet(reward: GameModel.rewards[1]) }
            else if v == "vcard" { ScreenScroll { CardFace(last4: "8842", revealed: true, name: "Klevi", style: .midnight, label: "Virtual"); CardFace(last4: "4827", revealed: false, name: "Klevi", style: .gold, customText: "DREAM BIG") } }
            else if v == "grow" { GrowView() }
            else if v == "newgoal" { AddGoalSheet() }
            else if v == "goaldetail" { NavigationStack { GoalDetailView(goalId: "phone") } }
            else if game.onboarded { MainTabView() } else { OnboardingFlow() }
        }
        .animation(.easeInOut, value: game.onboarded)
        .fontDesign(.rounded).monospacedDigit()
            .preferredColorScheme({ let a = ProcessInfo.processInfo.environment["RYZE_APPEARANCE"] ?? appearance; return a == "system" ? nil : (a == "light" ? .light : .dark) }())
    }
}
