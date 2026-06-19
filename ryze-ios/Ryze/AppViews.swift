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
        .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
        .shadow(color: .black.opacity(0.4), radius: 22, y: 14) } }
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
    var bg: Color { style == .primary ? Brand.text : style == .dark ? .black : Brand.surface }; var fg: Color { style == .primary ? .black : style == .dark ? .white : Brand.text } }
struct IconTile: View { let system: String; var color: Color = Brand.yellow; var size: CGFloat = 44
    var body: some View { Image(systemName: system).font(.system(size: size * 0.42, weight: .semibold)).symbolRenderingMode(.hierarchical).foregroundColor(color).frame(width: size, height: size).background(color.opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: 13)) } }
struct Avatar: View { let name: String; var size: CGFloat = 40; var you = false
    var body: some View { Text(String(name.prefix(1)).uppercased()).font(.system(size: size * 0.4, weight: .bold)).foregroundColor(you ? .black : Brand.text).frame(width: size, height: size).background(you ? Brand.yellow : Brand.surface).overlay(Circle().stroke(you ? Brand.yellow : Brand.hairline, lineWidth: 1)).clipShape(Circle()) } }
struct Bar: View { var v: Double; var body: some View { ProgressBar(value: v) } }
struct Ring: View { var v: Double; var size: CGFloat = 52
    var body: some View { ZStack { Circle().stroke(Brand.hairline, lineWidth: 5); Circle().trim(from: 0, to: max(0.02, min(1, v))).stroke(Brand.yellow, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90)) }.frame(width: size, height: size) } }
private func eyebrow(_ s: String) -> some View { HStack(spacing: 7) { Capsule().fill(Brand.yellow).frame(width: 14, height: 2); Text(s.uppercased()).font(.system(size: 11, weight: .semibold)).tracking(1.4).foregroundColor(Brand.faint) } }
struct ScreenScroll<C: View>: View {
    @ViewBuilder var content: C
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 16) { content }
                .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 140)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Brand.bg.ignoresSafeArea())
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
                HStack(spacing: 12) { Text("+\(m.xp) XP").font(.system(size: 12, weight: .medium)).foregroundColor(Brand.good); Text("+\(m.coins) coins").font(.system(size: 12, weight: .medium)).foregroundColor(Brand.yellow) } }
            Spacer()
            if m.claimed { HStack(spacing: 4) { Image(systemName: "checkmark.seal.fill").foregroundColor(Brand.good); Text("Done").font(.system(size: 13, weight: .semibold)).foregroundColor(Brand.mute) } }
            else if m.progress >= m.target { PillButton(title: "Claim") { game.claim(m.id) } }
            else { PillButton(title: m.target > 1 ? "+1" : "Start", style: .soft) { game.progress(m.id, by: m.target > 1 ? 1 : m.target) } } }
        if m.target > 1 && !m.claimed { VStack(alignment: .leading, spacing: 5) { Bar(v: Double(m.progress) / Double(m.target)); Text("\(m.progress)/\(m.target)").font(.system(size: 11)).foregroundColor(Brand.faint) } } } } }
}

// MARK: - Amount sheet (send / request / add / fund)
struct AmountSheet: View {
    enum Mode { case send, request, add, fund }
    let mode: Mode; var contact: Contact? = nil; var goalName: String? = nil; let onConfirm: (Double, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""; @State private var note = ""
    var title: String { switch mode { case .send: "Send money"; case .request: "Request money"; case .add: "Add money"; case .fund: "Add to goal" } }
    var cta: String { switch mode { case .send: "Send"; case .request: "Request"; case .add: "Add money"; case .fund: "Save" } }
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
                TextField("", text: $note, prompt: Text("Add a note 💬").foregroundColor(Brand.faint)).foregroundColor(Brand.text).multilineTextAlignment(.center).padding().frame(height: 50).frame(maxWidth: .infinity).background(Brand.surface).clipShape(RoundedRectangle(cornerRadius: 12))
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
    @State private var sel = Int(ProcessInfo.processInfo.environment["RYZE_TAB"] ?? "0") ?? 0
    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $sel) {
                HomeView(sel: $sel).tag(0).tabItem { Label("Home", systemImage: "house.fill") }
                CardsView().tag(1).tabItem { Label("Cards", systemImage: "creditcard.fill") }
                PayView().tag(2).tabItem { Label("Pay", systemImage: "paperplane.fill") }
                AssistantView().tag(3).tabItem { Label("Assistant", systemImage: "sparkles") }
                RewardsHub().tag(4).tabItem { Label("Rewards", systemImage: "gift.fill") }
            }.tint(Brand.yellow)
            CelebrationOverlay(trigger: game.celebrate).ignoresSafeArea()
            if let t = game.toast { ToastBanner(toast: t).padding(.top, 6).transition(.move(edge: .top).combined(with: .opacity)) }
        }
        .animation(.spring(response: 0.4), value: game.toast)
        .sensoryFeedback(.success, trigger: game.celebrate)
    }
}

