import SwiftUI

// MARK: - Shared components
struct AppCard<C: View>: View { @ViewBuilder var content: C
    var body: some View { content.padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .background(ZStack {
            RoundedRectangle(cornerRadius: 24).fill(LinearGradient(colors: [Brand.elev2, Brand.elev1], startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: 24).fill(LinearGradient(colors: [Color.white.opacity(0.06), .clear], startPoint: .top, endPoint: .center))
        })
        .specularBorder(24)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Brand.shadow1, radius: 2, y: 1)
        .shadow(color: Brand.shadow2, radius: 22, y: 14) } }
struct FeaturedCard<C: View>: View { @ViewBuilder var content: C
    var body: some View { content.padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.gold)
        .overlay(LinearGradient(colors: [Color.white.opacity(0.30), .clear], startPoint: .topLeading, endPoint: .center).blendMode(.softLight))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Brand.goldEdge.opacity(0.5), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Brand.yellow.opacity(0.26), radius: 22, y: 12) } }
struct PillButton: View { let title: String; var system: String? = nil; var style: Style = .primary; var enabled = true; let action: () -> Void
    enum Style { case primary, soft, dark }
    var body: some View { Button { if enabled { action() } } label: { HStack(spacing: 6) { if let s = system { Image(systemName: s).font(.system(size: 13, weight: .semibold)) }; Text(title).font(.system(size: 14, weight: .semibold)) }.foregroundColor(fg).padding(.horizontal, 16).frame(height: 40).background(bg).overlay(Capsule().stroke(style == .soft ? Brand.hairline : .clear, lineWidth: 1)).clipShape(Capsule()) }.buttonStyle(PressStyle()).opacity(enabled ? 1 : 0.4) }
    var bg: Color { style == .primary ? Brand.text : style == .dark ? .black : Brand.surface }; var fg: Color { style == .primary ? Brand.onText : style == .dark ? .white : Brand.text } }
struct IconTile: View { let system: String; var color: Color = Brand.yellowInk; var size: CGFloat = 44
    var body: some View { Image(systemName: system).font(.system(size: size * 0.42, weight: .semibold)).symbolRenderingMode(.hierarchical).foregroundColor(color).frame(width: size, height: size).background(color.opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: 13)) } }
struct Avatar: View { let name: String; var size: CGFloat = 40; var you = false; var imageData: Data? = nil
    var body: some View {
        Group {
            if let d = imageData, let ui = UIImage(data: d) { Image(uiImage: ui).resizable().scaledToFill() }
            else { Text(String(name.prefix(1)).uppercased()).font(.system(size: size * 0.4, weight: .bold)).foregroundColor(you ? .black : Brand.text).frame(maxWidth: .infinity, maxHeight: .infinity).background(you ? Brand.yellow : Brand.surface) }
        }
        .frame(width: size, height: size).clipShape(Circle()).overlay(Circle().stroke(you ? Brand.yellow : Brand.hairline, lineWidth: 1)) } }
struct Bar: View { var v: Double; var body: some View { ProgressBar(value: v) } }
struct Ring: View { var v: Double; var size: CGFloat = 52
    var body: some View { ZStack { Circle().stroke(Brand.hairline, lineWidth: 5); Circle().trim(from: 0, to: max(0.02, min(1, v))).stroke(Brand.yellow, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90)) }.frame(width: size, height: size) } }
private func eyebrow(_ s: String) -> some View { HStack(spacing: 7) { Capsule().fill(Brand.yellowInk).frame(width: 14, height: 2); Text(s.uppercased()).font(.system(size: 11, weight: .semibold)).tracking(1.4).foregroundColor(Brand.faint) } }
struct ScreenScroll<C: View>: View {
    @ViewBuilder var content: C
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 16) { content }
                .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 140)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ZStack { Brand.bg; RadialGradient(colors: [Brand.yellow.opacity(0.05), .clear], center: .top, startRadius: 4, endRadius: 380) }.ignoresSafeArea())
    }
}
struct StatCard: View { let value: String; let label: String
    var body: some View { VStack(alignment: .leading, spacing: 2) { Text(value).font(.system(size: 20, weight: .bold)).foregroundColor(Brand.text); Text(label).font(.system(size: 12)).foregroundColor(Brand.mute) }.padding(14).frame(maxWidth: .infinity, alignment: .leading).background(Brand.surface).overlay(RoundedRectangle(cornerRadius: 12).stroke(Brand.hairline, lineWidth: 1)).clipShape(RoundedRectangle(cornerRadius: 12)) } }
struct DarkButton: View { let title: String; var system: String? = nil; let action: () -> Void
    var body: some View { Button(action: action) { HStack(spacing: 7) { if let s = system { Image(systemName: s) }; Text(title).font(.system(size: 16, weight: .semibold)) }.foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 50).background(Color.black).clipShape(Capsule()) }.buttonStyle(PressStyle()) } }
struct ToastBanner: View { let toast: Toast
    var body: some View { HStack(spacing: 12) { Text(toast.label).font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.text).lineLimit(1); if toast.xp > 0 { Text("+\(toast.xp) XP").font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.good) }; if toast.coins != 0 { Text("\(toast.coins > 0 ? "+" : "")\(toast.coins)").font(.system(size: 14, weight: .semibold)).foregroundColor(toast.coins < 0 ? Brand.mute : Brand.yellow) } }.padding(.vertical, 12).padding(.horizontal, 18).background(Brand.surface).overlay(Capsule().stroke(Brand.hairline, lineWidth: 1)).clipShape(Capsule()) } }
