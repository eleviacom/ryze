import SwiftUI
import PhotosUI
import CoreImage.CIFilterBuiltins
import MapKit

// MARK: - Top bar (avatar opens Profile)
struct TopBar: View {
    let name: String
    var imageData: Data? = nil
    var onProfile: () -> Void
    var onAnalytics: () -> Void = {}
    var onSearch: () -> Void = {}
    var onMap: () -> Void = {}
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onProfile) { Avatar(name: name, size: 40, imageData: imageData) }
            Button(action: onSearch) { HStack { Image(systemName: "magnifyingglass").foregroundColor(Brand.mute); Text(T("Search", "Kërko")).foregroundColor(Brand.mute).font(.system(size: 15)); Spacer() }.padding(.horizontal, 14).frame(height: 40).liquidCapsule() }.buttonStyle(.plain)
            Button(action: onAnalytics) { Image(systemName: "chart.bar.fill").foregroundColor(Brand.text).frame(width: 40, height: 40).liquidCircle() }
            Button(action: onMap) { Image(systemName: "map.fill").foregroundColor(Brand.text).frame(width: 40, height: 40).liquidCircle() }
        }
    }
}

// MARK: - Profile (sheet from avatar)
enum ProfileDetail: String, Identifiable, Hashable {
    case personal, account, security, documents, settings, help, inbox
    var id: String { rawValue }
    var title: String {
        switch self {
        case .personal: return "Personal info"; case .account: return "Account details"
        case .security: return "Security & privacy"; case .documents: return "Documents"
        case .settings: return "Settings"; case .help: return "Help"; case .inbox: return "Inbox"
        }
    }
    var icon: String {
        switch self {
        case .personal: return "person.text.rectangle.fill"; case .account: return "building.columns.fill"
        case .security: return "lock.shield.fill"; case .documents: return "doc.text.fill"
        case .settings: return "gearshape.fill"; case .help: return "questionmark.circle.fill"; case .inbox: return "bell.badge.fill"
        }
    }
}

struct AppCardBG: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24).fill(LinearGradient(colors: [Brand.elev2, Brand.elev1], startPoint: .top, endPoint: .bottom)).specularBorder(24)
    }
}

func pdTitle(_ d: ProfileDetail) -> String {
    switch d {
    case .personal: return T("Personal info", "Të dhënat personale")
    case .account: return T("Account details", "Detajet e llogarisë")
    case .security: return T("Security & privacy", "Siguria & privatësia")
    case .documents: return T("Documents", "Dokumentet")
    case .settings: return T("Settings", "Cilësimet")
    case .help: return T("Help", "Ndihmë")
    case .inbox: return T("Inbox", "Mesazhet")
    }
}

struct ProfileSheet: View {
    @EnvironmentObject var game: GameModel
    @EnvironmentObject var bank: BankModel
    @Environment(\.dismiss) private var dismiss
    @State private var showPlans = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showQR = false
    @AppStorage("ryze_lang") private var lang = "en"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    AppCard {
                        VStack(spacing: 16) {
                            HStack(spacing: 14) {
                                PhotosPicker(selection: $photoItem, matching: .images) {
                                    ZStack(alignment: .bottomTrailing) {
                                        ZStack { Circle().stroke(Brand.gold, lineWidth: 2).frame(width: 60, height: 60); Avatar(name: game.name, size: 48, imageData: game.avatarData) }
                                        Image(systemName: "camera.circle.fill").font(.system(size: 18)).foregroundStyle(Brand.text, Brand.elev3).offset(x: 2, y: 2)
                                    }
                                }.buttonStyle(.plain)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(game.name).font(.system(size: 20, weight: .bold)).foregroundColor(Brand.text)
                                    Button { showQR = true } label: { HStack(spacing: 5) { Text("@\(game.name.lowercased())").font(.system(size: 13)).foregroundColor(Brand.mute); Image(systemName: "qrcode").font(.system(size: 13)).foregroundColor(Brand.yellow) } }.buttonStyle(.plain)
                                }
                                Spacer()
                            }
                            HStack(spacing: 0) {
                                miniStat("\(game.li.level)", T("Level", "Niveli")); statDivider()
                                miniStat("\(game.coins)", T("Points", "Pikë")); statDivider()
                                miniStat(game.tier.name, T("Tier", "Rangu"))
                            }
                        }
                    }
                    Button { showPlans = true } label: {
                        FeaturedCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(game.planLabel).font(.system(size: 19, weight: .bold)).foregroundColor(.black)
                                    Text(T("See your plan benefits", "Shiko përfitimet e planit")).font(.system(size: 13)).foregroundColor(.black.opacity(0.7))
                                }
                                Spacer()
                                Image(systemName: "star.circle.fill").foregroundColor(.black.opacity(0.25)).font(.system(size: 30))
                            }
                        }
                    }.buttonStyle(PressStyle())

                    sectionLabel(T("Account", "Llogaria"))
                    AppCard { VStack(spacing: 0) { navRow(.personal); rowDivider(); navRow(.account); rowDivider(); navRow(.security) } }

                    sectionLabel(T("Rewards & sharing", "Shpërblime & ndarje"))
                    AppCard { VStack(spacing: 0) {
                        ShareLink(item: "Join me on Ryze, use code \(game.referralCode) and we both get 200 points.") {
                            HStack(spacing: 14) { IconTile(system: "gift.fill", color: Brand.pink, size: 38); VStack(alignment: .leading, spacing: 1) { Text(T("Invite friends", "Fto miqtë")).font(.system(size: 16, weight: .semibold)).foregroundColor(Brand.text); Text(T("Earn 2,000 points or more", "Fito 2,000 pikë ose më shumë")).font(.system(size: 12)).foregroundColor(Brand.faint) }; Spacer(); Image(systemName: "square.and.arrow.up").foregroundColor(Brand.faint).font(.system(size: 14)) }.padding(.vertical, 12)
                        }.buttonStyle(.plain)
                        rowDivider(); navRow(.inbox, badge: "3")
                    } }

                    sectionLabel(T("More", "Më shumë"))
                    AppCard { VStack(spacing: 0) { navRow(.documents); rowDivider(); navRow(.settings); rowDivider(); navRow(.help) } }

                    Button { game.resetDemo(); dismiss() } label: {
                        HStack(spacing: 14) { IconTile(system: "rectangle.portrait.and.arrow.right", color: Brand.danger, size: 38); Text(T("Log out", "Dil")).font(.system(size: 16, weight: .semibold)).foregroundColor(Brand.danger); Spacer() }.padding(18)
                    }.buttonStyle(PressStyle()).background(AppCardBG()).clipShape(RoundedRectangle(cornerRadius: 24))

                    Text(T("Ryze · prototype for Raiffeisen Bank Albania", "Ryze · prototip për Raiffeisen Bank Albania")).font(.system(size: 11)).foregroundColor(Brand.faint).padding(.top, 2)
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 40)
            }
            .background(Brand.bg.ignoresSafeArea())
            .navigationDestination(for: ProfileDetail.self) { ProfileDetailView(detail: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(Brand.text) } }
                ToolbarItem(placement: .topBarTrailing) { Button { showPlans = true } label: { HStack(spacing: 5) { Image(systemName: "sparkles"); Text(T("Upgrade", "Përmirëso")) }.font(.system(size: 14, weight: .semibold)).foregroundColor(.black).padding(.horizontal, 14).frame(height: 34).background(Brand.gold).clipShape(Capsule()) } }
            }
            .toolbarBackground(Brand.bg, for: .navigationBar)
        }
        .sheet(isPresented: $showPlans) { PlansView() }
        .sheet(isPresented: $showQR) { QRSheet() }
        .onChange(of: photoItem) { _, item in Task { if let d = try? await item?.loadTransferable(type: Data.self) { await MainActor.run { game.avatarData = d } } } }
    }

    func navRow(_ d: ProfileDetail, badge: String? = nil) -> some View {
        NavigationLink(value: d) {
            HStack(spacing: 14) {
                IconTile(system: d.icon, size: 38)
                Text(pdTitle(d)).font(.system(size: 16, weight: .semibold)).foregroundColor(Brand.text)
                Spacer()
                if let b = badge { Text(b).font(.system(size: 12, weight: .bold)).foregroundColor(.black).frame(width: 22, height: 22).background(Brand.yellow).clipShape(Circle()) }
                Image(systemName: "chevron.right").foregroundColor(Brand.faint).font(.system(size: 13))
            }.padding(.vertical, 12)
        }.buttonStyle(.plain)
    }
    func rowDivider() -> some View { Divider().background(Brand.hairline).padding(.leading, 52) }
    func miniStat(_ v: String, _ l: String) -> some View { VStack(spacing: 2) { Text(v).font(.system(size: 17, weight: .bold)).foregroundColor(Brand.text); Text(l).font(.system(size: 11)).foregroundColor(Brand.mute) }.frame(maxWidth: .infinity) }
    func statDivider() -> some View { Rectangle().fill(Brand.hairline).frame(width: 1, height: 26) }
    func sectionLabel(_ t: String) -> some View { Eyebrow(text: t).frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 4) }
}