// MARK: - Home (balance-first)
struct HomeView: View {
    @EnvironmentObject var game: GameModel
    @EnvironmentObject var bank: BankModel
    @Binding var sel: Int
    @State private var rizNudge = true
    enum HSheet: Int, Identifiable { case add, profile, grow; var id: Int { rawValue } }
    @State private var homeSheet: HSheet? = nil
    var nearestGoal: Goal? { bank.goals.min { ($0.saved / $0.target) > ($1.saved / $1.target) } }
    var body: some View {
        ScreenScroll {
            TopBar(name: game.name, onProfile: { homeSheet = .profile }, onAnalytics: { homeSheet = .grow })
            // Total balance hero — signature void surface + gold glow + odometer digits
            VStack(alignment: .leading, spacing: 8) {
                HStack { eyebrow("Total balance"); Spacer(); Button { withAnimation(.smooth(duration: 0.35)) { bank.hideBalance.toggle() } } label: { Image(systemName: bank.hideBalance ? "eye.slash" : "eye").foregroundColor(Brand.mute).font(.system(size: 15)).symbolEffect(.bounce, value: bank.hideBalance) } }
                ZStack(alignment: .leading) {
                    Text(money(bank.totalALL)).font(.system(size: 46, weight: .bold, design: .rounded)).foregroundStyle(LinearGradient(colors: [.white, Color.white.opacity(0.78)], startPoint: .top, endPoint: .bottom)).contentTransition(.numericText()).blur(radius: bank.hideBalance ? 16 : 0).opacity(bank.hideBalance ? 0 : 1)
                    if bank.hideBalance { Text("•• ••• L").font(.system(size: 46, weight: .bold, design: .rounded)).foregroundColor(Brand.text) }
                }
                Text(bank.hideBalance ? " " : "\(money(bank.accounts[1].balance, "EUR")) · \(money(bank.savedTotal)) saved").font(.system(size: 14)).foregroundColor(Brand.mute)
            }
            .padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(ZStack {
                RoundedRectangle(cornerRadius: 24).fill(Brand.void)
                RoundedRectangle(cornerRadius: 24).fill(RadialGradient(colors: [Color(hex: 0xF2C200).opacity(0.13), .clear], center: .topLeading, startRadius: 8, endRadius: 280))
            })
            .specularBorder(24).clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.5), radius: 20, y: 12)
            .animation(.snappy(duration: 0.5), value: bank.totalALL)
            // Account chips
            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 10) {
                ForEach(bank.accounts) { a in HStack(spacing: 8) { Image(systemName: a.icon).foregroundColor(Brand.yellow); VStack(alignment: .leading, spacing: 1) { Text(a.name).font(.system(size: 12)).foregroundColor(Brand.mute); Text(bank.hideBalance ? "•••" : money(a.balance, a.currency)).font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.text) } }.padding(.horizontal, 14).frame(height: 56).background(Brand.surface).overlay(RoundedRectangle(cornerRadius: 14).stroke(Brand.hairline, lineWidth: 1)).clipShape(RoundedRectangle(cornerRadius: 14)) }
                Button { homeSheet = .grow } label: { HStack(spacing: 6) { Image(systemName: "plus"); Text("Savings") }.font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.mute).padding(.horizontal, 16).frame(height: 56).overlay(RoundedRectangle(cornerRadius: 14).stroke(Brand.hairline, lineWidth: 1)) }
            } }
            // Quick actions
            HStack(spacing: 4) {
                QuickAction(icon: "plus", label: "Add", prominent: true) { homeSheet = .add }
                QuickAction(icon: "paperplane.fill", label: "Send") { sel = 2 }
                QuickAction(icon: "arrow.down.left", label: "Request") { sel = 2 }
                QuickAction(icon: "arrow.left.arrow.right", label: "Exchange") { homeSheet = .grow }
                QuickAction(icon: "ellipsis", label: "More") { sel = 4 }
            }
            // Gamification strip (slim)
            Button { sel = 4 } label: { AppCard { HStack(spacing: 14) {
                ZStack { Ring(v: game.li.progress, size: 44); Text("\(game.li.level)").font(.system(size: 15, weight: .bold)).foregroundColor(Brand.text) }
                VStack(alignment: .leading, spacing: 2) { Text("\(game.tier.name) · Level \(game.li.level)").font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.text); Text("\(game.coins) coins · \(game.li.needed - game.li.intoLevel) XP to level up").font(.system(size: 12)).foregroundColor(Brand.mute) }
                Spacer(); Image(systemName: "chevron.right").foregroundColor(Brand.faint).font(.system(size: 13))
            } } }.buttonStyle(.plain)
            // Grow snapshot
            if let g = nearestGoal { Button { homeSheet = .grow } label: { AppCard { HStack(spacing: 14) { Ring(v: g.saved / g.target, size: 46).overlay(Image(systemName: g.icon).font(.system(size: 16)).foregroundColor(Brand.yellow)); VStack(alignment: .leading, spacing: 2) { Text("Saving for \(g.name)").font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.text); Text("\(money(g.saved)) of \(money(g.target))").font(.system(size: 12)).foregroundColor(Brand.mute) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(Brand.faint).font(.system(size: 13)) } } }.buttonStyle(.plain) }
            // Riz nudge
            if rizNudge { AppCard { HStack(spacing: 12) { IconTile(system: "sparkles", size: 40); VStack(alignment: .leading, spacing: 2) { Text("Riz").font(.system(size: 13, weight: .semibold)).foregroundColor(Brand.yellow); Text("You spent 20% more on eating out this week. Want to set a budget?").font(.system(size: 13)).foregroundColor(Brand.mute) }; Spacer(); Button { rizNudge = false } label: { Image(systemName: "xmark").foregroundColor(Brand.faint).font(.system(size: 12)) } } } }
            // Transactions
            HStack { eyebrow("Transactions"); Spacer(); Image(systemName: "magnifyingglass").foregroundColor(Brand.mute).font(.system(size: 13)) }
            VStack(spacing: 0) { ForEach(Array(bank.transactions.prefix(7))) { t in
                HStack(spacing: 12) { IconTile(system: t.icon, color: t.amount > 0 ? Brand.good : Brand.text, size: 40)
                    VStack(alignment: .leading, spacing: 2) { Text(t.merchant).font(.system(size: 15, weight: .medium)).foregroundColor(Brand.text); Text("\(t.category) · \(t.day)").font(.system(size: 12)).foregroundColor(Brand.faint) }
                    Spacer(); Text("\(t.amount > 0 ? "+" : "-")\(money(t.amount, t.currency))").font(.system(size: 15, weight: .semibold)).foregroundColor(t.amount > 0 ? Brand.good : Brand.text) }.padding(.vertical, 11)
            } }
        }
        .sheet(item: $homeSheet) { s in
            switch s {
            case .add: AmountSheet(mode: .add) { amt, _ in bank.addMoney(amt) }.presentationDetents([.medium])
            case .profile: ProfileSheet()
            case .grow: GrowView()
            }
        }
    }
}