struct QuickAction: View { let icon: String; let label: String; var prominent: Bool = false; let action: () -> Void
    var body: some View { Button(action: action) { VStack(spacing: 7) {
        Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundColor(prominent ? .black : Brand.text)
            .frame(width: 52, height: 52)
            .background(Circle().fill(prominent ? AnyShapeStyle(Brand.gold) : AnyShapeStyle(Brand.elev2)))
            .overlay(Circle().strokeBorder(prominent ? Color.clear : Brand.hairline, lineWidth: 1))
            .shadow(color: prominent ? Brand.yellow.opacity(0.30) : .clear, radius: prominent ? 10 : 0, y: 5)
        Text(label).font(.system(size: 12, weight: .medium)).foregroundColor(Brand.mute) } }.buttonStyle(PressStyle()).frame(maxWidth: .infinity) } }
struct MissionRowView: View { @EnvironmentObject var game: GameModel; let m: Mission
    var body: some View { AppCard { VStack(spacing: 10) {
        HStack(spacing: 14) { IconTile(system: m.aiGenerated ? "sparkles" : m.icon)
            VStack(alignment: .leading, spacing: 3) { Text(m.title).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text)
                HStack(spacing: 12) { Text("+\(m.xp) XP").font(.system(size: 12, weight: .medium)).foregroundColor(Brand.good); Text("+\(m.coins) " + T("coins", "monedha")).font(.system(size: 12, weight: .medium)).foregroundColor(Brand.yellow) } }
            Spacer()
            if m.claimed { HStack(spacing: 4) { Image(systemName: "checkmark.seal.fill").foregroundColor(Brand.good); Text(T("Done", "U krye")).font(.system(size: 13, weight: .semibold)).foregroundColor(Brand.mute) } }
            else if m.progress >= m.target { PillButton(title: T("Claim", "Merr")) { game.claim(m.id) } }
            else { PillButton(title: m.target > 1 ? "+1" : T("Start", "Fillo"), style: .soft) { game.progress(m.id, by: m.target > 1 ? 1 : m.target) } } }
        if m.target > 1 && !m.claimed { VStack(alignment: .leading, spacing: 5) { Bar(v: Double(m.progress) / Double(m.target)); Text("\(m.progress)/\(m.target)").font(.system(size: 11)).foregroundColor(Brand.faint) } } } } }
}

// MARK: - Amount sheet (send / request / add / fund)
struct AmountSheet: View {
    enum Mode { case send, request, add, fund }
    let mode: Mode; var contact: Contact? = nil; var goalName: String? = nil; let onConfirm: (Double, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    @State private var amount = ""; @State private var note = ""
    var title: String { switch mode { case .send: T("Send money", "Dërgo para"); case .request: T("Request money", "Kërko para"); case .add: T("Add money", "Shto para"); case .fund: T("Add to goal", "Shto te synimi") } }
    var cta: String { switch mode { case .send: T("Send", "Dërgo"); case .request: T("Request", "Kërko"); case .add: T("Add money", "Shto"); case .fund: T("Save", "Ruaj") } }
    var body: some View {
        VStack(spacing: 18) {
            HStack { Text(title).font(.system(size: 20, weight: .bold)).foregroundColor(Brand.text); Spacer(); Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(Brand.mute) } }
            if let c = contact { HStack(spacing: 10) { Avatar(name: c.name, size: 38); VStack(alignment: .leading) { Text(c.name).foregroundColor(Brand.text).font(.system(size: 15, weight: .semibold)); Text(c.tag).foregroundColor(Brand.mute).font(.system(size: 13)) }; Spacer() } }
            if let g = goalName { Text(g).foregroundColor(Brand.mute) }
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0", text: $amount).keyboardType(.numberPad).font(.system(size: 52, weight: .bold)).foregroundColor(Brand.text).fixedSize()
                Text("L").font(.system(size: 26, weight: .semibold)).foregroundColor(Brand.mute)
            }
            if mode == .send || mode == .request {
                TextField("", text: $note, prompt: Text(T("Add a note 💬", "Shto një shënim 💬")).foregroundColor(Brand.faint)).foregroundColor(Brand.text).multilineTextAlignment(.center).padding().frame(height: 50).frame(maxWidth: .infinity).background(Brand.surface).clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Spacer()
            PrimaryButton(title: cta, enabled: (Double(amount) ?? 0) > 0) { onConfirm(Double(amount) ?? 0, note); dismiss() }
        }
        .padding(20).frame(maxWidth: .infinity, maxHeight: .infinity).background(Brand.bg)
    }
}

// MARK: - Tab bar
struct MainTabView: View {
    @EnvironmentObject var game: GameModel
    @AppStorage("ryze_lang") private var lang = "en"
    @State private var sel = Int(ProcessInfo.processInfo.environment["RYZE_TAB"] ?? "0") ?? 0
    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $sel) {
                HomeView(sel: $sel).tag(0).tabItem { Label(T("Home", "Ballina"), systemImage: "house.fill") }
                CardsView().tag(1).tabItem { Label(T("Cards", "Kartat"), systemImage: "creditcard.fill") }
                PayView().tag(2).tabItem { Label(T("Pay", "Paguaj"), systemImage: "paperplane.fill") }
                AssistantView().tag(3).tabItem { Label(T("Assistant", "Asistenti"), systemImage: "sparkles") }
                RewardsHub().tag(4).tabItem { Label(T("Rewards", "Shpërblime"), systemImage: "gift.fill") }
            }.tint(Brand.yellow)
            CelebrationOverlay(trigger: game.celebrate).ignoresSafeArea()
            if let t = game.toast { ToastBanner(toast: t).padding(.top, 6).transition(.move(edge: .top).combined(with: .opacity)) }
        }
        .animation(.spring(response: 0.4), value: game.toast)
        .sensoryFeedback(.success, trigger: game.celebrate)
    }
}

