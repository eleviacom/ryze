import SwiftUI

struct PlanBenefit: Identifiable { let id = UUID(); let icon: String; let text: String }
struct PlanTier: Identifiable {
    let id: String; let name: String; let price: String; let tagline: String; let earn: String
    let colors: [Color]; let allCount: Int; let featured: Bool; let benefits: [PlanBenefit]
}

let PLANS: [PlanTier] = [
    .init(id: "free", name: "Free", price: "0 L/month", tagline: "Your no-cost youth account", earn: "1 point per 200 L spent",
        colors: [Color(hex: 0x2A2F3A), Color(hex: 0x16181A)], allCount: 10, featured: false,
        benefits: [
            .init(icon: "creditcard", text: "Free virtual card + 1 physical card"),
            .init(icon: "banknote", text: "20,000 L fee-free ATM withdrawals / month"),
            .init(icon: "paperplane", text: "Instant Ryze-to-Ryze transfers & bill splits"),
            .init(icon: "hexagon", text: "1 RyzePoint per 200 L spent"),
            .init(icon: "target", text: "Savings goals with round-ups"),
        ]),
    .init(id: "plus", name: "Plus", price: "199 L/month", tagline: "Built for students", earn: "2 points per 200 L spent",
        colors: [Color(hex: 0x7C5CFF), Color(hex: 0x4DA3FF)], allCount: 15, featured: false,
        benefits: [
            .init(icon: "graduationcap.fill", text: "Student coupons & local discounts"),
            .init(icon: "hexagon.fill", text: "2 RyzePoints per 200 L spent"),
            .init(icon: "banknote", text: "50,000 L fee-free ATM / month"),
            .init(icon: "paintpalette.fill", text: "2 exclusive card skins"),
            .init(icon: "bolt.heart.fill", text: "Round-up boost on savings"),
        ]),
    .init(id: "pro", name: "Pro", price: "399 L/month", tagline: "Do more with your money", earn: "4 points per 200 L spent",
        colors: [Color(hex: 0xFFE600), Color(hex: 0xF5B700)], allCount: 22, featured: true,
        benefits: [
            .init(icon: "square.grid.2x2.fill", text: "5 subscriptions included (Spotify, Glovo…)"),
            .init(icon: "hexagon.fill", text: "4 RyzePoints per 200 L spent"),
            .init(icon: "creditcard.fill", text: "Premium metallic-look card"),
            .init(icon: "arrow.uturn.backward.circle.fill", text: "Cashback at partner brands"),
            .init(icon: "simcard.fill", text: "1 GB eSIM data / month"),
            .init(icon: "ticket.fill", text: "Exclusive event tickets & drops"),
        ]),
    .init(id: "metal", name: "Metal", price: "799 L/month", tagline: "Go all in", earn: "6 points per 200 L spent",
        colors: [Color(hex: 0x8D969E), Color(hex: 0x3A3D40)], allCount: 30, featured: false,
        benefits: [
            .init(icon: "creditcard.fill", text: "Reinforced metal card"),
            .init(icon: "hexagon.fill", text: "6 RyzePoints per 200 L spent"),
            .init(icon: "airplane", text: "Airport lounge passes"),
            .init(icon: "shield.lefthalf.filled", text: "Travel & purchase insurance"),
            .init(icon: "square.grid.2x2.fill", text: "10 subscriptions included"),
            .init(icon: "star.fill", text: "Highest cashback + priority support"),
        ]),
]

struct CardArt: View {
    let colors: [Color]; let name: String
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)).frame(height: 120)
            VStack(alignment: .leading) {
                HStack { Image("RaiffeisenLogo").resizable().frame(width: 26, height: 26).clipShape(RoundedRectangle(cornerRadius: 7)); Spacer(); Text(name).font(.system(size: 12, weight: .bold)).foregroundColor(.white.opacity(0.9)) }
                Spacer()
                RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.55)).frame(width: 34, height: 24)
                Text("RYZE").font(.system(size: 12, weight: .heavy)).foregroundColor(.white)
            }.padding(14)
        }
    }
}

struct PlansView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var game: GameModel
    @State private var sel = 2 // Pro
    var tier: PlanTier { PLANS[sel] }
    var body: some View {
        ZStack { Brand.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack { Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(Brand.text).frame(width: 36, height: 36).background(Brand.surface).clipShape(Circle()) }; Spacer(); Text("Upgrade plan").font(.system(size: 17, weight: .semibold)).foregroundColor(Brand.text); Spacer(); Color.clear.frame(width: 36, height: 36) }.padding(.horizontal, 16).padding(.top, 12)
                ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { ForEach(Array(PLANS.enumerated()), id: \.element.id) { i, p in
                    Button { withAnimation { sel = i } } label: { Text(p.name).font(.system(size: 15, weight: .semibold)).foregroundColor(sel == i ? Brand.text : Brand.mute).padding(.horizontal, 18).frame(height: 38).background(sel == i ? Brand.surface : .clear).overlay(Capsule().stroke(sel == i ? Brand.hairline : .clear, lineWidth: 1)).clipShape(Capsule()) }
                } }.padding(.horizontal, 16) }.padding(.vertical, 14)
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ZStack(alignment: .topTrailing) {
                            RoundedRectangle(cornerRadius: 22).fill(LinearGradient(colors: tier.colors + [Brand.surface], startPoint: .topTrailing, endPoint: .bottomLeading)).frame(height: 150)
                            VStack(alignment: .leading) { Spacer(); Text(tier.name).font(.system(size: 34, weight: .bold)).foregroundColor(tier.featured ? .black : .white); Text(tier.price).font(.system(size: 16, weight: .semibold)).foregroundColor(tier.featured ? .black.opacity(0.7) : .white.opacity(0.8)) }.frame(maxWidth: .infinity, alignment: .leading).padding(18)
                            if tier.featured { Text("MOST POPULAR").font(.system(size: 11, weight: .bold)).foregroundColor(.black).padding(.horizontal, 10).padding(.vertical, 5).background(.white).clipShape(Capsule()).padding(14) }
                        }
                        ForEach(tier.benefits) { b in HStack(spacing: 14) { Image(systemName: b.icon).font(.system(size: 18)).foregroundColor(Brand.yellow).frame(width: 28); Text(b.text).font(.system(size: 16)).foregroundColor(Brand.text); Spacer() } }
                        Text("See all \(tier.allCount)+ benefits").font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.mute).frame(maxWidth: .infinity).padding(.vertical, 14).background(Brand.surface).clipShape(Capsule())
                    }.padding(.horizontal, 20).padding(.bottom, 20)
                }
                PrimaryButton(title: tier.id == "free" ? "Your current plan" : "Join \(tier.name)", enabled: tier.id != "free") { dismiss() }.padding(.horizontal, 20).padding(.bottom, 12)
            }
        }
    }
}