// MARK: - Pay hub + chat threads
struct PayView: View {
    @EnvironmentObject var bank: BankModel
    @State private var showAdd = false
    @State private var path: [String] = (ProcessInfo.processInfo.environment["RYZE_THREAD"].map { [$0] }) ?? []
    var pending: [(Contact, PayMsg)] { bank.contacts.compactMap { c in if let m = bank.threads[c.id]?.last, m.kind == .request, !m.fromMe, m.status == "pending" { return (c, m) }; return nil } }
    var body: some View {
        NavigationStack(path: $path) {
            ScreenScroll {
                Text("Pay").font(.system(size: 34, weight: .bold)).foregroundColor(Brand.text)
                HStack(spacing: 4) {
                    QuickAction(icon: "plus", label: "Add", prominent: true) { showAdd = true }
                    QuickAction(icon: "qrcode", label: "Scan") {}
                    QuickAction(icon: "building.columns.fill", label: "Bank") {}
                    QuickAction(icon: "person.2.fill", label: "Split") {}
                }
                if !pending.isEmpty {
                    eyebrow("Requests")
                    ForEach(pending, id: \.0.id) { c, m in AppCard { HStack(spacing: 12) { Avatar(name: c.name, size: 40); VStack(alignment: .leading, spacing: 2) { Text(c.name).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text); Text("asks \(money(m.amount)) · \(m.note)").font(.system(size: 12)).foregroundColor(Brand.mute) }; Spacer(); PillButton(title: "Pay") { bank.payRequest(c.id, m.id) } } } }
                }
                eyebrow("Frequent")
                ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 16) { ForEach(bank.contacts) { c in NavigationLink(value: c.id) { VStack(spacing: 6) { Avatar(name: c.name, size: 54); Text(c.name.split(separator: " ").first.map(String.init) ?? c.name).font(.system(size: 12)).foregroundColor(Brand.mute) } } } } }
                eyebrow("All contacts")
                VStack(spacing: 0) { ForEach(bank.contacts) { c in NavigationLink(value: c.id) { HStack(spacing: 12) { Avatar(name: c.name, size: 44); VStack(alignment: .leading, spacing: 2) { Text(c.name).font(.system(size: 15, weight: .medium)).foregroundColor(Brand.text); Text(c.tag + " · on Ryze").font(.system(size: 12)).foregroundColor(Brand.faint) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(Brand.faint).font(.system(size: 13)) }.padding(.vertical, 10) } } }
            }
            .navigationDestination(for: String.self) { id in if let c = bank.contacts.first(where: { $0.id == id }) { ChatThreadView(contact: c) } }
            .sheet(isPresented: $showAdd) { AmountSheet(mode: .add) { amt, _ in bank.addMoney(amt) }.presentationDetents([.medium]) }
        }
    }
}