// MARK: - Home (Bento dashboard, modular tiles, no big-number / circle-row template)
struct HomeView: View {
    @EnvironmentObject var game: GameModel
    @EnvironmentObject var bank: BankModel
    @Binding var sel: Int
    @State private var rizNudge = true
    @AppStorage("ryze_lang") private var lang = "en"
    enum HSheet: Int, Identifiable { case add, profile, grow, history, analytics, exchange, search; var id: Int { rawValue } }
    @State private var homeSheet: HSheet? = nil
    var nearestGoal: Goal? { bank.goals.min { ($0.saved / $0.target) > ($1.saved / $1.target) } }
    var weekNet: Double { bank.transactions.filter { $0.amount < 0 }.prefix(8).reduce(0) { $0 + $1.amount } }
    var weekBars: [Double] {
        var v = bank.transactions.filter { $0.amount < 0 }.prefix(7).map { abs($0.amount) }
        while v.count < 7 { v.append(Double((v.count * 137 % 380) + 140)) } // ponytail: pad to 7 for the sparkline
        return Array(v.prefix(7))
    }
    var body: some View {
        ScreenScroll {
            TopBar(name: game.name, imageData: game.avatarData, onProfile: { homeSheet = .profile }, onAnalytics: { homeSheet = .analytics }, onSearch: { homeSheet = .search })

            // 1) Hero bento, balance tile (void) + level/points tile (the one gold fill)
            HStack(alignment: .top, spacing: 12) {
                balanceTile.frame(height: 178).onTapGesture { homeSheet = .analytics }
                Button { sel = 4 } label: { levelTile.frame(height: 178) }.buttonStyle(PressStyle())
            }

            // 2) Move-money console, contained square actions in one card (no floating circles)
            AppCard { HStack(spacing: 0) {
                moveTile("plus", T("Add", "Shto")) { homeSheet = .add }
                moveDivider
                moveTile("paperplane.fill", T("Send", "Dërgo")) { sel = 2 }
                moveDivider
                moveTile("arrow.down.left", T("Request", "Kërko")) { sel = 2 }
                moveDivider
                moveTile("arrow.left.arrow.right", T("Exchange", "Këmbe")) { homeSheet = .exchange }
            } }

            // 3) Mixed bento row, savings goal + this-week spend
            HStack(alignment: .top, spacing: 12) {
                if let g = nearestGoal {
                    Button { homeSheet = .grow } label: { goalTile(g).frame(height: 128) }.buttonStyle(PressStyle())
                }
                spendTile.frame(height: 128).onTapGesture { homeSheet = .analytics }
            }

            // 4) Riz nudge
            if rizNudge { AppCard { HStack(spacing: 12) { IconTile(system: "sparkles", size: 40); VStack(alignment: .leading, spacing: 2) { Text("Riz").font(.system(size: 13, weight: .semibold)).foregroundColor(Brand.yellowInk); Text(T("You spent 20% more on eating out this week. Want to set a budget?", "Shpenzove 20% më shumë për ushqim këtë javë. Të vendosim një buxhet?")).font(.system(size: 13)).foregroundColor(Brand.mute) }; Spacer(); Button { withAnimation { rizNudge = false } } label: { Image(systemName: "xmark").foregroundColor(Brand.faint).font(.system(size: 12)) } } } }

            // 5) Activity, bounded + capped card with See all
            HStack { eyebrow(T("Recent", "Së fundmi")); Spacer(); Button { homeSheet = .history } label: { HStack(spacing: 3) { Text(T("See all", "Shiko të gjitha")).font(.system(size: 13, weight: .semibold)).foregroundColor(Brand.text); Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(Brand.faint) } } }
            AppCard { VStack(spacing: 0) { ForEach(Array(bank.transactions.prefix(5).enumerated()), id: \.element.id) { i, t in
                txnRow(t)
                if i < 4 { Rectangle().fill(Brand.hairline).frame(height: 1) }
            } } }
        }
        .sheet(item: $homeSheet) { s in
            switch s {
            case .add: AmountSheet(mode: .add) { amt, _ in bank.addMoney(amt) }.presentationDetents([.medium])
            case .profile: ProfileSheet()
            case .grow: GrowView()
            case .history: TxnHistorySheet()
            case .analytics: AnalyticsView()
            case .exchange: ExchangeView()
            case .search: SearchSheet()
            }
        }
    }

