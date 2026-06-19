import SwiftUI
import PhotosUI
import CoreImage.CIFilterBuiltins

// MARK: - Top bar (avatar opens Profile)
struct TopBar: View {
    let name: String
    var imageData: Data? = nil
    var onProfile: () -> Void
    var onAnalytics: () -> Void = {}
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onProfile) { Avatar(name: name, size: 40, imageData: imageData) }
            HStack { Image(systemName: "magnifyingglass").foregroundColor(Brand.mute); Text(T("Search", "Kërko")).foregroundColor(Brand.mute).font(.system(size: 15)); Spacer() }.padding(.horizontal, 14).frame(height: 40).background(Brand.surface).overlay(Capsule().stroke(Brand.hairline, lineWidth: 1)).clipShape(Capsule())
            Button(action: onAnalytics) { Image(systemName: "chart.bar.fill").foregroundColor(Brand.text).frame(width: 40, height: 40).background(Brand.surface).clipShape(Circle()) }
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
                                        ZStack { Hexagon().stroke(Brand.gold, lineWidth: 2).frame(width: 60, height: 60); Avatar(name: game.name, size: 48, imageData: game.avatarData) }
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
                                miniStat(game.tier.name, T("Tier", "Klasa"))
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
                                Image(systemName: "hexagon.fill").foregroundColor(.black.opacity(0.25)).font(.system(size: 30))
                            }
                        }
                    }.buttonStyle(PressStyle())

                    sectionLabel(T("Account", "Llogaria"))
                    AppCard { VStack(spacing: 0) { navRow(.personal); rowDivider(); navRow(.account); rowDivider(); navRow(.security) } }

                    sectionLabel(T("Rewards & sharing", "Shpërblime & ndarje"))
                    AppCard { VStack(spacing: 0) {
                        ShareLink(item: "Join me on Ryze — use code \(game.referralCode) and we both get 200 points.") {
                            HStack(spacing: 14) { IconTile(system: "gift.fill", color: Brand.pink, size: 38); VStack(alignment: .leading, spacing: 1) { Text(T("Invite friends", "Fto miqtë")).font(.system(size: 16, weight: .semibold)).foregroundColor(Brand.text); Text(T("Earn 2,000 points or more", "Fito 2,000 pikë ose më shumë")).font(.system(size: 12)).foregroundColor(Brand.faint) }; Spacer(); Image(systemName: "square.and.arrow.up").foregroundColor(Brand.faint).font(.system(size: 14)) }.padding(.vertical, 12)
                        }.buttonStyle(.plain)
                        rowDivider(); navRow(.inbox, badge: "3")
                    } }

                    sectionLabel(T("More", "Më shumë"))
                    AppCard { VStack(spacing: 0) { navRow(.documents); rowDivider(); navRow(.settings); rowDivider(); navRow(.help) } }

                    Button { game.resetDemo(); dismiss() } label: {
                        HStack(spacing: 14) { IconTile(system: "rectangle.portrait.and.arrow.right", color: Brand.danger, size: 38); Text(T("Log out", "Dil")).font(.system(size: 16, weight: .semibold)).foregroundColor(Brand.danger); Spacer() }.padding(18)
                    }.buttonStyle(PressStyle()).background(AppCardBG()).clipShape(RoundedRectangle(cornerRadius: 24))

                    Text("Ryze · prototype for Raiffeisen Bank Albania").font(.system(size: 11)).foregroundColor(Brand.faint).padding(.top, 2)
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
    @State private var faceID = true
    @State private var appLock = true
    @State private var notif = true
    @AppStorage("ryze_appearance") private var appearance = "dark"
    @AppStorage("ryze_lang") private var lang = "en"
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) { content }.padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 40)
        }
        .background(Brand.bg.ignoresSafeArea())
        .navigationTitle(pdTitle(detail)).navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.bg, for: .navigationBar)
    }
    @ViewBuilder var content: some View {
        switch detail {
        case .personal:
            infoCard([("Full name", game.name), ("Email", "klevi@ryze.al"), ("Phone", "+355 69 123 4567"), ("Date of birth", "14/03/2004"), ("Nationality", "Albania")])
        case .account:
            infoCard([("Account", "\(game.name) · Personal"), ("IBAN", "AL47 2026 1100 4827"), ("Currency", "ALL · EUR"), ("Opened", "Today"), ("Status", "Active")])
        case .security:
            Eyebrow(text: "Sign in")
            AppCard { VStack(spacing: 0) { toggleRow("Face ID", "faceid", $faceID); dv(); toggleRow("App lock", "lock.fill", $appLock); dv(); stub("Change passcode", "key.fill") } }
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
            AppCard { VStack(spacing: 0) { toggleRow(T("Notifications", "Njoftime"), "bell.fill", $notif); dv(); stub(T("About Ryze", "Rreth Ryze"), "info.circle.fill"); dv(); stub(T("Terms & privacy", "Kushtet & privatësia"), "doc.text.fill") } }
        case .help:
            AppCard { VStack(spacing: 0) { stub("FAQs", "questionmark.circle.fill"); dv(); stub("Contact support", "bubble.left.and.bubble.right.fill"); dv(); stub("Ask Riz", "sparkles") } }
        case .inbox:
            Eyebrow(text: "Notifications")
            AppCard { VStack(spacing: 0) { msg("Account opened", "Welcome to Ryze — your account is live.", "now"); dv(); msg("Security", "New sign-in to your account.", "1h"); dv(); msg("Rewards", "You earned 50 points this week.", "2d") } }
        }
    }
    func infoCard(_ rows: [(String, String)]) -> some View {
        AppCard { VStack(spacing: 0) { ForEach(Array(rows.enumerated()), id: \.offset) { i, r in
            HStack { Text(r.0).font(.system(size: 14)).foregroundColor(Brand.mute); Spacer(); Text(r.1).font(.system(size: 15, weight: .medium)).foregroundColor(Brand.text) }.padding(.vertical, 13)
            if i < rows.count - 1 { Divider().background(Brand.hairline) }
        } } }
    }
    func toggleRow(_ t: String, _ icon: String, _ b: Binding<Bool>) -> some View { HStack(spacing: 14) { IconTile(system: icon, size: 38); Text(t).font(.system(size: 16)).foregroundColor(Brand.text); Spacer(); Toggle("", isOn: b).labelsHidden().tint(Brand.yellow) }.padding(.vertical, 8) }
    func stub(_ t: String, _ icon: String) -> some View { HStack(spacing: 14) { IconTile(system: icon, size: 38); Text(t).font(.system(size: 16)).foregroundColor(Brand.text); Spacer(); Image(systemName: "chevron.right").foregroundColor(Brand.faint).font(.system(size: 13)) }.padding(.vertical, 12) }
    func doc(_ m: String) -> some View { HStack(spacing: 14) { IconTile(system: "doc.text.fill", size: 38); Text(m).font(.system(size: 16)).foregroundColor(Brand.text); Spacer(); Image(systemName: "arrow.down.circle").foregroundColor(Brand.yellow).font(.system(size: 18)) }.padding(.vertical, 12) }
    func msg(_ t: String, _ s: String, _ time: String) -> some View { HStack(spacing: 14) { IconTile(system: "bell.fill", size: 38); VStack(alignment: .leading, spacing: 2) { Text(t).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text); Text(s).font(.system(size: 13)).foregroundColor(Brand.mute) }; Spacer(); Text(time).font(.system(size: 11)).foregroundColor(Brand.faint) }.padding(.vertical, 11) }
    func dv() -> some View { Divider().background(Brand.hairline).padding(.leading, 52) }
}