struct ChatThreadView: View {
    @EnvironmentObject var bank: BankModel
    let contact: Contact
    @State private var text = ""
    @State private var sheet: AmountSheet.Mode? = nil
    var msgs: [PayMsg] { bank.threads[contact.id] ?? [] }
    var body: some View {
        ZStack { Brand.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView { VStack(spacing: 10) { ForEach(msgs) { m in bubble(m) } }.padding(16) }
                HStack(spacing: 8) {
                    Menu { Button("Send money") { sheet = .send }; Button("Request money") { sheet = .request } } label: { Image(systemName: "plus").font(.system(size: 18, weight: .bold)).foregroundColor(.black).frame(width: 40, height: 40).background(Brand.yellow).clipShape(Circle()) }
                    TextField("", text: $text, prompt: Text("Message").foregroundColor(Brand.faint)).foregroundColor(Brand.text).padding(.horizontal, 14).frame(height: 40).background(Brand.surface).overlay(Capsule().stroke(Brand.hairline, lineWidth: 1)).clipShape(Capsule())
                    Button { let t = text.trimmingCharacters(in: .whitespaces); if !t.isEmpty { bank.sendText(contact.id, t); text = "" } } label: { Image(systemName: "arrow.up").font(.system(size: 16, weight: .bold)).foregroundColor(.black).frame(width: 40, height: 40).background(Brand.text).clipShape(Circle()) }
                }.padding(12)
            }
        }
        .navigationTitle(contact.name).navigationBarTitleDisplayMode(.inline)
        .sheet(item: Binding(get: { sheet.map { SheetWrap(mode: $0) } }, set: { sheet = $0?.mode })) { w in
            AmountSheet(mode: w.mode, contact: contact) { amt, note in if w.mode == .send { bank.send(to: contact, amount: amt, note: note) } else { bank.request(from: contact, amount: amt, note: note) } }.presentationDetents([.large])
        }
    }
    struct SheetWrap: Identifiable { let mode: AmountSheet.Mode; var id: Int { mode == .send ? 0 : 1 } }
    @ViewBuilder func bubble(_ m: PayMsg) -> some View {
        HStack { if m.fromMe { Spacer(minLength: 40) }
            if m.kind == .text {
                Text(m.text).font(.system(size: 15)).foregroundColor(m.fromMe ? .black : Brand.text).padding(.vertical, 9).padding(.horizontal, 13).background(m.fromMe ? Brand.text : Brand.surface).clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) { Image(systemName: m.kind == .send ? "paperplane.fill" : "arrow.down.left").font(.system(size: 13, weight: .bold)).foregroundColor(.black); Text(m.kind == .send ? "Sent" : "Request").font(.system(size: 12, weight: .bold)).foregroundColor(.black.opacity(0.7)) }
                    Text(money(m.amount)).font(.system(size: 22, weight: .bold)).foregroundColor(.black)
                    if !m.note.isEmpty { Text(m.note).font(.system(size: 13)).foregroundColor(.black.opacity(0.75)) }
                    Text(m.status.capitalized).font(.system(size: 11, weight: .semibold)).foregroundColor(.black.opacity(0.55))
                    if m.kind == .request && !m.fromMe && m.status == "pending" { PillButton(title: "Pay \(money(m.amount))", style: .dark) { bank.payRequest(contact.id, m.id) } }
                }.padding(14).frame(width: 220, alignment: .leading).background(Brand.yellow).clipShape(RoundedRectangle(cornerRadius: 18))
            }
            if !m.fromMe { Spacer(minLength: 40) } }
    }
}