struct ProfileDetailView: View {
    @EnvironmentObject var game: GameModel
    @EnvironmentObject var bank: BankModel
    let detail: ProfileDetail
    @AppStorage("ryze_app_lock") private var appLock = false
    @State private var ibanShown = false
    @State private var notif = true
    @AppStorage("ryze_appearance") private var appearance = "dark"
    @AppStorage("ryze_lang") private var lang = "en"
    enum DetailSheet: Identifiable { case coming(String), info(String, String), riz; var id: String { switch self { case .coming(let s): return "c-\(s)"; case .info(let t, _): return "i-\(t)"; case .riz: return "riz" } } }
    @State private var dsheet: DetailSheet? = nil
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) { content }.padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 40)
        }
        .background(Brand.bg.ignoresSafeArea())
        .navigationTitle(pdTitle(detail)).navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.bg, for: .navigationBar)
        .sheet(item: $dsheet) { s in
            switch s {
            case .coming(let t): ComingSoonSheet(title: t)
            case .info(let t, let b): InfoTextSheet(title: t, text: b)
            case .riz: RizSheet(stepWhy: nil, seed: false).presentationDetents([.large]).presentationBackground(Brand.surface)
            }
        }
    }
    @ViewBuilder var content: some View {
        switch detail {
        case .personal:
            infoCard([("Full name", game.name), ("Email", "klevi@ryze.al"), ("Phone", "+355 69 123 4567"), ("Date of birth", "14/03/2004"), ("Nationality", "Albania")])
        case .account:
            let iban = "AL47 2026 1100 4827"
            AppCard { VStack(spacing: 0) {
                infoRow("Account", "\(game.name) · Personal"); Divider().background(Brand.hairline)
                HStack { Text("IBAN").font(.system(size: 14)).foregroundColor(Brand.mute); Spacer()
                    Text(ibanShown ? iban : maskIBAN(iban)).font(.system(size: 15, weight: .medium, design: .monospaced)).foregroundColor(Brand.text)
                    Button { withAnimation { ibanShown.toggle() } } label: { Image(systemName: ibanShown ? "eye.slash" : "eye").font(.system(size: 13)).foregroundColor(Brand.mute) }
                    Button { Clip.copySensitive(iban) } label: { Image(systemName: "doc.on.doc").font(.system(size: 13)).foregroundColor(Brand.mute) }
                }.padding(.vertical, 13); Divider().background(Brand.hairline)
                infoRow("Currency", "ALL · EUR"); Divider().background(Brand.hairline)
                infoRow("Opened", "Today"); Divider().background(Brand.hairline)
                infoRow("Status", "Active")
            } }
        case .security:
            Eyebrow(text: "Sign in")
            AppCard { VStack(spacing: 0) { toggleRow(T("App lock (Face ID / passcode)", "Kyçje (Face ID / kod)"), "faceid", $appLock); dv(); stub("Change passcode", "key.fill") } }
            Eyebrow(text: "Privacy")
            AppCard { VStack(spacing: 0) { toggleRow("Hide balance", "eye.slash.fill", $bank.hideBalance); dv(); stub("Trusted devices", "iphone") } }
        case .documents:
            Eyebrow(text: "Statements")
            AppCard { VStack(spacing: 0) { doc("June 2026"); dv(); doc("May 2026"); dv(); doc("April 2026") } }
        case .settings:
            Eyebrow(text: T("Appearance", "Pamja"))
            AppCard { segRow([("system", T("System", "Sistemi")), ("light", T("Light", "E çelët")), ("dark", T("Dark", "E errët"))], $appearance) }
            Eyebrow(text: T("Language", "Gjuha"))
            AppCard { segRow([("en", "English"), ("sq", "Shqip")], $lang) }
            AppCard { VStack(spacing: 0) { toggleRow(T("Notifications", "Njoftime"), "bell.fill", $notif); dv(); actionStub(T("About Ryze", "Rreth Ryze"), "info.circle.fill") { dsheet = .info(T("About Ryze", "Rreth Ryze"), Legal.disclaimer) }; dv(); actionStub(T("Terms & privacy", "Kushtet & privatësia"), "doc.text.fill") { dsheet = .info(T("Terms & privacy", "Kushtet & privatësia"), Legal.infoNotice) } } }
        case .help:
            AppCard { VStack(spacing: 0) { stub("FAQs", "questionmark.circle.fill"); dv(); stub("Contact support", "bubble.left.and.bubble.right.fill"); dv(); actionStub(T("Ask Riz", "Pyet Riz"), "sparkles") { dsheet = .riz } } }
        case .inbox:
            Eyebrow(text: "Notifications")
            AppCard { VStack(spacing: 0) { msg("Account opened", "Welcome to Ryze, your account is live.", "now"); dv(); msg("Security", "New sign-in to your account.", "1h"); dv(); msg("Rewards", "You earned 50 points this week.", "2d") } }
        }
    }
    func infoCard(_ rows: [(String, String)]) -> some View {
        AppCard { VStack(spacing: 0) { ForEach(Array(rows.enumerated()), id: \.offset) { i, r in
            HStack { Text(r.0).font(.system(size: 14)).foregroundColor(Brand.mute); Spacer(); Text(r.1).font(.system(size: 15, weight: .medium)).foregroundColor(Brand.text) }.padding(.vertical, 13)
            if i < rows.count - 1 { Divider().background(Brand.hairline) }
        } } }
    }
    func infoRow(_ l: String, _ v: String) -> some View { HStack { Text(l).font(.system(size: 14)).foregroundColor(Brand.mute); Spacer(); Text(v).font(.system(size: 15, weight: .medium)).foregroundColor(Brand.text) }.padding(.vertical, 13) }
    private func maskIBAN(_ s: String) -> String { let t = s.replacingOccurrences(of: " ", with: ""); guard t.count > 8 else { return s }; return "\(t.prefix(4)) •••• •••• \(t.suffix(4))" }
    func toggleRow(_ t: String, _ icon: String, _ b: Binding<Bool>) -> some View { HStack(spacing: 14) { IconTile(system: icon, size: 38); Text(t).font(.system(size: 16)).foregroundColor(Brand.text); Spacer(); Toggle("", isOn: b).labelsHidden().tint(Brand.yellow) }.padding(.vertical, 8) }
    func stub(_ t: String, _ icon: String) -> some View { Button { dsheet = .coming(t) } label: { HStack(spacing: 14) { IconTile(system: icon, size: 38); Text(t).font(.system(size: 16)).foregroundColor(Brand.text); Spacer(); Image(systemName: "chevron.right").foregroundColor(Brand.faint).font(.system(size: 13)) }.padding(.vertical, 12) }.buttonStyle(.plain) }
    func actionStub(_ t: String, _ icon: String, _ action: @escaping () -> Void) -> some View { Button(action: action) { HStack(spacing: 14) { IconTile(system: icon, size: 38); Text(t).font(.system(size: 16)).foregroundColor(Brand.text); Spacer(); Image(systemName: "chevron.right").foregroundColor(Brand.faint).font(.system(size: 13)) }.padding(.vertical, 12) }.buttonStyle(.plain) }
    func doc(_ m: String) -> some View { Button { dsheet = .coming(m + " " + T("statement", "pasqyrë")) } label: { HStack(spacing: 14) { IconTile(system: "doc.text.fill", size: 38); Text(m).font(.system(size: 16)).foregroundColor(Brand.text); Spacer(); Image(systemName: "arrow.down.circle").foregroundColor(Brand.yellow).font(.system(size: 18)) }.padding(.vertical, 12) }.buttonStyle(.plain) }
    func msg(_ t: String, _ s: String, _ time: String) -> some View { HStack(spacing: 14) { IconTile(system: "bell.fill", size: 38); VStack(alignment: .leading, spacing: 2) { Text(t).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text); Text(s).font(.system(size: 13)).foregroundColor(Brand.mute) }; Spacer(); Text(time).font(.system(size: 11)).foregroundColor(Brand.faint) }.padding(.vertical, 11) }
    func dv() -> some View { Divider().background(Brand.hairline).padding(.leading, 52) }
}