// MARK: - Assistant (Riz, full tab)
struct AssistantView: View {
    @State private var msgs: [RizMessage] = [RizMessage(fromUser: false, text: "Hey, I'm Riz — your money assistant. Ask me about your spending, RyzePoints, plans, or how anything in Ryze works.")]
    @State private var input = ""
    let chips = ["Explain RyzePoints", "How do I save?", "Which plan fits me?", "Is my money safe?"]
    func send(_ t: String) { let q = t.trimmingCharacters(in: .whitespaces); guard !q.isEmpty else { return }; input = ""; msgs.append(RizMessage(fromUser: true, text: q)); msgs.append(RizMessage(fromUser: false, text: Riz.reply(stepWhy: nil, text: q))) }
    var body: some View {
        ZStack { Brand.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 10) { Image(systemName: "sparkles").font(.system(size: 20)).foregroundColor(.black).frame(width: 40, height: 40).background(Brand.gold).clipShape(Circle()); VStack(alignment: .leading, spacing: 1) { Text("Riz").font(.system(size: 18, weight: .bold)).foregroundColor(Brand.text); Text("Your money assistant").font(.system(size: 12)).foregroundColor(Brand.mute) }; Spacer() }.padding(16)
                ScrollView { VStack(spacing: 10) { ForEach(msgs) { m in HStack { if m.fromUser { Spacer(minLength: 40) }; Text(m.text).font(.system(size: 15)).foregroundColor(m.fromUser ? .black : Brand.text).padding(.vertical, 10).padding(.horizontal, 14).background(m.fromUser ? Brand.text : Brand.surface).overlay(RoundedRectangle(cornerRadius: 18).stroke(m.fromUser ? .clear : Brand.hairline, lineWidth: 1)).clipShape(RoundedRectangle(cornerRadius: 18)); if !m.fromUser { Spacer(minLength: 40) } } } }.padding(.horizontal, 16) }
                if msgs.count <= 1 { ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { ForEach(chips, id: \.self) { c in Button { send(c) } label: { Text(c).font(.system(size: 13, weight: .semibold)).foregroundColor(Brand.text).padding(.horizontal, 14).frame(height: 36).background(Brand.surface).overlay(Capsule().stroke(Brand.hairline, lineWidth: 1)).clipShape(Capsule()) } } }.padding(.horizontal, 16) }.padding(.bottom, 8) }
                HStack(spacing: 8) { TextField("", text: $input, prompt: Text("Ask Riz…").foregroundColor(Brand.faint)).foregroundColor(Brand.text).padding(.horizontal, 16).frame(height: 48).background(Brand.surface).overlay(Capsule().stroke(Brand.hairline, lineWidth: 1)).clipShape(Capsule()); Button { send(input) } label: { Image(systemName: "arrow.up").font(.system(size: 18, weight: .bold)).foregroundColor(.black).frame(width: 48, height: 48).background(Brand.gold).clipShape(Circle()) } }.padding(16)
            }
        }
    }
}