// MARK: - Cards
struct CardsView: View {
    @EnvironmentObject var bank: BankModel
    var body: some View {
        ScreenScroll {
            Text("Cards").font(.system(size: 34, weight: .bold)).foregroundColor(Brand.text)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 22).fill(LinearGradient(colors: [Brand.yellow, Color(hex: 0xFFB020)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(height: 200)
                VStack(alignment: .leading) {
                    HStack { Image("RaiffeisenLogo").resizable().frame(width: 34, height: 34).clipShape(RoundedRectangle(cornerRadius: 9)); Spacer(); Text("Debit Premium").font(.system(size: 13, weight: .semibold)).foregroundColor(.black.opacity(0.7)) }
                    Spacer()
                    Text(bank.revealed ? "4827  2156  9043  1124" : "••••  ••••  ••••  \(bank.card.last4)").font(.system(size: 20, weight: .semibold, design: .monospaced)).foregroundColor(.black)
                    HStack { Text("RYZE").font(.system(size: 13, weight: .bold)).foregroundColor(.black); Spacer(); Text(bank.revealed ? "09/29   CVV 412" : "VISA").font(.system(size: 14, weight: .bold)).foregroundColor(.black) }
                }.padding(20)
                if bank.card.frozen { ZStack { Color.black.opacity(0.45); VStack(spacing: 6) { Image(systemName: "snowflake").font(.system(size: 30)).foregroundColor(.white); Text("Frozen").font(.system(size: 14, weight: .bold)).foregroundColor(.white) } }.clipShape(RoundedRectangle(cornerRadius: 22)).frame(height: 200) }
            }
            HStack(spacing: 10) {
                PillButton(title: bank.card.frozen ? "Unfreeze" : "Freeze", system: "snowflake", style: .soft) { bank.toggleFreeze() }
                PillButton(title: bank.revealed ? "Hide details" : "Show details", system: "eye", style: .soft) { bank.revealed.toggle() }
                Spacer()
            }
            eyebrow("Security")
            AppCard { VStack(spacing: 0) {
                toggleRow("Online payments", "globe", $bank.card.online)
                Divider().background(Brand.hairline)
                toggleRow("Contactless", "wave.3.right", $bank.card.contactless)
                Divider().background(Brand.hairline)
                toggleRow("ATM withdrawals", "banknote", $bank.card.atm)
            } }
            AppCard { HStack(spacing: 12) { IconTile(system: "creditcard.and.123"); VStack(alignment: .leading, spacing: 2) { Text("Order a physical card").font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text); Text("Free delivery in 5–7 days").font(.system(size: 12)).foregroundColor(Brand.mute) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(Brand.faint) } }
            AppCard { HStack(spacing: 12) { IconTile(system: "paintpalette.fill", color: Brand.violet); VStack(alignment: .leading, spacing: 2) { Text("Card skins").font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text); Text("Unlock new designs as you level up").font(.system(size: 12)).foregroundColor(Brand.mute) }; Spacer(); Image(systemName: "lock.fill").foregroundColor(Brand.faint) } }
        }
    }
    func toggleRow(_ t: String, _ icon: String, _ v: Binding<Bool>) -> some View { HStack { Image(systemName: icon).foregroundColor(Brand.mute).frame(width: 28); Text(t).font(.system(size: 15)).foregroundColor(Brand.text); Spacer(); Toggle("", isOn: v).labelsHidden().tint(Brand.yellow) }.padding(.vertical, 6) }
}