// MARK: - Assistant (Riz, full tab, premium AI copilot)
struct RizOrb: View {
    var size: CGFloat = 44
    var glow: Bool = true
    @State private var pulse = false
    var body: some View {
        Image("RaiffeisenLogo").resizable().scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            .background(Circle().fill(RadialGradient(colors: [Brand.yellow.opacity(glow ? 0.42 : 0), .clear], center: .center, startRadius: 2, endRadius: size)).frame(width: size * 2.1, height: size * 2.1).scaleEffect(pulse ? 1.06 : 0.92))
            .shadow(color: Brand.yellow.opacity(glow ? 0.35 : 0), radius: glow ? 16 : 0, y: 5)
        .onAppear { if glow { withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { pulse = true } } }
    }
}

struct TypingDots: View {
    @State private var on = false
    var body: some View {
        HStack(spacing: 5) { ForEach(0..<3, id: \.self) { idx in
            Circle().fill(Brand.mute).frame(width: 7, height: 7).scaleEffect(on ? 1 : 0.5).opacity(on ? 1 : 0.4)
                .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(idx) * 0.15), value: on)
        } }.onAppear { on = true }
    }
}

struct AssistantView: View {
    @EnvironmentObject var game: GameModel
    @EnvironmentObject var bank: BankModel
    @AppStorage("ryze_lang") private var lang = "en"
    @State private var msgs: [RizMessage] = ProcessInfo.processInfo.environment["RYZE_RIZ"] != nil ? [RizMessage(fromUser: true, text: "How am I spending this month?"), RizMessage(fromUser: false, text: "You've spent 16,500 L this month, mostly on eating out (6,400 L). That's ~20% more than last week. Want me to set a weekly cap so you stay on track?")] : []
    @State private var input = ""
    @State private var typing = false
    @State private var didAsk = false
    var caps: [(String, String, String)] {
        [("chart.pie.fill", T("My spending", "Shpenzimet e mia"), T("How am I spending this month?", "Si po shpenzoj këtë muaj?")),
         ("star.circle.fill", T("RyzePoints", "RyzePikë"), T("How do RyzePoints work?", "Si funksionojnë RyzePikët?")),
         ("crown.fill", T("Best plan for me", "Plani më i mirë"), T("Which plan fits me best?", "Cili plan më përshtatet?")),
         ("lock.shield.fill", T("Is my money safe?", "A janë të sigurta?"), T("Is my money safe with Ryze?", "A janë të sigurta paratë me Ryze?"))]
    }
    func send(_ t: String) {
        let q = t.trimmingCharacters(in: .whitespaces); guard !q.isEmpty else { return }
        input = ""
        withAnimation(.snappy) { msgs.append(RizMessage(fromUser: true, text: q)) }
        typing = true
        let history = msgs
        let ctx = rizContext()
        Task {
            let live = await RizService.reply(history: history, context: ctx)
            await MainActor.run {
                typing = false
                let reply = live ?? Riz.reply(stepWhy: nil, text: q)
                withAnimation(.snappy) { msgs.append(RizMessage(fromUser: false, text: reply)) }
            }
        }
    }
    func rizContext() -> String {
        let cats = bank.categories.map { "\($0.name) \(money($0.amount))" }.joined(separator: ", ")
        let goals = bank.goals.map { "\($0.name) \(Int($0.saved / $0.target * 100))% (\(money($0.saved)) of \(money($0.target)))" }.joined(separator: ", ")
        return """
        Reply language: \(T("English", "Albanian (Shqip)"))
        Name: \(game.name)
        Plan: \(game.planLabel) (earn rate \(PLANS.first { $0.id == game.plan }?.earn ?? "1x"))
        Level \(game.li.level), tier \(game.tier.name), RyzePoints \(game.coins), streak \(game.streak) days
        Balance: \(money(bank.totalALL)) main + \(money(bank.totalEUR, "EUR"))
        This month: income \(money(bank.monthIncome)), spent \(money(bank.monthSpend))
        Spending by category: \(cats)
        Savings goals: \(goals)
        """
    }
    var body: some View {
        ZStack { Brand.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    RizOrb(size: 42, glow: false)
                    VStack(alignment: .leading, spacing: 2) { Text("Riz").font(.system(size: 18, weight: .bold)).foregroundColor(Brand.text); HStack(spacing: 5) { Circle().fill(Brand.good).frame(width: 7, height: 7); Text(T("Online · money copilot", "Online · kopilot parash")).font(.system(size: 12)).foregroundColor(Brand.mute) } }
                    Spacer()
                    if !msgs.isEmpty { Button { withAnimation { msgs = [] } } label: { Image(systemName: "square.and.pencil").font(.system(size: 18)).foregroundColor(Brand.text) } }
                }.padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
                Rectangle().fill(Brand.hairline).frame(height: 1)

                if msgs.isEmpty && !typing {
                    VStack(spacing: 0) {
                        Spacer(minLength: 8)
                        RizOrb(size: 72, glow: true)
                        VStack(spacing: 6) {
                            Text(T("Hi \(game.name), I'm Riz", "Ç'kemi \(game.name), unë jam Riz")).font(.system(size: 22, weight: .bold)).foregroundColor(Brand.text).multilineTextAlignment(.center)
                            Text(T("Your money copilot. Ask about spending, points or plans.", "Kopiloti yt i parave. Pyet për shpenzime, pikë ose plane.")).font(.system(size: 14)).foregroundColor(Brand.mute).multilineTextAlignment(.center)
                        }.padding(.horizontal, 28).padding(.top, 14)
                        VStack(spacing: 9) { ForEach(Array(caps.enumerated()), id: \.offset) { _, c in capCard(c.0, c.1, c.2) } }.padding(.top, 22)
                        HStack(spacing: 6) { Image(systemName: "lock.fill").font(.system(size: 11)); Text(T("Private · encrypted in transit, only minimal data is shared", "Privat · e enkriptuar gjatë transferimit, ndahen vetëm të dhëna minimale")).font(.system(size: 12)) }.foregroundColor(Brand.faint).padding(.top, 16)
                        Spacer(minLength: 8)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(.horizontal, 20)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(msgs) { m in bubble(m).id(m.id) }
                                if typing { HStack(alignment: .bottom, spacing: 8) { RizOrb(size: 28, glow: false); TypingDots().padding(.vertical, 14).padding(.horizontal, 16).background(Brand.elev2).overlay(RoundedRectangle(cornerRadius: 20).stroke(Brand.hairline, lineWidth: 1)).clipShape(RoundedRectangle(cornerRadius: 20)); Spacer(minLength: 44) }.id("typing") }
                            }.padding(16)
                        }
                        .onChange(of: msgs.count) { _, _ in if let id = msgs.last?.id { withAnimation(.easeOut) { proxy.scrollTo(id, anchor: .bottom) } } }
                        .onChange(of: typing) { _, t in if t { withAnimation(.easeOut) { proxy.scrollTo("typing", anchor: .bottom) } } }
                    }
                }

                HStack(spacing: 8) {
                    TextField("", text: $input, prompt: Text(T("Ask Riz anything...", "Pyet Riz çdo gjë...")).foregroundColor(Brand.faint)).foregroundColor(Brand.text).padding(.horizontal, 16).frame(height: 48).liquidCapsule()
                    Button { send(input) } label: { Image(systemName: "arrow.up").font(.system(size: 18, weight: .bold)).foregroundColor(.black).frame(width: 48, height: 48).background(Brand.gold).clipShape(Circle()).shadow(color: Brand.yellow.opacity(0.3), radius: 8, y: 4) }.opacity(input.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                }.padding(16)
            }
        }
        .onAppear {
            if let q = ProcessInfo.processInfo.environment["RYZE_ASK"], !didAsk { didAsk = true; send(q) }
            consumePending()
        }
        .onChange(of: game.pendingRizPrompt) { _, _ in consumePending() }
    }
    // Deep-linked prompt from the Analytics insight card → ask Riz with full context.
    func consumePending() {
        if let p = game.pendingRizPrompt { game.pendingRizPrompt = nil; send(p) }
    }
    func capCard(_ icon: String, _ title: String, _ prompt: String) -> some View {
        Button { send(prompt) } label: {
            HStack(spacing: 12) {
                IconTile(system: icon, size: 38)
                VStack(alignment: .leading, spacing: 1) { Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text); Text(prompt).font(.system(size: 12)).foregroundColor(Brand.mute).lineLimit(1) }
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 12, weight: .semibold)).foregroundColor(Brand.faint)
            }.padding(.horizontal, 14).padding(.vertical, 11).background(AppCardBG()).clipShape(RoundedRectangle(cornerRadius: 18))
        }.buttonStyle(PressStyle())
    }
    @ViewBuilder func bubble(_ m: RizMessage) -> some View {
        if m.fromUser {
            HStack { Spacer(minLength: 44); Text(m.text).font(.system(size: 15)).foregroundColor(Brand.onText).padding(.vertical, 11).padding(.horizontal, 15).background(Brand.text).clipShape(RoundedRectangle(cornerRadius: 20)) }
        } else {
            HStack(alignment: .bottom, spacing: 8) {
                RizOrb(size: 28, glow: false)
                RizRichText(text: m.text).font(.system(size: 15)).foregroundColor(Brand.text).frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 11).padding(.horizontal, 14).background(Brand.elev2).overlay(RoundedRectangle(cornerRadius: 20).stroke(Brand.hairline, lineWidth: 1)).clipShape(RoundedRectangle(cornerRadius: 20))
                Spacer(minLength: 16)
            }
        }
    }
}

