import SwiftUI

struct PlanBenefit: Identifiable { let id = UUID(); let icon: String; let text: String }
struct PlanTier: Identifiable {
    let id: String; let name: String; let price: String; let tagline: String; let earn: String
    let image: String; let featured: Bool; let benefits: [PlanBenefit]; let extra: [PlanBenefit]
    var allCount: Int { benefits.count + extra.count }
}

let PLANS: [PlanTier] = [
    .init(id: "free", name: "Free", price: "0 L/month", tagline: "Your no-cost youth account", earn: "1 point per 200 L spent",
        image: "plan_free", featured: false,
        benefits: [
            .init(icon: "creditcard", text: "Free virtual card + 1 physical card"),
            .init(icon: "banknote", text: "20,000 L fee-free ATM withdrawals / month"),
            .init(icon: "paperplane", text: "Instant Ryze-to-Ryze transfers & bill splits"),
            .init(icon: "hexagon", text: "1 RyzePoint per 200 L spent"),
            .init(icon: "target", text: "Savings goals with round-ups"),
        ],
        extra: [
            .init(icon: "bell", text: "Real-time spend notifications"),
            .init(icon: "chart.pie", text: "Spending analytics & budgets"),
            .init(icon: "person.2", text: "Group bills & squad challenges"),
            .init(icon: "sparkles", text: "Riz AI money assistant"),
            .init(icon: "lock.shield", text: "Card freeze & security controls"),
        ]),
    .init(id: "plus", name: "Plus", price: "199 L/month", tagline: "Built for students", earn: "2 points per 200 L spent",
        image: "plan_plus", featured: false,
        benefits: [
            .init(icon: "graduationcap.fill", text: "Student coupons & local discounts"),
            .init(icon: "hexagon.fill", text: "2 RyzePoints per 200 L spent"),
            .init(icon: "banknote", text: "50,000 L fee-free ATM / month"),
            .init(icon: "paintpalette.fill", text: "2 exclusive card skins"),
            .init(icon: "bolt.heart.fill", text: "Round-up boost on savings"),
        ],
        extra: [
            .init(icon: "shield.lefthalf.filled", text: "Purchase protection up to 100,000 L"),
            .init(icon: "ticket", text: "Ticket-cancellation cover for events"),
            .init(icon: "arrow.left.arrow.right", text: "Higher fee-free exchange limit"),
            .init(icon: "headphones", text: "Priority support"),
        ]),
    .init(id: "pro", name: "Pro", price: "399 L/month", tagline: "Do more with your money", earn: "4 points per 200 L spent",
        image: "plan_pro", featured: true,
        benefits: [
            .init(icon: "square.grid.2x2.fill", text: "5 subscriptions included (Spotify, Glovo…)"),
            .init(icon: "hexagon.fill", text: "4 RyzePoints per 200 L spent"),
            .init(icon: "creditcard.fill", text: "Premium metallic-look card"),
            .init(icon: "arrow.uturn.backward.circle.fill", text: "Cashback at partner brands"),
            .init(icon: "simcard.fill", text: "1 GB eSIM data / month"),
            .init(icon: "ticket.fill", text: "Exclusive event tickets & drops"),
        ],
        extra: [
            .init(icon: "airplane", text: "Discounted airport lounge access"),
            .init(icon: "shield.lefthalf.filled", text: "Travel medical insurance"),
            .init(icon: "infinity", text: "Unlimited fee-free exchange"),
            .init(icon: "star.fill", text: "Higher cashback rate"),
        ]),
    .init(id: "metal", name: "Metal", price: "799 L/month", tagline: "Go all in", earn: "6 points per 200 L spent",
        image: "plan_metal", featured: false,
        benefits: [
            .init(icon: "creditcard.fill", text: "Reinforced metal card"),
            .init(icon: "hexagon.fill", text: "6 RyzePoints per 200 L spent"),
            .init(icon: "airplane", text: "Airport lounge passes included"),
            .init(icon: "shield.lefthalf.filled", text: "Travel & purchase insurance"),
            .init(icon: "square.grid.2x2.fill", text: "10 subscriptions included"),
            .init(icon: "star.fill", text: "Highest cashback + priority support"),
        ],
        extra: [
            .init(icon: "globe", text: "Discount on international transfers"),
            .init(icon: "simcard.fill", text: "Larger monthly eSIM data"),
            .init(icon: "ticket.fill", text: "Concierge & priority event access"),
            .init(icon: "creditcard.and.123", text: "Up to 3 physical cards"),
        ]),
]

struct PlansView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var game: GameModel
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
                    Spacer(); Text("Upgrade plan").font(.system(size: 17, weight: .semibold)).foregroundColor(Brand.text); Spacer()
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
                                if tier.featured { Text("MOST POPULAR").font(.system(size: 10, weight: .bold)).foregroundColor(.black).padding(.horizontal, 9).padding(.vertical, 5).background(Brand.gold).clipShape(Capsule()) }
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
                            Text(expanded ? "Show less" : "See all \(tier.allCount) benefits").font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text)
                                .frame(maxWidth: .infinity).padding(.vertical, 14).background(Brand.surface).clipShape(Capsule())
                        }.buttonStyle(PressStyle())
                    }.padding(.horizontal, 20).padding(.bottom, 20)
                }

                PrimaryButton(title: isCurrent ? "Your current plan" : (tier.id == "free" ? "Switch to Free" : "Join \(tier.name)"), enabled: !isCurrent) {
                    game.setPlan(tier.id); dismiss()
                }.padding(.horizontal, 20).padding(.bottom, 12)
            }
        }
        .onAppear { sel = PLANS.firstIndex { $0.id == game.plan } ?? 2 }
    }
}