    // Balance tile, signature void surface + warm glow + odometer + week sparkline
    private var balanceTile: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack { Text(T("Balance", "Gjendja")).font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(Brand.faint); Spacer(); Button { withAnimation(.smooth(duration: 0.35)) { bank.hideBalance.toggle() } } label: { Image(systemName: bank.hideBalance ? "eye.slash" : "eye").font(.system(size: 13)).foregroundColor(Brand.mute).symbolEffect(.bounce, value: bank.hideBalance) } }
            Spacer(minLength: 6)
            ZStack(alignment: .leading) {
                Text(money(bank.totalALL)).font(.system(size: 27, weight: .bold, design: .rounded)).foregroundStyle(LinearGradient(colors: [.white, Color.white.opacity(0.78)], startPoint: .top, endPoint: .bottom)).contentTransition(.numericText()).blur(radius: bank.hideBalance ? 14 : 0).opacity(bank.hideBalance ? 0 : 1)
                if bank.hideBalance { Text("•• ••• L").font(.system(size: 27, weight: .bold, design: .rounded)).foregroundColor(.white) }
            }.lineLimit(1).minimumScaleFactor(0.6)
            Text(bank.hideBalance ? " " : money(bank.accounts[1].balance, "EUR")).font(.system(size: 12)).foregroundColor(Brand.mute)
            Spacer(minLength: 8)
            sparkline(weekBars, color: Color.white.opacity(0.28), height: 22)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(16)
        .background(ZStack {
            RoundedRectangle(cornerRadius: 24).fill(Brand.void)
            RoundedRectangle(cornerRadius: 24).fill(RadialGradient(colors: [Color(hex: 0xF8D01F).opacity(0.13), .clear], center: .topLeading, startRadius: 8, endRadius: 220))
        })
        .specularBorder(24).clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.5), radius: 18, y: 10)
        .animation(.snappy(duration: 0.5), value: bank.totalALL)
        .environment(\.colorScheme, .dark)
    }

    // Level / points tile, the single gold fill on Home
    private var levelTile: some View {
        FeaturedCard { VStack(alignment: .leading, spacing: 0) {
            HStack { Text("LEVEL \(game.li.level)").font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.black.opacity(0.6)); Spacer(); Image(systemName: "star.circle.fill").font(.system(size: 15)).foregroundColor(.black.opacity(0.7)) }
            Spacer(minLength: 6)
            Text("\(game.coins)").font(.system(size: 26, weight: .bold, design: .rounded)).foregroundColor(.black).contentTransition(.numericText()).animation(.snappy, value: game.coins).lineLimit(1).minimumScaleFactor(0.6)
            Text(T("RyzePoints", "RyzePikë")).font(.system(size: 12)).foregroundColor(.black.opacity(0.65))
            Spacer(minLength: 8)
            GeometryReader { gx in ZStack(alignment: .leading) { Capsule().fill(.black.opacity(0.16)); Capsule().fill(.black.opacity(0.8)).frame(width: gx.size.width * max(0.04, min(1, game.li.progress))) } }.frame(height: 5)
            Text("\(game.li.needed - game.li.intoLevel) " + T("XP to level up", "XP për nivel")).font(.system(size: 10)).foregroundColor(.black.opacity(0.6)).padding(.top, 4)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading) }
    }

    // Savings goal tile
    private func goalTile(_ g: Goal) -> some View {
        AppCard { VStack(alignment: .leading, spacing: 10) {
            Ring(v: g.saved / g.target, size: 38).overlay(Image(systemName: g.icon).font(.system(size: 14)).foregroundColor(Brand.yellow))
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 2) {
                Text(g.name).font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.text).lineLimit(1)
                Text("\(Int(g.saved / g.target * 100))% · \(money(g.saved))").font(.system(size: 12)).foregroundColor(Brand.mute).lineLimit(1)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading) }
    }

    // This-week spend tile
    private var spendTile: some View {
        AppCard { VStack(alignment: .leading, spacing: 8) {
            HStack { Text(T("This week", "Këtë javë")).font(.system(size: 12, weight: .semibold)).foregroundColor(Brand.mute); Spacer(); Image(systemName: "chart.bar.fill").font(.system(size: 11)).foregroundColor(Brand.faint) }
            Spacer(minLength: 0)
            sparkline(weekBars, color: Brand.yellow.opacity(0.8), height: 32)
            Text("−\(money(weekNet))").font(.system(size: 17, weight: .bold)).foregroundColor(Brand.text)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading) }
    }

    private func sparkline(_ vals: [Double], color: Color, height: CGFloat) -> some View {
        let mx = vals.max() ?? 1
        return HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(vals.enumerated()), id: \.offset) { _, v in
                Capsule().fill(color).frame(height: max(4, height * CGFloat(pow(v / mx, 0.55))))
            }
        }.frame(height: height, alignment: .bottom).frame(maxWidth: .infinity, alignment: .leading)
    }

    private var moveDivider: some View { Rectangle().fill(Brand.hairline).frame(width: 1, height: 36) }
    private func moveTile(_ icon: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) { VStack(spacing: 7) { IconTile(system: icon, color: Brand.text, size: 44); Text(label).font(.system(size: 12, weight: .medium)).foregroundColor(Brand.mute) } }.buttonStyle(PressStyle()).frame(maxWidth: .infinity)
    }
    private func txnRow(_ t: Txn) -> some View {
        HStack(spacing: 12) { IconTile(system: t.icon, color: t.amount > 0 ? Brand.good : Brand.text, size: 40)
            VStack(alignment: .leading, spacing: 2) { Text(t.merchant).font(.system(size: 15, weight: .medium)).foregroundColor(Brand.text); Text("\(t.category) · \(t.day)").font(.system(size: 12)).foregroundColor(Brand.faint) }
            Spacer(); Text("\(t.amount > 0 ? "+" : "-")\(money(t.amount, t.currency))").font(.system(size: 15, weight: .semibold)).foregroundColor(t.amount > 0 ? Brand.good : Brand.text) }.padding(.vertical, 11)
    }
}

// Full transaction history (opened from Home → See all)
struct TxnHistorySheet: View {
    @EnvironmentObject var bank: BankModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    var body: some View {
        NavigationStack {
            ScreenScroll {
                AppCard { VStack(spacing: 0) { ForEach(Array(bank.transactions.enumerated()), id: \.element.id) { i, t in
                    HStack(spacing: 12) { IconTile(system: t.icon, color: t.amount > 0 ? Brand.good : Brand.text, size: 40)
                        VStack(alignment: .leading, spacing: 2) { Text(t.merchant).font(.system(size: 15, weight: .medium)).foregroundColor(Brand.text); Text("\(t.category) · \(t.day)").font(.system(size: 12)).foregroundColor(Brand.faint) }
                        Spacer(); Text("\(t.amount > 0 ? "+" : "-")\(money(t.amount, t.currency))").font(.system(size: 15, weight: .semibold)).foregroundColor(t.amount > 0 ? Brand.good : Brand.text) }.padding(.vertical, 11)
                    if i < bank.transactions.count - 1 { Rectangle().fill(Brand.hairline).frame(height: 1) }
                } } }
            }
            .navigationTitle(T("All activity", "Aktiviteti")).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(T("Done", "U krye")) { dismiss() } } }
        }
    }
}