func rewardCategory(_ id: String) -> String {
    switch id {
    case "r-coffee", "r-kfc", "r-glovo": return "Food"
    case "r-spotify", "r-cinema", "r-game": return "Streaming"
    case "r-merch", "r-fashion": return "Shopping"
    case "r-data", "r-cashback": return "Mobile"
    default: return "Food"
    }
}
func rewardColor(_ id: String) -> Color {
    ["r-spotify": Brand.good, "r-coffee": Brand.coral, "r-cinema": Brand.violet, "r-cashback": Brand.yellow, "r-data": Brand.sky, "r-merch": Brand.pink, "r-glovo": Brand.yellow, "r-kfc": Brand.coral, "r-game": Brand.violet, "r-fashion": Brand.pink][id] ?? Brand.yellow
}

// Redemption result: activation code + QR (scan in store, or enter at checkout) by category.
struct CouponRedeemedSheet: View {
    @EnvironmentObject var game: GameModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    let reward: Reward
    @State private var code = ""
    @State private var copied = false
    private var inStore: Bool { rewardCategory(reward.id) == "Food" }
    var body: some View {
        ZStack { Brand.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                HStack { Spacer(); Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(Brand.text).frame(width: 36, height: 36).liquidCircle() } }
                Image(systemName: reward.icon).font(.system(size: 30, weight: .semibold)).foregroundColor(.white).frame(width: 74, height: 74).background(LinearGradient(colors: [rewardColor(reward.id), rewardColor(reward.id).opacity(0.7)], startPoint: .top, endPoint: .bottom)).clipShape(RoundedRectangle(cornerRadius: 20))
                VStack(spacing: 3) { Text(reward.title).font(.system(size: 22, weight: .bold)).foregroundColor(Brand.text).multilineTextAlignment(.center); Text(reward.brand).font(.system(size: 14)).foregroundColor(Brand.mute) }
                if let img = qrImage("ryze://redeem/\(reward.id)/\(code)") {
                    Image(uiImage: img).interpolation(.none).resizable().frame(width: 196, height: 196).padding(18).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 24)).overlay(RoundedRectangle(cornerRadius: 24).stroke(Brand.gold, lineWidth: 2))
                }
                Button { Clip.copySensitive(code); withAnimation { copied = true } } label: {
                    HStack(spacing: 8) { Text(code).font(.system(size: 18, weight: .bold, design: .monospaced)).tracking(2).foregroundColor(Brand.text); Image(systemName: copied ? "checkmark" : "doc.on.doc").font(.system(size: 13)).foregroundColor(copied ? Brand.good : Brand.mute) }.padding(.horizontal, 16).frame(height: 44).liquidCapsule()
                }.buttonStyle(PressStyle())
                Text(inStore ? T("Show this QR at the counter to claim your reward.", "Trego këtë QR në arkë për të marrë shpërblimin.") : T("Enter this code at checkout to redeem.", "Vendose këtë kod në arkë për ta përdorur.")).font(.system(size: 13)).foregroundColor(Brand.mute).multilineTextAlignment(.center).padding(.horizontal, 30)
                Spacer()
                PrimaryButton(title: T("Done", "U krye")) { dismiss() }
            }.padding(24)
        }
        .onAppear { if code.isEmpty { code = Self.gen(); if !game.redeemed.contains(reward.id) { game.redeem(reward.id) } } }
    }
    static func gen() -> String { let cs = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789"); func p() -> String { String((0..<4).map { _ in cs.randomElement()! }) }; return "RYZE-\(p())-\(p())" }
}