// MARK: - Grow
struct GrowView: View {
    @EnvironmentObject var bank: BankModel
    @State private var fundId: String? = nil
    var maxCat: Double { bank.categories.map(\.amount).max() ?? 1 }
    var body: some View {
        ScreenScroll {
            Text("Grow").font(.system(size: 34, weight: .bold)).foregroundColor(Brand.text)
            FeaturedCard { VStack(alignment: .leading, spacing: 4) { Text("TOTAL SAVED").font(.system(size: 12, weight: .semibold)).tracking(1).foregroundColor(.black.opacity(0.55)); Text(money(bank.savedTotal)).font(.system(size: 40, weight: .bold)).foregroundColor(.black); Text("Across \(bank.goals.count) goals").font(.system(size: 14)).foregroundColor(.black.opacity(0.7)) } }
            eyebrow("Goals")
            ForEach(bank.goals) { g in AppCard { HStack(spacing: 16) {
                Ring(v: g.saved / g.target, size: 58).overlay(Image(systemName: g.icon).font(.system(size: 18)).foregroundColor(Brand.yellow))
                VStack(alignment: .leading, spacing: 3) { Text(g.name).font(.system(size: 16, weight: .semibold)).foregroundColor(Brand.text); Text("\(money(g.saved)) of \(money(g.target))").font(.system(size: 13)).foregroundColor(Brand.mute); if g.roundup { Text("Round-ups on").font(.system(size: 11, weight: .semibold)).foregroundColor(Brand.good) } }
                Spacer(); PillButton(title: "Add", style: .soft) { fundId = g.id }
            } } }
            eyebrow("This month’s spending")
            AppCard { VStack(spacing: 12) { ForEach(bank.categories) { c in
                HStack(spacing: 12) { Image(systemName: c.icon).foregroundColor(c.color).frame(width: 24)
                    VStack(alignment: .leading, spacing: 5) { HStack { Text(c.name).font(.system(size: 14)).foregroundColor(Brand.text); Spacer(); Text(money(c.amount)).font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.text) }
                        GeometryReader { gx in ZStack(alignment: .leading) { Capsule().fill(Brand.hairline); Capsule().fill(c.color).frame(width: gx.size.width * (c.amount / maxCat)) } }.frame(height: 6) } }
            } } }
            AppCard { HStack(spacing: 12) { IconTile(system: "arrow.left.arrow.right", color: Brand.mint); VStack(alignment: .leading, spacing: 2) { Text("Exchange ALL ↔ EUR").font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text); Text("Live rate, low fees").font(.system(size: 12)).foregroundColor(Brand.mute) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(Brand.faint) } }
        }
        .sheet(item: Binding(get: { fundId.map { GID(id: $0) } }, set: { fundId = $0?.id })) { g in AmountSheet(mode: .fund, goalName: bank.goals.first { $0.id == g.id }?.name) { amt, _ in bank.fundGoal(g.id, amt) }.presentationDetents([.medium]) }
    }
    struct GID: Identifiable { let id: String }
}

