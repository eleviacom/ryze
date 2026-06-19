import SwiftUI

// MARK: - Top bar (avatar opens Profile)
struct TopBar: View {
    let name: String
    var onProfile: () -> Void
    var onAnalytics: () -> Void = {}
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onProfile) { Avatar(name: name, size: 40) }
            HStack { Image(systemName: "magnifyingglass").foregroundColor(Brand.mute); Text("Search").foregroundColor(Brand.mute).font(.system(size: 15)); Spacer() }.padding(.horizontal, 14).frame(height: 40).background(Brand.surface).overlay(Capsule().stroke(Brand.hairline, lineWidth: 1)).clipShape(Capsule())
            Button(action: onAnalytics) { Image(systemName: "chart.bar.fill").foregroundColor(Brand.text).frame(width: 40, height: 40).background(Brand.surface).clipShape(Circle()) }
        }
    }
}

// MARK: - Profile (sheet from avatar)
struct ProfileSheet: View {
    @EnvironmentObject var game: GameModel
    @Environment(\.dismiss) private var dismiss
    @State private var showPlans = false
    func row(_ icon: String, _ title: String, _ sub: String? = nil, badge: String? = nil) -> some View {
        HStack(spacing: 14) { Image(systemName: icon).font(.system(size: 18)).foregroundColor(Brand.yellow).frame(width: 28)
            VStack(alignment: .leading, spacing: 1) { Text(title).font(.system(size: 16)).foregroundColor(Brand.text); if let s = sub { Text(s).font(.system(size: 12)).foregroundColor(Brand.mute) } }
            Spacer(); if let b = badge { Text(b).font(.system(size: 12, weight: .bold)).foregroundColor(.black).frame(width: 22, height: 22).background(.white).clipShape(Circle()) } else { Image(systemName: "chevron.right").foregroundColor(Brand.faint).font(.system(size: 13)) } }.padding(.vertical, 13)
    }
    var body: some View {
        ZStack { Brand.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    HStack { Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(Brand.text).frame(width: 36, height: 36).background(Brand.surface).clipShape(Circle()) }; Spacer(); Button { showPlans = true } label: { HStack(spacing: 5) { Image(systemName: "sparkles"); Text("Upgrade") }.font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.text).padding(.horizontal, 14).frame(height: 36).background(Brand.surface).clipShape(Capsule()) } }.padding(.top, 12)
                    Avatar(name: game.name, size: 84).padding(.top, 8)
                    Text(game.name).font(.system(size: 24, weight: .bold)).foregroundColor(Brand.text).padding(.top, 8)
                    HStack(spacing: 6) { Text("@\(game.name.lowercased())").font(.system(size: 14)).foregroundColor(Brand.mute); Image(systemName: "qrcode").font(.system(size: 13)).foregroundColor(Brand.mute) }
                    Button { showPlans = true } label: { HStack { VStack(alignment: .leading, spacing: 3) { Text("Ryze Free").font(.system(size: 18, weight: .bold)).foregroundColor(Brand.text); Text("View plan benefits").font(.system(size: 13)).foregroundColor(Brand.mute) }; Spacer(); CardArt(colors: [Brand.yellow, Color(hex: 0xF5B700)], name: "Free").frame(width: 120).rotationEffect(.degrees(8)).offset(x: 16) }.padding(16).frame(height: 96).background(LinearGradient(colors: [Color(hex: 0x7C5CFF).opacity(0.4), Brand.surface], startPoint: .leading, endPoint: .trailing)).clipShape(RoundedRectangle(cornerRadius: 18)).clipped() }.padding(.top, 18)
                    VStack(spacing: 0) {
                        row("gift.fill", "Invite friends", "Earn 2,000 points or more")
                        Divider().background(Brand.hairline)
                        row("megaphone.fill", "Inbox", badge: "3")
                        Divider().background(Brand.hairline)
                        row("person.text.rectangle.fill", "Personal info")
                        Divider().background(Brand.hairline)
                        row("building.columns.fill", "Account details")
                        Divider().background(Brand.hairline)
                        row("lock.shield.fill", "Security")
                        Divider().background(Brand.hairline)
                        row("doc.text.fill", "Documents & statements")
                        Divider().background(Brand.hairline)
                        row("questionmark.circle.fill", "Help")
                        Divider().background(Brand.hairline)
                        row("gearshape.fill", "Settings")
                    }.padding(.horizontal, 16).background(Brand.surface).clipShape(RoundedRectangle(cornerRadius: 18)).padding(.top, 18)
                    Button { game.resetDemo(); dismiss() } label: { HStack(spacing: 14) { Image(systemName: "rectangle.portrait.and.arrow.right").foregroundColor(Brand.danger).frame(width: 28); Text("Log out").font(.system(size: 16)).foregroundColor(Brand.danger); Spacer() }.padding(.vertical, 15).padding(.horizontal, 16).background(Brand.surface).clipShape(RoundedRectangle(cornerRadius: 18)) }.padding(.top, 12)
                }.padding(.horizontal, 16).padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showPlans) { PlansView() }
    }
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
            TopBar(name: game.name) { rewardsSheet = .profile }
            // points hero
            ZStack {
                RoundedRectangle(cornerRadius: 22).fill(RadialGradient(colors: [Brand.yellow.opacity(0.22), Brand.surface], center: .top, startRadius: 10, endRadius: 320))
                VStack(spacing: 6) {
                    Text("Ryze Free plan").font(.system(size: 14)).foregroundColor(Brand.mute)
                    HStack(spacing: 8) { Image(systemName: "hexagon.fill").foregroundColor(Brand.yellow).font(.system(size: 26)).symbolEffect(.bounce, value: game.celebrate); Text("\(game.coins)").font(.system(size: 44, weight: .bold, design: .rounded)).foregroundStyle(LinearGradient(colors: [.white, Color.white.opacity(0.8)], startPoint: .top, endPoint: .bottom)).contentTransition(.numericText()).animation(.snappy, value: game.coins) }
                    Text("1 point / 200 L spent").font(.system(size: 13)).foregroundColor(Brand.mute)
                    Button { rewardsSheet = .plans } label: { Text("Upgrade").font(.system(size: 14, weight: .semibold)).foregroundColor(.black).padding(.horizontal, 22).frame(height: 38).background(Brand.gold).clipShape(Capsule()) }.padding(.top, 6)
                }.padding(.vertical, 26)
            }.frame(maxWidth: .infinity)
            HStack(spacing: 4) {
                QuickAction(icon: "plus", label: "Earn", prominent: true) {}
                QuickAction(icon: "arrow.down.circle.fill", label: "Redeem") {}
                QuickAction(icon: "sparkles", label: "Plan perks") { rewardsSheet = .plans }
                QuickAction(icon: "ellipsis", label: "More") {}
            }
            Eyebrow(text: "Products")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(products, id: \.0) { p in VStack(spacing: 6) { Image(systemName: p.1).font(.system(size: 20)).foregroundColor(Brand.text).frame(width: 56, height: 56).background(Brand.surface).clipShape(RoundedRectangle(cornerRadius: 16)); Text(p.0).font(.system(size: 11)).foregroundColor(Brand.mute) } }
            }
            Eyebrow(text: "Offers for you")
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
            Eyebrow(text: "Top brands for you")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(brands, id: \.self) { b in VStack(spacing: 6) { Text(String(b.prefix(1))).font(.system(size: 20, weight: .bold)).foregroundColor(Brand.text).frame(width: 56, height: 56).background(Brand.surface).clipShape(Circle()); Text(b).font(.system(size: 11)).foregroundColor(Brand.mute).lineLimit(1) } }
            }
            Eyebrow(text: "Challenges")
            ForEach(game.missions.filter { !$0.claimed }.prefix(2)) { MissionRowView(m: $0) }
            Eyebrow(text: "Your insights")
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