// Original coupon look, a perforated ticket (not Revolut's gradient brand cards).
struct CouponTicket: View {
    let r: Reward
    let color: Color
    let owned: Bool
    let locked: Bool
    let afford: Bool
    let tierName: String
    let redeem: () -> Void
    @AppStorage("ryze_lang") private var lang = "en"
    private let stubW: CGFloat = 82
    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                LinearGradient(colors: [color, color.opacity(0.72)], startPoint: .top, endPoint: .bottom)
                Image(systemName: r.icon).font(.system(size: 24, weight: .semibold)).foregroundColor(.white)
            }.frame(width: stubW)
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(r.title).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text).lineLimit(1)
                    Text(r.brand).font(.system(size: 12)).foregroundColor(Brand.mute)
                    HStack(spacing: 5) { Image(systemName: "star.circle.fill").font(.system(size: 12)).foregroundColor(Brand.yellow); Text("\(r.cost) \(T("pts", "pikë"))").font(.system(size: 12, weight: .semibold)).foregroundColor(Brand.text) }
                }
                Spacer()
                if owned { VStack(spacing: 3) { Image(systemName: "checkmark.seal.fill").font(.system(size: 18)).foregroundColor(Brand.good); Text(T("Owned", "E zotëruar")).font(.system(size: 10)).foregroundColor(Brand.mute) } }
                else if locked { VStack(spacing: 3) { Image(systemName: "lock.fill").font(.system(size: 16)).foregroundColor(Brand.faint); Text(tierName).font(.system(size: 10)).foregroundColor(Brand.faint) } }
                else { Button(action: redeem) { Text(T("Redeem", "Shkëmbe")).font(.system(size: 13, weight: .semibold)).foregroundColor(afford ? .black : Brand.faint).padding(.horizontal, 14).frame(height: 34).background(afford ? AnyShapeStyle(Brand.yellow) : AnyShapeStyle(Brand.elev3)).clipShape(Capsule()) }.buttonStyle(PressStyle()).disabled(!afford) }
            }.padding(.horizontal, 14)
        }
        .frame(height: 96)
        .background(AppCardBG())
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay { Path { p in p.move(to: CGPoint(x: stubW, y: 12)); p.addLine(to: CGPoint(x: stubW, y: 84)) }.stroke(Brand.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])) }
        .overlay(alignment: .topLeading) { Circle().fill(Brand.bg).frame(width: 16, height: 16).offset(x: stubW - 8, y: -8) }
        .overlay(alignment: .bottomLeading) { Circle().fill(Brand.bg).frame(width: 16, height: 16).offset(x: stubW - 8, y: 8) }
    }
}