// MARK: - Rewards hub (RevPoints style)
struct BrandOffer: Identifiable { let id = UUID(); let brand: String; let copy: String; let pts: String; let colors: [Color] }
struct RewardsHub: View {
    @EnvironmentObject var game: GameModel
    @AppStorage("ryze_lang") private var lang = "en"
    enum RSheet: Int, Identifiable { case profile, plans; var id: Int { rawValue } }
    @State private var rewardsSheet: RSheet? = nil
    let products: [(String, String)] = [("Gift cards", "giftcard"), ("Coupons", "tag.fill"), ("Shops", "bag.fill"), ("eSIM", "simcard.fill"), ("Events", "ticket.fill"), ("Lounges", "sofa.fill"), ("Pocket", "tray.fill"), ("More", "ellipsis")]
    let offers = [
        BrandOffer(brand: "Spotify", copy: "3 months Premium, on us", pts: "300 pts", colors: [Color(hex: 0x1DB954), Color(hex: 0x0A0A0A)]),
        BrandOffer(brand: "Glovo", copy: "Order more, earn more", pts: "10 / 1000 L", colors: [Color(hex: 0xFFC244), Color(hex: 0x0A0A0A)]),
        BrandOffer(brand: "Kinema Millennium", copy: "2-for-1 cinema nights", pts: "250 pts", colors: [Color(hex: 0xE61E49), Color(hex: 0x0A0A0A)]),
    ]
    let brands = ["Spotify", "Glovo", "Kinema", "ONE", "Pull&Bear", "KFC", "Mango", "Temu"]
    var body: some View {
        ScreenScroll {
            TopBar(name: game.name, imageData: game.avatarData) { rewardsSheet = .profile }
            // points hero
            ZStack {
                RoundedRectangle(cornerRadius: 22).fill(RadialGradient(colors: [Brand.yellow.opacity(0.22), Brand.surface], center: .top, startRadius: 10, endRadius: 320))
                VStack(spacing: 6) {
                    Text("\(game.planLabel) plan").font(.system(size: 14)).foregroundColor(Brand.mute)
                    HStack(spacing: 8) { Image(systemName: "hexagon.fill").foregroundColor(Brand.yellow).font(.system(size: 26)).symbolEffect(.bounce, value: game.celebrate); Text("\(game.coins)").font(.system(size: 44, weight: .bold, design: .rounded)).foregroundStyle(LinearGradient(colors: [.white, Color.white.opacity(0.8)], startPoint: .top, endPoint: .bottom)).contentTransition(.numericText()).animation(.snappy, value: game.coins) }
                    Text("1 point / 200 L spent").font(.system(size: 13)).foregroundColor(Brand.mute)
                    Button { rewardsSheet = .plans } label: { Text(T("Upgrade", "Përmirëso")).font(.system(size: 14, weight: .semibold)).foregroundColor(.black).padding(.horizontal, 22).frame(height: 38).background(Brand.gold).clipShape(Capsule()) }.padding(.top, 6)
                }.padding(.vertical, 26)
            }.frame(maxWidth: .infinity)
            HStack(spacing: 4) {
                QuickAction(icon: "plus", label: T("Earn", "Fito"), prominent: true) {}
                QuickAction(icon: "arrow.down.circle.fill", label: T("Redeem", "Përdor")) {}
                QuickAction(icon: "sparkles", label: T("Plan perks", "Përfitime")) { rewardsSheet = .plans }
                QuickAction(icon: "ellipsis", label: T("More", "Më shumë")) {}
            }
            Eyebrow(text: T("Products", "Produkte"))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(products, id: \.0) { p in VStack(spacing: 6) { Image(systemName: p.1).font(.system(size: 20)).foregroundColor(Brand.text).frame(width: 56, height: 56).background(Brand.surface).clipShape(RoundedRectangle(cornerRadius: 16)); Text(p.0).font(.system(size: 11)).foregroundColor(Brand.mute) } }
            }
            Eyebrow(text: T("Offers for you", "Oferta për ty"))
            ForEach(offers) { o in
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 20).fill(LinearGradient(colors: o.colors, startPoint: .topTrailing, endPoint: .bottomLeading)).frame(height: 150)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(o.pts).font(.system(size: 12, weight: .bold)).foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 5).background(.white.opacity(0.2)).clipShape(Capsule())
                        Text(o.brand).font(.system(size: 13, weight: .semibold)).foregroundColor(.white.opacity(0.85))
                        Text(o.copy).font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                    }.padding(18)
                }
            }
            Eyebrow(text: T("Top brands for you", "Markat kryesore"))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(brands, id: \.self) { b in VStack(spacing: 6) { Text(String(b.prefix(1))).font(.system(size: 20, weight: .bold)).foregroundColor(Brand.text).frame(width: 56, height: 56).background(Brand.surface).clipShape(Circle()); Text(b).font(.system(size: 11)).foregroundColor(Brand.mute).lineLimit(1) } }
            }
            Eyebrow(text: T("Challenges", "Sfida"))
            ForEach(game.missions.filter { !$0.claimed }.prefix(2)) { MissionRowView(m: $0) }
            Eyebrow(text: T("Your insights", "Statistikat e tua"))
            HStack(spacing: 12) {
                insight("hexagon.fill", "\(game.coins)", "points all-time")
                insight("banknote.fill", "1,240 L", "saved on fees")
            }
        }
        .sheet(item: $rewardsSheet) { s in
            switch s { case .profile: ProfileSheet(); case .plans: PlansView() }
        }
        .onAppear { if ProcessInfo.processInfo.environment["RYZE_SHEET"] == "plans" { rewardsSheet = .plans } }
    }
    func insight(_ icon: String, _ v: String, _ l: String) -> some View {
        VStack(alignment: .leading, spacing: 8) { Image(systemName: icon).foregroundColor(Brand.yellow).font(.system(size: 18)); Text(v).font(.system(size: 20, weight: .bold)).foregroundColor(Brand.text); Text(l).font(.system(size: 12)).foregroundColor(Brand.mute) }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(Brand.surface).overlay(RoundedRectangle(cornerRadius: 16).stroke(Brand.hairline, lineWidth: 1)).clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct QRSheet: View {
    @EnvironmentObject var game: GameModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack { Brand.bg.ignoresSafeArea()
            VStack(spacing: 18) {
                HStack { Spacer(); Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(Brand.text).frame(width: 36, height: 36).background(Brand.surface).clipShape(Circle()) } }
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
