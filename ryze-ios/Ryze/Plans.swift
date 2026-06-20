import SwiftUI

struct PlanBenefit: Identifiable { let id = UUID(); let icon: String; let text: String }
struct PlanTier: Identifiable {
    let id: String; let name: String; let price: String; let tagline: String; let earn: String
    let image: String; let featured: Bool; let benefits: [PlanBenefit]; let extra: [PlanBenefit]
    var allCount: Int { benefits.count + extra.count }
}

var PLANS: [PlanTier] { [
    .init(id: "spark", name: "Spark", price: T("0 L/month", "0 L/muaj"), tagline: T("Start your rise. Zero cost, zero catch.", "Fillo ngjitjen. Pa kosto, pa kushte."), earn: T("1x RyzePoints · 1 point per 200 L spent", "1x RyzePoints · 1 pikë për 200 L shpenzuar"),
        image: "plan_free", featured: false,
        benefits: [
            .init(icon: "creditcard", text: T("Free virtual card + your first physical Ryze card", "Kartë virtuale falas + karta jote e parë fizike Ryze")),
            .init(icon: "banknote", text: T("20,000 L fee-free ATM withdrawals every month", "20,000 L tërheqje pa tarifë në ATM çdo muaj")),
            .init(icon: "paperplane", text: T("Instant Ryze-to-Ryze transfers + one-tap bill splits", "Transferta të menjëhershme Ryze-në-Ryze + ndarje faturash me një prekje")),
            .init(icon: "star.circle", text: T("Earn 1x RyzePoints (1 point per 200 L)", "Fito 1x RyzePoints (1 pikë për 200 L)")),
            .init(icon: "target", text: T("Savings goals with automatic round-ups", "Synime kursimi me rrumbullakim automatik")),
            .init(icon: "flame", text: T("Daily streak + starter quests to level up", "Seri ditore + sfida fillestare për të ngjitur nivel")),
        ],
        extra: [
            .init(icon: "sparkles", text: T("Riz AI money coach for budgets and tips", "Riz, trajneri yt AI për buxhete dhe këshilla")),
            .init(icon: "lock.shield", text: T("Card freeze, limits and real-time alerts", "Ngrirje karte, limite dhe njoftime në kohë reale")),
        ]),
    .init(id: "lift", name: "Lift", price: T("290 L/month", "290 L/muaj"), tagline: T("Made for students. Discounts where you actually spend.", "Bërë për studentët. Zbritje aty ku shpenzon vërtet."), earn: T("2x RyzePoints · 2 points per 200 L spent", "2x RyzePoints · 2 pikë për 200 L shpenzuar"),
        image: "plan_plus", featured: false,
        benefits: [
            .init(icon: "graduationcap.fill", text: T("Student coupons: Glovo, cinema tickets and local cafés", "Kupona studentësh: Glovo, bileta kinemaje dhe kafe lokale")),
            .init(icon: "star.circle.fill", text: T("Earn 2x RyzePoints on everything you buy", "Fito 2x RyzePoints për gjithçka që blen")),
            .init(icon: "banknote", text: T("50,000 L fee-free ATM withdrawals / month", "50,000 L tërheqje pa tarifë në ATM / muaj")),
            .init(icon: "antenna.radiowaves.left.and.right", text: T("1 GB mobile data / month (Vodafone, ONE, ALBtelecom)", "1 GB internet celular / muaj (Vodafone, ONE, ALBtelecom)")),
            .init(icon: "paintpalette.fill", text: T("2 exclusive card skins to flex your style", "2 pamje ekskluzive karte për stilin tënd")),
            .init(icon: "bolt.heart.fill", text: T("Round-up Boost. Savings grow 2x faster", "Përforcim rrumbullakimi. Kursimet rriten 2x më shpejt")),
        ],
        extra: [
            .init(icon: "shield.lefthalf.filled", text: T("Streak Shield: skip a day without losing your streak", "Mburojë serie: humb një ditë pa e prishur serinë")),
            .init(icon: "headphones", text: T("Priority in-app support when you need a human", "Mbështetje me përparësi në app kur të duhet një person")),
        ]),
    .init(id: "surge", name: "Surge", price: T("690 L/month", "690 L/muaj"), tagline: T("Hit your stride. The all-rounder most Ryzers pick.", "Gjej ritmin tënd. Zgjedhja e plotë e shumicës së Ryzerëve."), earn: T("4x RyzePoints · 4 points per 200 L spent", "4x RyzePoints · 4 pikë për 200 L shpenzuar"),
        image: "plan_pro", featured: true,
        benefits: [
            .init(icon: "square.grid.2x2.fill", text: T("3 subscriptions on us: Spotify, Glovo Prime, YouTube and more", "3 abonime falas: Spotify, Glovo Prime, YouTube e të tjera")),
            .init(icon: "star.circle.fill", text: T("Earn 4x RyzePoints + double points on weekend nights out", "Fito 4x RyzePoints + pikë të dyfishta në daljet e fundjavës")),
            .init(icon: "arrow.uturn.backward.circle.fill", text: T("Cashback at partner brands (groceries, gyms, bookstores)", "Cashback te markat partnere (ushqime, palestra, libraritë)")),
            .init(icon: "airplane", text: T("No-fee FX abroad up to 200,000 L / month, perfect for trips", "Këmbim pa tarifë jashtë deri në 200,000 L / muaj, ideal për udhëtime")),
            .init(icon: "simcard.fill", text: T("3 GB mobile data / month on any Albanian network", "3 GB internet celular / muaj në çdo rrjet shqiptar")),
            .init(icon: "person.2.fill", text: T("Squad Mode: shared goals and money challenges with friends", "Modaliteti Skuadër: synime të përbashkëta dhe sfida parash me shokët")),
        ],
        extra: [
            .init(icon: "ticket.fill", text: T("Monthly RyzePoints drop + early access to ticket releases", "Dhuratë mujore RyzePoints + akses i hershëm te biletat")),
            .init(icon: "shield.lefthalf.filled", text: T("Purchase protection up to 150,000 L", "Mbrojtje blerjeje deri në 150,000 L")),
        ]),
    .init(id: "apex", name: "Apex", price: T("1,490 L/month", "1,490 L/muaj"), tagline: T("Go all in. Built for travel, Erasmus and big plans.", "Hidhu plotësisht. Bërë për udhëtime, Erasmus dhe plane të mëdha."), earn: T("5x RyzePoints · 5 points per 200 L spent", "5x RyzePoints · 5 pikë për 200 L shpenzuar"),
        image: "plan_metal", featured: false,
        benefits: [
            .init(icon: "globe", text: T("Unlimited fee-free FX + cheap international transfers, made for Erasmus", "Këmbim pa tarifë i pakufizuar + transferta ndërkombëtare të lira, bërë për Erasmus")),
            .init(icon: "star.circle.fill", text: T("Earn the max 5x RyzePoints on every purchase", "Fito maksimumin 5x RyzePoints për çdo blerje")),
            .init(icon: "square.grid.2x2.fill", text: T("6 subscriptions included + highest partner cashback", "6 abonime të përfshira + cashback-u më i lartë te partnerët")),
            .init(icon: "creditcard.fill", text: T("Standout Apex card (metallic finish) + up to 3 physical cards", "Kartë Apex që bie në sy (përfundim metalik) + deri në 3 karta fizike")),
            .init(icon: "simcard.fill", text: T("8 GB mobile data / month + roaming data for travel", "8 GB internet celular / muaj + të dhëna roaming për udhëtime")),
            .init(icon: "bolt.fill", text: T("Quest Boost and Level Boost: rank up twice as fast", "Përforcim sfidash dhe nivelesh: ngjitu dy herë më shpejt")),
        ],
        extra: [
            .init(icon: "bell.badge.fill", text: T("Concierge for tickets, trips and last-minute student deals", "Konzierge për bileta, udhëtime dhe oferta studentore të minutës së fundit")),
            .init(icon: "shield.lefthalf.filled", text: T("Travel and purchase cover for your trips abroad", "Mbulim udhëtimi dhe blerjeje për udhëtimet jashtë")),
        ]),
] }