// MARK: - Rewards hub (gamified season, Play · Invite · Belong)
struct RewardsHub: View {
    @EnvironmentObject var game: GameModel
    @AppStorage("ryze_lang") private var lang = "en"
    enum RRoute: Identifiable { case profile, plans, earn, redeem, analytics, search, map; case coming(String); case coupon(String); var id: String { switch self { case .coming(let s): return "coming-\(s)"; case .coupon(let s): return "coupon-\(s)"; default: return "r-\(String(describing: self))" } } }
    @State private var route: RRoute? = nil
    private var today: String { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date()) }
    var currentPlan: PlanTier? { PLANS.first { $0.id == game.plan } }
    var body: some View {
        ScreenScroll {
            TopBar(name: game.name, imageData: game.avatarData, onProfile: { route = .profile }, onAnalytics: { route = .analytics }, onSearch: { route = .search }, onMap: { route = .map })

            pointsHero
            actionsCard
            discoverCard
            challengesCard
            categoryGrid
            featuredRewards
        }
        .sheet(item: $route) { r in
            switch r {
            case .profile: ProfileSheet()
            case .plans: PlansView()
            case .earn: EarnSheet()
            case .redeem: RewardsStoreSheet()
            case .analytics: AnalyticsView()
            case .search: SearchSheet()
            case .map: DiscoveryMapView()
            case .coming(let str): ComingSoonSheet(title: str)
            case .coupon(let rid): if let rr = GameModel.rewards.first(where: { $0.id == rid }) { CouponRedeemedSheet(reward: rr) }
            }
        }
        .onAppear { if ProcessInfo.processInfo.environment["RYZE_SHEET"] == "plans" { route = .plans } }
    }
    // MARK: points hero (big, centered, like Home balance)
    private var pointsHero: some View {
        VStack(spacing: 12) {
            Text(game.planLabel).font(.system(size: 13, weight: .medium)).foregroundColor(.white.opacity(0.6))
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Image(systemName: "hexagon.fill").font(.system(size: 40)).foregroundStyle(Brand.gold)
                    Image(systemName: "sparkle").font(.system(size: 16, weight: .bold)).foregroundColor(.black)
                }
                Text("\(game.coins)").font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [.white, Color.white.opacity(0.82)], startPoint: .top, endPoint: .bottom))
                    .contentTransition(.numericText()).animation(.snappy, value: game.coins)
                    .lineLimit(1).minimumScaleFactor(0.5)
            }
            Text(T("RyzePoints", "RyzePikë") + " · " + earnRate).font(.system(size: 13)).foregroundColor(Brand.mute)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 26).padding(.horizontal, 20)
        .background(ZStack {
            RoundedRectangle(cornerRadius: 24).fill(Brand.void)
            RoundedRectangle(cornerRadius: 24).fill(RadialGradient(colors: [Brand.yellow.opacity(0.16), .clear], center: .center, startRadius: 8, endRadius: 300))
        })
        .specularBorder(24).clipShape(RoundedRectangle(cornerRadius: 24))
        .environment(\.colorScheme, .dark)
    }
    private var earnRate: String {
        let e = currentPlan?.earn ?? "1 point per 200 L spent"
        let parts = e.split(separator: "·")
        return (parts.count > 1 ? String(parts.last!) : e).trimmingCharacters(in: .whitespaces)
    }

    // MARK: action icons (Earn / Redeem / Perks / Invite) — like Home's console
    private var actionsCard: some View {
        AppCard { HStack(spacing: 0) {
            actionTile("plus", T("Earn", "Fito")) { route = .earn }
            actionDivider
            actionTile("giftcard.fill", T("Redeem", "Përdor")) { route = .redeem }
            actionDivider
            actionTile("crown.fill", T("Perks", "Përfitime")) { route = .plans }
            actionDivider
            ShareLink(item: T("Join me on Ryze, use code \(game.referralCode) and we both get 200 points.", "Bashkohu me mua në Ryze, përdor kodin \(game.referralCode) dhe marrim nga 200 pikë.")) { actionLabel("person.2.fill", T("Invite", "Fto")) }.frame(maxWidth: .infinity)
        } }
    }
    private var actionDivider: some View { Rectangle().fill(Brand.hairline).frame(width: 1, height: 36) }

    // Discovery-map entry — also reachable from the Home top bar (map icon).
    private var discoverCard: some View {
        Button { route = .map } label: {
            AppCard { HStack(spacing: 14) {
                ZStack { RoundedRectangle(cornerRadius: 13).fill(Brand.sky.opacity(0.18)).frame(width: 46, height: 46)
                    Image(systemName: "map.fill").font(.system(size: 20)).foregroundColor(Brand.sky) }
                VStack(alignment: .leading, spacing: 3) {
                    Text(T("Discover Tirana", "Zbulo Tiranën")).font(.system(size: 16, weight: .bold)).foregroundColor(Brand.text)
                    Text("\(game.discovered.count)/\(GameModel.discoverySpots.count) " + T("spots · 🔥 \(game.respect) respect", "vende · 🔥 \(game.respect) respekt")).font(.system(size: 12)).foregroundColor(Brand.mute).lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(Brand.faint)
            } }
        }.buttonStyle(PressStyle())
    }
    private func actionLabel(_ icon: String, _ label: String) -> some View {
        VStack(spacing: 7) { IconTile(system: icon, color: Brand.text, size: 44); Text(label).font(.system(size: 12, weight: .medium)).foregroundColor(Brand.mute) }.frame(maxWidth: .infinity)
    }
    private func actionTile(_ icon: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) { actionLabel(icon, label) }.buttonStyle(PressStyle())
    }

    // MARK: challenges (daily check-in + 2 daily challenges)
    // exclude m-checkin — it's already the dedicated streak row above
    private var dailyChallenges: [Mission] { Array(game.missions.filter { !$0.claimed && $0.id != "m-checkin" }.prefix(2)) }
    private var challengesCard: some View {
        let done = game.lastCheckIn == today
        return AppCard { VStack(spacing: 0) {
            HStack(spacing: 14) {
                IconTile(system: "flame.fill", color: Brand.coral, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(game.streak)-\(T("day streak", "ditë seri"))").font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text)
                    Text(done ? T("Checked in today · back tomorrow", "U regjistrove sot · kthehu nesër") : T("Check in to keep your streak", "Regjistrohu për të mbajtur serinë")).font(.system(size: 12)).foregroundColor(Brand.mute)
                }
                Spacer()
                if done { Image(systemName: "checkmark.seal.fill").foregroundColor(Brand.good).font(.system(size: 22)) }
                else { PillButton(title: T("Check in", "Regjistrohu")) { game.dailyCheckIn() } }
            }.padding(.vertical, 4)
            ForEach(dailyChallenges) { m in
                Rectangle().fill(Brand.hairline).frame(height: 1).padding(.vertical, 4)
                challengeRow(m)
            }
        } }
    }
    private func challengeRow(_ m: Mission) -> some View {
        HStack(spacing: 12) {
            IconTile(system: m.icon, color: Brand.yellow, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(m.title).font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.text).lineLimit(1)
                Text("+\(m.xp) XP · +\(m.coins) " + T("pts", "pikë")).font(.system(size: 12)).foregroundColor(Brand.mute)
            }
            Spacer(minLength: 6)
            if m.progress >= m.target { PillButton(title: T("Claim", "Merr")) { game.claim(m.id) } }
            else { PillButton(title: m.target > 1 ? "+1" : T("Go", "Fillo"), style: .soft) { game.progress(m.id, by: m.target > 1 ? 1 : m.target) } }
        }.padding(.vertical, 4)
    }

    // MARK: category icons (premium tiles)
    private var rewardCats: [(String, String, Color)] {
        [(T("Food", "Ushqim"), "fork.knife", Brand.coral),
         (T("Streaming", "Streaming"), "play.tv.fill", Brand.good),
         (T("Shopping", "Blerje"), "bag.fill", Brand.pink),
         (T("Mobile", "Celular"), "antenna.radiowaves.left.and.right", Brand.sky),
         (T("Travel", "Udhëtim"), "airplane", Brand.yellow),
         (T("Gaming", "Lojëra"), "gamecontroller.fill", Brand.violet),
         (T("Coffee", "Kafe"), "cup.and.saucer.fill", Brand.coral),
         (T("Fashion", "Modë"), "tshirt.fill", Brand.pink)]
    }
    private var categoryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 16) {
            ForEach(Array(rewardCats.enumerated()), id: \.offset) { _, c in
                Button { route = .redeem } label: {
                    VStack(spacing: 8) {
                        Image(systemName: c.1).font(.system(size: 21, weight: .medium)).foregroundColor(c.2)
                            .frame(width: 56, height: 56).background(c.2.opacity(0.14)).clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                        Text(c.0).font(.system(size: 12, weight: .medium)).foregroundColor(Brand.mute).lineLimit(1)
                    }.frame(maxWidth: .infinity)
                }.buttonStyle(PressStyle())
            }
        }.padding(.vertical, 2)
    }

    // MARK: featured rewards — real generated images (Revolut-style)
    private var featured: [(img: String, id: String)] {
        [("reward_music", "r-spotify"), ("reward_food", "r-kfc"), ("reward_gaming", "r-game"), ("reward_fashion", "r-fashion")]
    }
    private var featuredRewards: some View {
        VStack(spacing: 14) {
            ForEach(featured, id: \.id) { f in
                if let r = GameModel.rewards.first(where: { $0.id == f.id }) { rewardImageCard(f.img, r) }
            }
        }
    }
    private func rewardImageCard(_ img: String, _ r: Reward) -> some View {
        let owned = game.redeemed.contains(r.id)
        let locked = r.tierMin > game.tierIndex
        let afford = game.coins >= r.cost
        // Only open the coupon if it can actually be redeemed; otherwise send to the store (shows locked/afford state).
        return Button { if owned || (afford && !locked) { route = .coupon(r.id) } else { route = .redeem } } label: {
            ZStack(alignment: .bottomLeading) {
                Image(img).resizable().scaledToFill().frame(maxWidth: .infinity).frame(height: 196).clipped()
                LinearGradient(colors: [.clear, .clear, .black.opacity(0.82)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 3) {
                    Text(r.brand.uppercased()).font(.system(size: 10, weight: .bold)).tracking(0.6).foregroundColor(.white.opacity(0.7))
                    Text(r.title).font(.system(size: 18, weight: .bold)).foregroundColor(.white).lineLimit(1)
                }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                costPill(r, owned: owned, locked: locked)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(12)
            }
            .frame(maxWidth: .infinity).frame(height: 196)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Brand.hairline, lineWidth: 1))
        }.buttonStyle(PressStyle())
    }
    // Lifted off the photo with a stroke + shadow so the gold pill reads on light images too.
    private func costPill(_ r: Reward, owned: Bool, locked: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: owned ? "checkmark.seal.fill" : locked ? "lock.fill" : "hexagon.fill").font(.system(size: 11, weight: .bold))
            Text(owned ? T("Owned", "E marrë") : locked ? TIERS[r.tierMin].name : "\(r.cost)").font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(owned || locked ? .white : .black)
        .padding(.horizontal, 9).frame(height: 26)
        .background(owned ? AnyShapeStyle(.ultraThinMaterial) : locked ? AnyShapeStyle(Color.black.opacity(0.55)) : AnyShapeStyle(Brand.gold))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
    }

}