// MARK: - Pay hub + chat threads
struct PayView: View {
    @EnvironmentObject var bank: BankModel
    @AppStorage("ryze_lang") private var lang = "en"
    enum PayFlow: Int, Identifiable { case add, scan, bank, split; var id: Int { rawValue } }
    @State private var flow: PayFlow? = nil
    @State private var search = ""
    @State private var path: [String] = (ProcessInfo.processInfo.environment["RYZE_THREAD"].map { [$0] }) ?? []
    var pending: [(Contact, PayMsg)] { bank.contacts.compactMap { c in if let m = bank.threads[c.id]?.last, m.kind == .request, !m.fromMe, m.status == "pending" { return (c, m) }; return nil } }
    var filtered: [Contact] { search.isEmpty ? bank.contacts : bank.contacts.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.tag.localizedCaseInsensitiveContains(search) } }
    var recent: [Txn] { bank.transactions.filter { ["Sent", "Added", "Transfer", "Exchange"].contains($0.category) }.prefix(4).map { $0 } }
    var body: some View {
        NavigationStack(path: $path) {
            ScreenScroll {
                HStack(alignment: .firstTextBaseline) {
                    Text(T("Pay", "Paguaj")).font(.system(size: 34, weight: .bold)).foregroundColor(Brand.text)
                    Spacer()
                    HStack(spacing: 6) { Image(systemName: "wallet.pass.fill").font(.system(size: 12)).foregroundColor(Brand.yellow); Text(bank.hideBalance ? "•••" : money(bank.totalALL)).font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.text) }.padding(.horizontal, 12).frame(height: 34).background(Brand.surface).overlay(Capsule().stroke(Brand.hairline, lineWidth: 1)).clipShape(Capsule())
                }
                AppCard { HStack(spacing: 0) {
                    payTile("plus", T("Add", "Shto")) { flow = .add }
                    payDivider
                    payTile("qrcode", T("Scan", "Skano")) { flow = .scan }
                    payDivider
                    payTile("building.columns.fill", T("Bank", "Banka")) { flow = .bank }
                    payDivider
                    payTile("person.2.fill", T("Split", "Ndaj")) { flow = .split }
                } }
                if !pending.isEmpty {
                    eyebrow(T("Requests", "Kërkesa"))
                    ForEach(pending, id: \.0.id) { c, m in AppCard { HStack(spacing: 12) { Avatar(name: c.name, size: 42); VStack(alignment: .leading, spacing: 2) { Text(c.name).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text); Text(T("asks", "kërkon") + " \(money(m.amount)) · \(m.note)").font(.system(size: 12)).foregroundColor(Brand.mute).lineLimit(1) }; Spacer(); PillButton(title: T("Pay", "Paguaj")) { bank.payRequest(c.id, m.id) } } } }
                }
                eyebrow(T("Pay a friend", "Paguaj një mik"))
                HStack(spacing: 8) { Image(systemName: "magnifyingglass").foregroundColor(Brand.mute); TextField("", text: $search, prompt: Text(T("Search name or @tag", "Kërko emër ose @tag")).foregroundColor(Brand.faint)).foregroundColor(Brand.text).autocorrectionDisabled() }.padding(.horizontal, 14).frame(height: 46).background(Brand.surface).overlay(Capsule().stroke(Brand.hairline, lineWidth: 1)).clipShape(Capsule())
                if search.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 16) { ForEach(bank.contacts) { c in NavigationLink(value: c.id) { VStack(spacing: 6) { Avatar(name: c.name, size: 56); Text(c.name.split(separator: " ").first.map(String.init) ?? c.name).font(.system(size: 12)).foregroundColor(Brand.mute) } } } }.padding(.vertical, 2) }
                }
                AppCard { VStack(spacing: 0) { ForEach(Array(filtered.enumerated()), id: \.element.id) { idx, c in
                    NavigationLink(value: c.id) { HStack(spacing: 12) { Avatar(name: c.name, size: 44); VStack(alignment: .leading, spacing: 2) { Text(c.name).font(.system(size: 15, weight: .medium)).foregroundColor(Brand.text); Text(c.tag + " · " + T("on Ryze", "në Ryze")).font(.system(size: 12)).foregroundColor(Brand.faint) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(Brand.faint).font(.system(size: 13)) }.padding(.vertical, 11) }.buttonStyle(.plain)
                    if idx < filtered.count - 1 { Rectangle().fill(Brand.hairline).frame(height: 1) }
                } } }
                if !recent.isEmpty && search.isEmpty {
                    eyebrow(T("Recent", "Së fundmi"))
                    AppCard { VStack(spacing: 0) { ForEach(Array(recent.enumerated()), id: \.element.id) { idx, t in
                        HStack(spacing: 12) { IconTile(system: t.icon, color: t.amount > 0 ? Brand.good : Brand.text, size: 40); VStack(alignment: .leading, spacing: 2) { Text(t.merchant).font(.system(size: 15, weight: .medium)).foregroundColor(Brand.text); Text("\(t.category) · \(t.day)").font(.system(size: 12)).foregroundColor(Brand.faint) }; Spacer(); Text("\(t.amount > 0 ? "+" : "-")\(money(t.amount, t.currency))").font(.system(size: 15, weight: .semibold)).foregroundColor(t.amount > 0 ? Brand.good : Brand.text) }.padding(.vertical, 11)
                        if idx < recent.count - 1 { Rectangle().fill(Brand.hairline).frame(height: 1) }
                    } } }
                }
            }
            .navigationDestination(for: String.self) { id in if let c = bank.contacts.first(where: { $0.id == id }) { ChatThreadView(contact: c) } }
            .sheet(item: $flow) { f in
                switch f {
                case .add: AmountSheet(mode: .add) { amt, _ in bank.addMoney(amt) }.presentationDetents([.medium])
                case .scan: ScanPayView()
                case .bank: BankTransferView()
                case .split: SplitBillView()
                }
            }
        }
    }
    var payDivider: some View { Rectangle().fill(Brand.hairline).frame(width: 1, height: 36) }
    func payTile(_ icon: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) { VStack(spacing: 7) { IconTile(system: icon, color: Brand.text, size: 44); Text(label).font(.system(size: 12, weight: .medium)).foregroundColor(Brand.mute) } }.buttonStyle(PressStyle()).frame(maxWidth: .infinity)
    }
}