struct PlansView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var game: GameModel
    @AppStorage("ryze_lang") private var lang = "en"
    @State private var sel = 2
    @State private var expanded = false
    var tier: PlanTier { PLANS[sel] }
    var rows: [PlanBenefit] { expanded ? tier.benefits + tier.extra : tier.benefits }
    var isCurrent: Bool { tier.id == game.plan }

    var body: some View {
        ZStack { Brand.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(Brand.text).frame(width: 36, height: 36).background(Brand.surface).clipShape(Circle()) }
                    Spacer(); Text(T("Upgrade plan", "Përmirëso planin")).font(.system(size: 17, weight: .semibold)).foregroundColor(Brand.text); Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }.padding(.horizontal, 16).padding(.top, 12)

                ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { ForEach(Array(PLANS.enumerated()), id: \.element.id) { i, p in
                    Button { withAnimation(.snappy) { sel = i; expanded = false } } label: {
                        HStack(spacing: 5) {
                            Text(p.name).font(.system(size: 15, weight: .semibold))
                            if p.id == game.plan { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)) }
                        }
                        .foregroundColor(sel == i ? Brand.text : Brand.mute).padding(.horizontal, 18).frame(height: 38)
                        .background(sel == i ? Brand.surface : Color.clear).overlay(Capsule().stroke(sel == i ? Brand.hairline : .clear, lineWidth: 1)).clipShape(Capsule())
                    }
                } }.padding(.horizontal, 16) }.padding(.vertical, 14)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ZStack(alignment: .bottomLeading) {
                            Image(tier.image).resizable().scaledToFill().frame(height: 168).frame(maxWidth: .infinity).clipped()
                                .overlay(LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom))
                            HStack(alignment: .bottom) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tier.name).font(.system(size: 30, weight: .bold)).foregroundColor(.white)
                                    Text(tier.price).font(.system(size: 15, weight: .semibold)).foregroundColor(.white.opacity(0.85))
                                }
                                Spacer()
                                if tier.featured { Text(T("MOST POPULAR", "MË I ZGJEDHURI")).font(.system(size: 10, weight: .bold)).foregroundColor(.black).padding(.horizontal, 9).padding(.vertical, 5).background(Brand.gold).clipShape(Capsule()) }
                            }.padding(16)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24)).specularBorder(24)

                        Text(tier.tagline).font(.system(size: 15)).foregroundColor(Brand.mute)
                        VStack(spacing: 0) {
                            ForEach(rows) { b in
                                HStack(spacing: 14) { Image(systemName: b.icon).font(.system(size: 18)).foregroundColor(Brand.yellow).frame(width: 28); Text(b.text).font(.system(size: 16)).foregroundColor(Brand.text); Spacer() }
                                    .padding(.vertical, 11)
                            }
                        }
                        Button { withAnimation(.snappy) { expanded.toggle() } } label: {
                            Text(expanded ? T("Show less", "Më pak") : "\(T("See all", "Shiko të")) \(tier.allCount) \(T("benefits", "përfitimet"))").font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text)
                                .frame(maxWidth: .infinity).padding(.vertical, 14).background(Brand.surface).clipShape(Capsule())
                        }.buttonStyle(PressStyle())
                    }.padding(.horizontal, 20).padding(.bottom, 20)
                }

                PrimaryButton(title: isCurrent ? T("Your current plan", "Plani yt aktual") : (tier.id == "spark" ? T("Switch to Spark", "Kalo te Spark") : "\(T("Join", "Bashkohu te")) \(tier.name)"), enabled: !isCurrent) {
                    game.setPlan(tier.id); dismiss()
                }.padding(.horizontal, 20).padding(.bottom, 12)
            }
        }
        .onAppear { sel = PLANS.firstIndex { $0.id == game.plan } ?? 2 }
    }
}