struct InfoTextSheet: View {
    let title: String; let text: String
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    var body: some View {
        NavigationStack {
            ScrollView { Text(text).font(.system(size: 14)).foregroundColor(Brand.mute).lineSpacing(4).frame(maxWidth: .infinity, alignment: .leading).padding(20) }
            .background(Brand.bg.ignoresSafeArea())
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.bg, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(T("Done", "U krye")) { dismiss() } } }
        }
    }
}

struct QRSheet: View {
    @EnvironmentObject var game: GameModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack { Brand.bg.ignoresSafeArea()
            VStack(spacing: 18) {
                HStack { Spacer(); Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(Brand.text).frame(width: 36, height: 36).liquidCircle() } }
                Spacer()
                Text(T("Your Ryze code", "Kodi yt Ryze")).font(.system(size: 24, weight: .bold)).foregroundColor(Brand.text)
                Text(T("Scan to pay me or add me on Ryze", "Skano për të paguar ose më shto në Ryze")).font(.system(size: 15)).foregroundColor(Brand.mute).multilineTextAlignment(.center)
                if let img = qrImage("ryze://pay/\(game.referralCode)") {
                    Image(uiImage: img).interpolation(.none).resizable().frame(width: 230, height: 230).padding(22).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 28))
                        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Brand.gold, lineWidth: 2))
                }
                Text("@\(game.name.lowercased()) · \(game.referralCode)").font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text)
                Spacer()
            }.padding(24)
        }
    }
}