struct ChatThreadView: View {
    @EnvironmentObject var bank: BankModel
    @AppStorage("ryze_lang") private var lang = "en"
    let contact: Contact
    @State private var text = ""
    @State private var sheet: AmountSheet.Mode? = nil
    var msgs: [PayMsg] { bank.threads[contact.id] ?? [] }
    var body: some View {
        ZStack { Brand.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Avatar(name: contact.name, size: 44)
                    VStack(alignment: .leading, spacing: 2) { Text(contact.name).font(.system(size: 16, weight: .semibold)).foregroundColor(Brand.text); Text(contact.tag + " · " + T("on Ryze", "në Ryze")).font(.system(size: 12)).foregroundColor(Brand.faint) }
                    Spacer()
                    Button { sheet = .request } label: { Text(T("Request", "Kërko")).font(.system(size: 13, weight: .semibold)).foregroundColor(Brand.text).padding(.horizontal, 14).frame(height: 34).overlay(Capsule().stroke(Brand.hairline, lineWidth: 1)) }
                    Button { sheet = .send } label: { Text(T("Send", "Dërgo")).font(.system(size: 13, weight: .semibold)).foregroundColor(.black).padding(.horizontal, 14).frame(height: 34).background(Brand.yellow).clipShape(Capsule()) }
                }.padding(.horizontal, 16).padding(.vertical, 10).background(Brand.elev1)
                Rectangle().fill(Brand.hairline).frame(height: 1)
                ScrollViewReader { proxy in
                    ScrollView { VStack(spacing: 10) { ForEach(msgs) { m in bubble(m).id(m.id) } }.padding(16) }
                        .onChange(of: msgs.count) { _, _ in if let last = msgs.last { withAnimation(.easeOut) { proxy.scrollTo(last.id, anchor: .bottom) } } }
                }
                HStack(spacing: 8) {
                    Menu { Button(T("Send money", "Dërgo para")) { sheet = .send }; Button(T("Request money", "Kërko para")) { sheet = .request } } label: { Image(systemName: "plus").font(.system(size: 18, weight: .bold)).foregroundColor(.black).frame(width: 42, height: 42).background(Brand.yellow).clipShape(Circle()) }
                    TextField("", text: $text, prompt: Text(T("Message", "Mesazh")).foregroundColor(Brand.faint)).foregroundColor(Brand.text).padding(.horizontal, 16).frame(height: 44).background(Brand.surface).overlay(Capsule().stroke(Brand.hairline, lineWidth: 1)).clipShape(Capsule())
                    Button { let t = text.trimmingCharacters(in: .whitespaces); if !t.isEmpty { bank.sendText(contact.id, t); text = "" } } label: { Image(systemName: "arrow.up").font(.system(size: 16, weight: .bold)).foregroundColor(Brand.onText).frame(width: 42, height: 42).background(Brand.text).clipShape(Circle()) }.opacity(text.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                }.padding(12)
            }
        }
        .navigationTitle(contact.name).navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.bg, for: .navigationBar)
        .sheet(item: Binding(get: { sheet.map { SheetWrap(mode: $0) } }, set: { sheet = $0?.mode })) { w in
            AmountSheet(mode: w.mode, contact: contact) { amt, note in if w.mode == .send { bank.send(to: contact, amount: amt, note: note) } else { bank.request(from: contact, amount: amt, note: note) } }.presentationDetents([.large])
        }
    }
    struct SheetWrap: Identifiable { let mode: AmountSheet.Mode; var id: Int { mode == .send ? 0 : 1 } }
    @ViewBuilder func bubble(_ m: PayMsg) -> some View {
        HStack { if m.fromMe { Spacer(minLength: 36) }
            if m.kind == .text {
                Text(m.text).font(.system(size: 15)).foregroundColor(m.fromMe ? Brand.onText : Brand.text).padding(.vertical, 10).padding(.horizontal, 14).background(m.fromMe ? AnyShapeStyle(Brand.text) : AnyShapeStyle(Brand.elev2)).overlay(RoundedRectangle(cornerRadius: 20).stroke(m.fromMe ? Color.clear : Brand.hairline, lineWidth: 1)).clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                moneyBubble(m)
            }
            if !m.fromMe { Spacer(minLength: 36) } }
    }
    func moneyBubble(_ m: PayMsg) -> some View {
        let incoming = m.kind == .request && !m.fromMe && m.status == "pending"
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: m.kind == .send ? "paperplane.fill" : "arrow.down.left").font(.system(size: 14, weight: .bold)).foregroundColor(.black).frame(width: 34, height: 34).background(Color.black.opacity(0.12)).clipShape(Circle())
                VStack(alignment: .leading, spacing: 1) { Text(m.kind == .send ? T("Sent", "Dërguar") : T("Request", "Kërkesë")).font(.system(size: 12, weight: .bold)).foregroundColor(.black.opacity(0.65)); Text(money(m.amount)).font(.system(size: 24, weight: .bold)).foregroundColor(.black) }
            }
            if !m.note.isEmpty { Text(m.note).font(.system(size: 13)).foregroundColor(.black.opacity(0.78)) }
            HStack(spacing: 6) { Image(systemName: m.status == "paid" ? "checkmark.circle.fill" : "clock.fill").font(.system(size: 11)).foregroundColor(.black.opacity(0.55)); Text(m.status.capitalized).font(.system(size: 11, weight: .semibold)).foregroundColor(.black.opacity(0.55)) }
            if incoming { PillButton(title: T("Pay", "Paguaj") + " \(money(m.amount))", style: .dark) { bank.payRequest(contact.id, m.id) } }
        }.padding(16).frame(width: 232, alignment: .leading).background(Brand.gold).clipShape(RoundedRectangle(cornerRadius: 20)).shadow(color: Brand.yellow.opacity(0.22), radius: 12, y: 6)
    }
}