// MARK: - Profile (gamification folded in)
struct ProfileView: View {
    @EnvironmentObject var game: GameModel
    @State private var riz = false
    let cols2 = [GridItem(.flexible()), GridItem(.flexible())]
    let cols3 = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var earned: Int { game.badges.filter { $0.earned }.count }
    var quests: [Mission] { game.missions.filter { !$0.claimed } }
    var board: [LeaderRow] { (GameModel.leaderboard + [LeaderRow(id: "you", name: game.name, xp: game.xp, you: true)]).sorted { $0.xp > $1.xp } }
    var body: some View {
        ScreenScroll {
            VStack(spacing: 8) { Avatar(name: game.name, size: 80); Text(game.name).font(.system(size: 22, weight: .bold)).foregroundColor(Brand.text); Text("@\(game.name.lowercased()) · \(game.tier.name) · Level \(game.li.level)").font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.yellow) }.frame(maxWidth: .infinity).padding(.vertical, 6)
            AppCard { VStack(alignment: .leading, spacing: 10) { Text(game.tier.perk).font(.system(size: 13)).foregroundColor(Brand.mute); Bar(v: game.li.progress); Text("\(game.li.intoLevel)/\(game.li.needed) XP to level \(game.li.level + 1)").font(.system(size: 12)).foregroundColor(Brand.faint) } }
            LazyVGrid(columns: cols3, spacing: 10) { StatCard(value: "\(game.xp)", label: "Total XP"); StatCard(value: "\(game.coins)", label: "Coins"); StatCard(value: "\(game.streak)d", label: "Streak"); StatCard(value: "\(game.invites)", label: "Invites"); StatCard(value: "\(earned)/\(game.badges.count)", label: "Badges"); StatCard(value: "Lv \(game.li.level)", label: game.tier.name) }
            if !quests.isEmpty { eyebrow("Quests — earn from real actions"); ForEach(quests.prefix(4)) { MissionRowView(m: $0) } }
            eyebrow("Badges")
            LazyVGrid(columns: cols2, spacing: 10) { ForEach(game.badges) { b in AppCard { VStack(spacing: 6) { Image(systemName: b.earned ? b.icon : "lock.fill").font(.system(size: 22)).foregroundColor(b.earned ? Brand.yellow : Brand.faint).frame(width: 48, height: 48).background((b.earned ? Brand.yellow : Color.white).opacity(b.earned ? 0.12 : 0.05)).clipShape(Circle()); Text(b.title).font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.text); Text(b.desc).font(.system(size: 11)).foregroundColor(Brand.mute).multilineTextAlignment(.center) }.frame(maxWidth: .infinity) }.opacity(b.earned ? 1 : 0.5) } }
            eyebrow("Rewards store")
            ForEach(GameModel.rewards) { r in let owned = game.redeemed.contains(r.id); let locked = r.tierMin > game.tierIndex; let afford = game.coins >= r.cost
                AppCard { HStack(spacing: 14) { IconTile(system: r.icon); VStack(alignment: .leading, spacing: 2) { Text(r.title).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text); Text(r.brand).font(.system(size: 13)).foregroundColor(Brand.mute) }; Spacer()
                    if owned { Image(systemName: "checkmark.seal.fill").foregroundColor(Brand.good) } else if locked { HStack(spacing: 4) { Image(systemName: "lock.fill"); Text(TIERS[r.tierMin].name) }.font(.system(size: 13, weight: .semibold)).foregroundColor(Brand.faint) } else { PillButton(title: "\(r.cost)", enabled: afford) { game.redeem(r.id) } } } } }
            eyebrow("Invite friends")
            AppCard { HStack(spacing: 12) { IconTile(system: "gift.fill", color: Brand.pink); VStack(alignment: .leading, spacing: 2) { Text(game.referralCode).font(.system(size: 16, weight: .bold)).foregroundColor(Brand.text); Text("You both get 200 coins").font(.system(size: 12)).foregroundColor(Brand.mute) }; Spacer(); ShareLink(item: "Join me on Ryze — use code \(game.referralCode)") { Image(systemName: "square.and.arrow.up").foregroundColor(.black).frame(width: 40, height: 40).background(Brand.yellow).clipShape(Circle()) } } }
            eyebrow("Security & support")
            AppCard { VStack(spacing: 0) {
                row("Passcode & Face ID", "lock.fill"); Divider().background(Brand.hairline)
                row("Notifications", "bell.fill"); Divider().background(Brand.hairline)
                Button { riz = true } label: { row("Ask Riz", "sparkles") }.buttonStyle(.plain); Divider().background(Brand.hairline)
                row("Help & support", "questionmark.circle.fill")
            } }
            Button { game.resetDemo() } label: { Text("Reset demo").font(.system(size: 16, weight: .semibold)).foregroundColor(Brand.text).frame(maxWidth: .infinity).frame(height: 50).overlay(Capsule().stroke(Brand.text, lineWidth: 1)) }
        }
        .sheet(isPresented: $riz) { RizSheet(stepWhy: nil, seed: false).presentationDetents([.large]).presentationBackground(Brand.surface) }
    }
    func row(_ t: String, _ icon: String) -> some View { HStack(spacing: 12) { Image(systemName: icon).foregroundColor(Brand.yellow).frame(width: 26); Text(t).font(.system(size: 15)).foregroundColor(Brand.text); Spacer(); Image(systemName: "chevron.right").foregroundColor(Brand.faint).font(.system(size: 13)) }.padding(.vertical, 12) }
}