func qrImage(_ string: String) -> UIImage? {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(string.utf8)
    filter.correctionLevel = "M"
    guard let out = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
          let cg = context.createCGImage(out, from: out.extent) else { return nil }
    return UIImage(cgImage: cg)
}

extension ProfileDetailView {
    func segRow(_ options: [(String, String)], _ binding: Binding<String>) -> some View {
        HStack(spacing: 8) { ForEach(options, id: \.0) { o in
            Button { binding.wrappedValue = o.0 } label: {
                Text(o.1).font(.system(size: 14, weight: .semibold)).foregroundColor(binding.wrappedValue == o.0 ? .black : Brand.text)
                    .frame(maxWidth: .infinity).frame(height: 40)
                    .background(binding.wrappedValue == o.0 ? AnyShapeStyle(Brand.gold) : AnyShapeStyle(Brand.elev3)).clipShape(Capsule())
            }.buttonStyle(PressStyle())
        } }.padding(8)
    }
}

// MARK: - Discovery map (GTA-style fog of war over a stylized Tirana)
struct DiscoveryMapView: View {
    @EnvironmentObject var game: GameModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    private let spots = GameModel.discoverySpots

    private func kindColor(_ k: SpotKind) -> Color {
        switch k { case .atm: Brand.yellow; case .shop: Brand.coral; case .landmark: Brand.sky; case .park: Brand.mint; case .spot: Brand.violet }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            GeometryReader { geo in
                ZStack {
                    realMap
                    fog(geo.size).allowsHitTesting(false)
                    ForEach(spots) { s in
                        marker(s).position(x: s.x * geo.size.width, y: s.y * geo.size.height)
                    }
                }
                .clipped()
            }
            footer
        }
        .background(Brand.bg.ignoresSafeArea())
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(T("Discover Tirana", "Zbulo Tiranën")).font(.system(size: 20, weight: .bold)).foregroundColor(Brand.text)
                Text("\(game.discovered.count)/\(spots.count) " + T("unlocked", "të zhbllokuara")).font(.system(size: 12)).foregroundColor(Brand.mute)
            }
            Spacer()
            HStack(spacing: 5) { Image(systemName: "flame.fill").font(.system(size: 12)).foregroundColor(Brand.violet); Text("\(game.respect)").font(.system(size: 14, weight: .bold)).foregroundColor(Brand.text); Text(T("respect", "respekt")).font(.system(size: 12)).foregroundColor(Brand.mute) }
                .padding(.horizontal, 12).frame(height: 34).liquidCapsule()
            Button { dismiss() } label: { Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundColor(Brand.mute).frame(width: 32, height: 32).background(Brand.surface).clipShape(Circle()) }
        }.padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 12)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.tap.fill").font(.system(size: 16)).foregroundColor(Brand.yellow)
            Text(T("Tap a spot to check in — unlock ATMs, malls and landmarks to clear the map and earn RyzePoints + respect.", "Prek një vend për t'u regjistruar — zhblloko ATM, qendra dhe pika interesi për të pastruar hartën dhe fituar RyzePikë + respekt.")).font(.system(size: 12)).foregroundColor(Brand.mute).fixedSize(horizontal: false, vertical: true)
        }.padding(.horizontal, 20).padding(.vertical, 14)
    }

    @ViewBuilder private func marker(_ s: DiscoverySpot) -> some View {
        let on = game.discovered.contains(s.id)
        Button {
            if !on { withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { game.discover(s) } }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    Circle().fill(on ? AnyShapeStyle(kindColor(s.kind)) : AnyShapeStyle(Color.black.opacity(0.55)))
                        .frame(width: on ? 38 : 30, height: on ? 38 : 30)
                        .overlay(Circle().stroke(on ? Color.white.opacity(0.55) : Brand.yellow.opacity(0.5), lineWidth: on ? 1.5 : 1))
                        .shadow(color: on ? kindColor(s.kind).opacity(0.65) : .clear, radius: on ? 9 : 0)
                    Image(systemName: on ? s.icon : "questionmark").font(.system(size: on ? 16 : 13, weight: .bold)).foregroundColor(on ? .black : Brand.yellow)
                }
                if on {
                    Text(s.name).font(.system(size: 10, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                        .padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(Color.black.opacity(0.55))).fixedSize()
                }
            }
        }.buttonStyle(PressStyle())
    }

    // Real streets — a fixed, non-interactive dark MapKit map of central Tirana, under the fog.
    private var realMap: some View {
        Map(initialPosition: .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 41.3265, longitude: 19.8190), latitudinalMeters: 2600, longitudinalMeters: 2600)), interactionModes: []) { }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll, showsTraffic: false))
            .environment(\.colorScheme, .dark)
            .allowsHitTesting(false)
    }

    // Fog of war — dark everywhere, softly erased around each discovered spot.
    private func fog(_ size: CGSize) -> some View {
        Canvas { ctx, sz in
            ctx.fill(Path(CGRect(origin: .zero, size: sz)), with: .color(Color.black.opacity(0.8)))
            ctx.blendMode = .destinationOut
            for s in spots where game.discovered.contains(s.id) {
                let c = CGPoint(x: s.x * sz.width, y: s.y * sz.height)
                let rad = sz.width * 0.22
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - rad, y: c.y - rad, width: rad * 2, height: rad * 2)),
                         with: .radialGradient(Gradient(colors: [.black, .black.opacity(0)]), center: c, startRadius: rad * 0.25, endRadius: rad))
            }
        }
    }
}