// MARK: - Cards
struct CardsView: View {
    @EnvironmentObject var bank: BankModel
    @EnvironmentObject var game: GameModel
    @AppStorage("ryze_lang") private var lang = "en"
    enum CardFlow: Int, Identifiable { case order, applePay, limit, studio; var id: Int { rawValue } }
    @State private var cardFlow: CardFlow? = nil
    var cardBars: [Double] {
        var v = bank.transactions.filter { $0.amount < 0 }.prefix(7).map { abs($0.amount) }
        while v.count < 7 { v.append(Double((v.count * 151 % 360) + 120)) }
        return Array(v.prefix(7))
    }
    var body: some View {
        ScreenScroll {
            HStack { Text(T("Cards", "Kartat")).font(.system(size: 34, weight: .bold)).foregroundColor(Brand.text); Spacer() }

            CardFace(last4: bank.card.last4, frozen: bank.card.frozen, revealed: bank.revealed, name: game.name, style: bank.cardStyle, customText: bank.cardText)
                .onTapGesture { withAnimation(.smooth(duration: 0.3)) { bank.revealed.toggle() } }

            AppCard { HStack(spacing: 0) {
                ctrlTile("snowflake", bank.card.frozen ? T("Unfreeze", "Shkrije") : T("Freeze", "Ngrije"), active: bank.card.frozen) { bank.toggleFreeze() }
                ctrlDivider
                ctrlTile(bank.revealed ? "eye.slash" : "eye", bank.revealed ? T("Hide", "Fshih") : T("Details", "Detajet"), active: bank.revealed) { bank.revealed.toggle() }
                ctrlDivider
                ctrlTile("creditcard.fill", T("Apple Pay", "Apple Pay")) { cardFlow = .applePay }
                ctrlDivider
                ctrlTile("slider.horizontal.3", T("Limits", "Limitet")) { cardFlow = .limit }
            } }

            HStack(alignment: .top, spacing: 12) {
                AppCard { VStack(alignment: .leading, spacing: 8) {
                    Text(T("Spent this month", "Këtë muaj")).font(.system(size: 12, weight: .semibold)).foregroundColor(Brand.mute)
                    Spacer(minLength: 0)
                    cardSparkline(cardBars)
                    Text(money(bank.cardSpent)).font(.system(size: 18, weight: .bold)).foregroundColor(Brand.text)
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading) }.frame(height: 132)
                Button { cardFlow = .limit } label: { AppCard { VStack(alignment: .leading, spacing: 8) {
                    Text(T("Monthly limit", "Limiti mujor")).font(.system(size: 12, weight: .semibold)).foregroundColor(Brand.mute)
                    Spacer(minLength: 0)
                    Text(money(bank.cardLimit)).font(.system(size: 18, weight: .bold)).foregroundColor(Brand.text)
                    ProgressBar(value: min(1, bank.cardSpent / bank.cardLimit))
                    Text("\(Int(min(1, bank.cardSpent / bank.cardLimit) * 100))% " + T("used", "përdorur")).font(.system(size: 11)).foregroundColor(Brand.faint)
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading) }.frame(height: 132) }.buttonStyle(PressStyle())
            }

            eyebrow(T("Card controls", "Kontrollet e kartës"))
            AppCard { VStack(spacing: 0) {
                toggleRow(T("Online payments", "Pagesa online"), "globe", $bank.card.online)
                Divider().background(Brand.hairline)
                toggleRow(T("Contactless", "Pa kontakt"), "wave.3.right", $bank.card.contactless)
                Divider().background(Brand.hairline)
                toggleRow(T("ATM withdrawals", "Tërheqje ATM"), "banknote", $bank.card.atm)
            } }

            eyebrow(T("Virtual card", "Kartë virtuale"))
            if let v = bank.virtualCard {
                CardFace(last4: v.last4, frozen: v.frozen, revealed: bank.virtualRevealed, name: game.name, style: .midnight, label: T("Virtual", "Virtuale"))
                    .onTapGesture { withAnimation(.smooth(duration: 0.3)) { bank.virtualRevealed.toggle() } }
                HStack(spacing: 10) {
                    PillButton(title: v.frozen ? T("Unfreeze", "Shkrije") : T("Freeze", "Ngrije"), system: "snowflake", style: .soft) { bank.toggleVirtualFreeze() }
                    PillButton(title: T("Delete", "Fshi"), system: "trash", style: .soft) { withAnimation { bank.deleteVirtualCard() } }
                    Spacer()
                }
            } else {
                Button { withAnimation { bank.createVirtualCard() } } label: { AppCard { HStack(spacing: 14) { IconTile(system: "plus.rectangle.on.rectangle", color: Brand.violet, size: 44); VStack(alignment: .leading, spacing: 2) { Text(T("Create a virtual card", "Krijo kartë virtuale")).font(.system(size: 16, weight: .semibold)).foregroundColor(Brand.text); Text(T("Safer online shopping, freeze anytime", "Më e sigurt online, ngrije kurdo")).font(.system(size: 12)).foregroundColor(Brand.mute) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(Brand.faint) } } }.buttonStyle(PressStyle())
            }

            eyebrow(T("Manage", "Menaxho"))
            Button { cardFlow = .order } label: { AppCard { HStack(spacing: 12) { IconTile(system: "creditcard.and.123"); VStack(alignment: .leading, spacing: 2) { Text(T("Order a physical card", "Porosit kartë fizike")).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text); Text(T("Free delivery in 5-7 days", "Dërgesë falas brenda 5-7 ditëve")).font(.system(size: 12)).foregroundColor(Brand.mute) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(Brand.faint) } } }.buttonStyle(PressStyle())
            Button { cardFlow = .studio } label: { AppCard { HStack(spacing: 12) { IconTile(system: "paintbrush.fill", color: Brand.violet); VStack(alignment: .leading, spacing: 2) { Text(T("Personalise your card", "Personalizo kartën")).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text); Text(T("Colours and your own text", "Ngjyra dhe teksti yt")).font(.system(size: 12)).foregroundColor(Brand.mute) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(Brand.faint) } } }.buttonStyle(PressStyle())
        }
        .sheet(item: $cardFlow) { f in
            switch f {
            case .order: OrderCardSheet()
            case .studio: CardStudioSheet()
            case .applePay: ApplePaySheet()
            case .limit: CardLimitSheet()
            }
        }
    }
    var ctrlDivider: some View { Rectangle().fill(Brand.hairline).frame(width: 1, height: 34) }
    func ctrlTile(_ icon: String, _ label: String, active: Bool = false, _ action: @escaping () -> Void) -> some View {
        Button(action: action) { VStack(spacing: 7) {
            Image(systemName: icon).font(.system(size: 17, weight: .semibold)).foregroundColor(active ? .black : Brand.text).frame(width: 44, height: 44).background(active ? AnyShapeStyle(Brand.yellow) : AnyShapeStyle(Brand.elev3)).clipShape(RoundedRectangle(cornerRadius: 13))
            Text(label).font(.system(size: 11, weight: .medium)).foregroundColor(Brand.mute).lineLimit(1).minimumScaleFactor(0.75)
        } }.buttonStyle(PressStyle()).frame(maxWidth: .infinity)
    }
    func cardSparkline(_ vals: [Double]) -> some View {
        let mx = vals.max() ?? 1
        return HStack(alignment: .bottom, spacing: 4) { ForEach(Array(vals.enumerated()), id: \.offset) { _, v in Capsule().fill(Brand.yellow.opacity(0.8)).frame(height: max(4, 28 * CGFloat(pow(v / mx, 0.55)))) } }.frame(height: 28, alignment: .bottom).frame(maxWidth: .infinity, alignment: .leading)
    }
    func toggleRow(_ t: String, _ icon: String, _ v: Binding<Bool>) -> some View { HStack { Image(systemName: icon).foregroundColor(Brand.mute).frame(width: 28); Text(t).font(.system(size: 15)).foregroundColor(Brand.text); Spacer(); Toggle("", isOn: v).labelsHidden().tint(Brand.yellow) }.padding(.vertical, 6) }
}

// MARK: - Savings (goals)
struct GrowView: View {
    @EnvironmentObject var bank: BankModel
    @AppStorage("ryze_lang") private var lang = "en"
    enum GrowSheet: Identifiable { case fund(String), exchange, newGoal; var id: String { switch self { case .fund(let g): return "fund-\(g)"; case .exchange: return "exchange"; case .newGoal: return "new" } } }
    @State private var growSheet: GrowSheet? = nil
    var body: some View {
        NavigationStack {
            ScreenScroll {
                FeaturedCard { VStack(alignment: .leading, spacing: 4) {
                    Text(T("TOTAL SAVED", "TOTAL I KURSYER")).font(.system(size: 12, weight: .semibold)).tracking(1).foregroundColor(.black.opacity(0.55))
                    Text(money(bank.savedTotal)).font(.system(size: 40, weight: .bold)).foregroundColor(.black).contentTransition(.numericText()).animation(.snappy, value: bank.savedTotal)
                    Text(T("Across \(bank.goals.count) goals", "Në \(bank.goals.count) synime")).font(.system(size: 14)).foregroundColor(.black.opacity(0.7))
                } }
                Button { growSheet = .newGoal } label: { AppCard { HStack(spacing: 14) {
                    IconTile(system: "plus", color: Brand.text, size: 44)
                    VStack(alignment: .leading, spacing: 2) { Text(T("New savings goal", "Synim i ri kursimi")).font(.system(size: 16, weight: .semibold)).foregroundColor(Brand.text); Text(T("Save toward something you want", "Kurse për diçka që dëshiron")).font(.system(size: 12)).foregroundColor(Brand.mute) }
                    Spacer(); Image(systemName: "chevron.right").foregroundColor(Brand.faint).font(.system(size: 13))
                } } }.buttonStyle(PressStyle())
                if !bank.goals.isEmpty { eyebrow(T("Your goals", "Synimet e tua")) }
                ForEach(bank.goals) { g in NavigationLink(value: g.id) { goalRow(g) }.buttonStyle(.plain) }
                Button { growSheet = .exchange } label: { AppCard { HStack(spacing: 12) { IconTile(system: "arrow.left.arrow.right", color: Brand.mint); VStack(alignment: .leading, spacing: 2) { Text(T("Convert currency", "Këmbe valutë")).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text); Text(T("Move between ALL and EUR", "Lëviz mes ALL dhe EUR")).font(.system(size: 12)).foregroundColor(Brand.mute) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(Brand.faint) } } }.buttonStyle(PressStyle())
            }
            .navigationTitle(T("Savings", "Kursime")).navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Brand.bg, for: .navigationBar)
            .navigationDestination(for: String.self) { gid in GoalDetailView(goalId: gid) }
        }
        .sheet(item: $growSheet) { s in
            switch s {
            case .fund(let gid): AmountSheet(mode: .fund, goalName: bank.goals.first { $0.id == gid }?.name) { amt, _ in bank.fundGoal(gid, amt) }.presentationDetents([.medium])
            case .exchange: ExchangeView()
            case .newGoal: AddGoalSheet()
            }
        }
    }
    func goalRow(_ g: Goal) -> some View {
        AppCard { HStack(spacing: 16) {
            Ring(v: g.saved / g.target, size: 54).overlay(Image(systemName: g.icon).font(.system(size: 18)).foregroundColor(Brand.yellow))
            VStack(alignment: .leading, spacing: 3) {
                Text(g.name).font(.system(size: 16, weight: .semibold)).foregroundColor(Brand.text)
                Text("\(money(g.saved)) " + T("of", "nga") + " \(money(g.target))").font(.system(size: 13)).foregroundColor(Brand.mute)
                if g.roundup { HStack(spacing: 4) { Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 10)); Text(T("Round-ups on", "Rrumbullakimi aktiv")) }.font(.system(size: 11, weight: .semibold)).foregroundColor(Brand.good) }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) { Text("\(Int(g.saved / g.target * 100))%").font(.system(size: 15, weight: .bold)).foregroundColor(Brand.text); Image(systemName: "chevron.right").foregroundColor(Brand.faint).font(.system(size: 13)) }
        } }
    }
}
