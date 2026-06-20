import SwiftUI
import MapKit

fileprivate func plainNum(_ v: Double, _ ccy: String) -> String {
    let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = ccy == "EUR" ? 2 : 0
    return f.string(from: NSNumber(value: v)) ?? "0"
}

// MARK: - Analytics (rebuilt, the top-right chart button)
struct AnalyticsView: View {
    @EnvironmentObject var bank: BankModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    var maxCat: Double { bank.categories.map(\.amount).max() ?? 1 }
    var net: Double { bank.monthIncome - bank.monthSpend }
    var topMerchants: [(name: String, total: Double, icon: String)] {
        var dict: [String: (Double, String)] = [:]
        for t in bank.transactions where t.amount < 0 {
            let prev = dict[t.merchant]?.0 ?? 0
            dict[t.merchant] = (prev + abs(t.amount), t.icon)
        }
        return dict.map { (name: $0.key, total: $0.value.0, icon: $0.value.1) }.sorted { $0.total > $1.total }.prefix(4).map { $0 }
    }
    var body: some View {
        NavigationStack {
            ScreenScroll {
                AppCard { VStack(alignment: .leading, spacing: 14) {
                    Eyebrow(text: T("This month", "Këtë muaj"))
                    HStack(spacing: 12) {
                        flowStat(T("Money in", "Hyrje"), bank.monthIncome, Brand.good, "arrow.down.left")
                        flowStat(T("Money out", "Dalje"), bank.monthSpend, Brand.danger, "arrow.up.right")
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack { Text(T("Net flow", "Fluksi neto")).font(.system(size: 13)).foregroundColor(Brand.mute); Spacer(); Text("\(net >= 0 ? "+" : "−")\(money(net))").font(.system(size: 15, weight: .bold)).foregroundColor(net >= 0 ? Brand.good : Brand.text) }
                        GeometryReader { gx in let tot = max(bank.monthIncome, bank.monthSpend, 1)
                            VStack(alignment: .leading, spacing: 7) {
                                Capsule().fill(Brand.good).frame(width: max(6, gx.size.width * CGFloat(bank.monthIncome / tot)), height: 8)
                                Capsule().fill(Brand.danger.opacity(0.85)).frame(width: max(6, gx.size.width * CGFloat(bank.monthSpend / tot)), height: 8)
                            }
                        }.frame(height: 23)
                    }
                } }
                Eyebrow(text: T("Where it goes", "Ku shkojnë paratë"))
                AppCard { VStack(spacing: 12) { ForEach(bank.categories) { c in
                    HStack(spacing: 12) { Image(systemName: c.icon).foregroundColor(c.color).frame(width: 24)
                        VStack(alignment: .leading, spacing: 5) {
                            HStack { Text(c.name).font(.system(size: 14)).foregroundColor(Brand.text); Spacer(); Text(money(c.amount)).font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.text) }
                            GeometryReader { gx in ZStack(alignment: .leading) { Capsule().fill(Brand.hairline); Capsule().fill(c.color).frame(width: gx.size.width * CGFloat(c.amount / maxCat)) } }.frame(height: 6)
                        }
                    }
                } } }
                Eyebrow(text: T("Top merchants", "Tregtarët kryesorë"))
                AppCard { VStack(spacing: 0) { ForEach(Array(topMerchants.enumerated()), id: \.offset) { i, m in
                    HStack(spacing: 12) { IconTile(system: m.icon, color: Brand.text, size: 38)
                        Text(m.name).font(.system(size: 15, weight: .medium)).foregroundColor(Brand.text)
                        Spacer(); Text(money(m.total)).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text) }.padding(.vertical, 11)
                    if i < topMerchants.count - 1 { Rectangle().fill(Brand.hairline).frame(height: 1) }
                } } }
                Eyebrow(text: T("Insight", "Këshillë"))
                AppCard { HStack(spacing: 12) { IconTile(system: "sparkles", size: 40); VStack(alignment: .leading, spacing: 2) { Text("Riz").font(.system(size: 13, weight: .semibold)).foregroundColor(Brand.yellow); Text(T("Eating out is your biggest category this month. A weekly cap of 4,000 L would save about 2,400 L.", "Ushqimi jashtë është kategoria më e madhe këtë muaj. Një limit javor prej 4,000 L do të kursente rreth 2,400 L.")).font(.system(size: 13)).foregroundColor(Brand.mute) }; Spacer(minLength: 0) } }
            }
            .navigationTitle(T("Analytics", "Analitika")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.bg, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(T("Done", "U krye")) { dismiss() } } }
        }
    }
    func flowStat(_ label: String, _ v: Double, _ color: Color, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) { HStack(spacing: 6) { Image(systemName: icon).foregroundColor(color).font(.system(size: 13)); Text(label).font(.system(size: 12)).foregroundColor(Brand.mute) }; Text(money(v)).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(Brand.text).lineLimit(1).minimumScaleFactor(0.6) }.frame(maxWidth: .infinity, alignment: .leading).padding(14).liquidSurface(14)
    }
}

// MARK: - Exchange (ALL <-> EUR)
struct ExchangeView: View {
    @EnvironmentObject var bank: BankModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    @State private var toEUR = true
    @State private var amount = ""
    var amt: Double { Double(amount) ?? 0 }
    var fromCcy: String { toEUR ? "ALL" : "EUR" }
    var toCcy: String { toEUR ? "EUR" : "ALL" }
    var converted: Double { toEUR ? amt / bank.fxRate : amt * bank.fxRate }
    var srcBalance: Double { bank.accounts.first { $0.currency == fromCcy }?.balance ?? 0 }
    var ok: Bool { amt > 0 && amt <= srcBalance }
    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                exchangeRow(T("From", "Nga"), fromCcy, srcBalance, input: true)
                ZStack {
                    Rectangle().fill(Brand.hairline).frame(height: 1)
                    Button { withAnimation(.snappy) { toEUR.toggle() } } label: { Image(systemName: "arrow.up.arrow.down").font(.system(size: 16, weight: .bold)).foregroundColor(.black).frame(width: 46, height: 46).background(Brand.gold).clipShape(Circle()) }.buttonStyle(PressStyle())
                }
                exchangeRow(T("To", "Në"), toCcy, bank.accounts.first { $0.currency == toCcy }?.balance ?? 0, input: false)
                HStack { Text(T("Exchange rate", "Kursi i këmbimit")).font(.system(size: 13)).foregroundColor(Brand.mute); Spacer(); Text("1 EUR = \(String(format: "%.1f", bank.fxRate)) L").font(.system(size: 13, weight: .semibold)).foregroundColor(Brand.text) }.padding(.horizontal, 4)
                Spacer()
                PrimaryButton(title: ok ? T("Exchange", "Këmbe") : (amt > srcBalance ? T("Not enough funds", "Fonde të pamjaftueshme") : T("Exchange", "Këmbe")), enabled: ok) { bank.exchange(toEUR: toEUR, amount: amt); dismiss() }
            }
            .padding(20).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).background(Brand.bg.ignoresSafeArea())
            .navigationTitle(T("Exchange", "Këmbe")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.bg, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(T("Done", "U krye")) { dismiss() } } }
        }
    }
    @ViewBuilder func exchangeRow(_ label: String, _ ccy: String, _ bal: Double, input: Bool) -> some View {
        AppCard { VStack(alignment: .leading, spacing: 8) {
            HStack { Text(label).font(.system(size: 12, weight: .bold)).tracking(1).foregroundColor(Brand.faint); Spacer(); Text("\(ccy) · \(money(bal, ccy))").font(.system(size: 12)).foregroundColor(Brand.mute) }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if input {
                    TextField("0", text: $amount).keyboardType(.decimalPad).font(.system(size: 34, weight: .bold, design: .rounded)).foregroundColor(Brand.text).fixedSize()
                } else {
                    Text(plainNum(converted, ccy)).font(.system(size: 34, weight: .bold, design: .rounded)).foregroundColor(Brand.text).contentTransition(.numericText()).animation(.snappy, value: converted)
                }
                Spacer()
                Text(ccy).font(.system(size: 16, weight: .semibold)).foregroundColor(Brand.mute)
            }
        } }
    }
}

// MARK: - Scan & pay
struct ScanPayView: View {
    @EnvironmentObject var game: GameModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    @State private var showMine = false
    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Picker("", selection: $showMine) { Text(T("Scan", "Skano")).tag(false); Text(T("My code", "Kodi im")).tag(true) }.pickerStyle(.segmented).padding(.horizontal, 4)
                Spacer()
                if showMine {
                    if let img = qrImage("ryze://pay/\(game.referralCode)") {
                        Image(uiImage: img).interpolation(.none).resizable().frame(width: 240, height: 240).padding(22).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 28)).overlay(RoundedRectangle(cornerRadius: 28).stroke(Brand.gold, lineWidth: 2))
                    }
                    Text("@\(game.name.lowercased()) · \(game.referralCode)").font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text)
                    Text(T("Show this to get paid instantly", "Trego këtë për t'u paguar menjëherë")).font(.system(size: 14)).foregroundColor(Brand.mute)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28).fill(Brand.surfaceDeep).frame(width: 250, height: 250)
                        RoundedRectangle(cornerRadius: 28).stroke(Brand.yellow, lineWidth: 3).frame(width: 250, height: 250)
                        Image(systemName: "qrcode.viewfinder").font(.system(size: 92)).foregroundColor(Brand.mute)
                    }
                    Text(T("Point at a Ryze QR to pay", "Drejtoje te një kod Ryze për të paguar")).font(.system(size: 14)).foregroundColor(Brand.mute)
                    Text(T("Camera isn't available in the simulator", "Kamera nuk disponohet në simulator")).font(.system(size: 12)).foregroundColor(Brand.faint)
                }
                Spacer()
            }
            .padding(20).frame(maxWidth: .infinity, maxHeight: .infinity).background(Brand.bg.ignoresSafeArea())
            .navigationTitle(T("Scan & Pay", "Skano & Paguaj")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.bg, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(T("Done", "U krye")) { dismiss() } } }
        }
    }
}

// MARK: - Split a bill
struct SplitBillView: View {
    @EnvironmentObject var bank: BankModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    @State private var amount = ""
    @State private var selected: Set<String> = []
    var amt: Double { Double(amount) ?? 0 }
    var heads: Int { selected.count + 1 }
    var per: Double { heads > 0 ? amt / Double(heads) : 0 }
    var ok: Bool { amt > 0 && !selected.isEmpty }
    var body: some View {
        NavigationStack {
            ScreenScroll {
                AppCard { VStack(alignment: .leading, spacing: 8) {
                    Text(T("Total bill", "Fatura totale")).font(.system(size: 12, weight: .bold)).tracking(1).foregroundColor(Brand.faint)
                    HStack(alignment: .firstTextBaseline, spacing: 6) { TextField("0", text: $amount).keyboardType(.numberPad).font(.system(size: 36, weight: .bold, design: .rounded)).foregroundColor(Brand.text).fixedSize(); Text("L").font(.system(size: 20, weight: .semibold)).foregroundColor(Brand.mute); Spacer() }
                    if ok { Text(T("Split \(heads) ways · ", "Ndaje në \(heads) · ") + "\(money(per)) " + T("each", "secili")).font(.system(size: 13, weight: .semibold)).foregroundColor(Brand.yellow) }
                } }
                Eyebrow(text: T("Split with", "Ndaj me"))
                AppCard { VStack(spacing: 0) { ForEach(Array(bank.contacts.enumerated()), id: \.element.id) { i, c in
                    Button { if selected.contains(c.id) { selected.remove(c.id) } else { selected.insert(c.id) } } label: {
                        HStack(spacing: 12) { Avatar(name: c.name, size: 40)
                            VStack(alignment: .leading, spacing: 2) { Text(c.name).font(.system(size: 15, weight: .medium)).foregroundColor(Brand.text); Text(c.tag).font(.system(size: 12)).foregroundColor(Brand.faint) }
                            Spacer()
                            ZStack { Circle().stroke(selected.contains(c.id) ? Brand.yellow : Brand.hairline, lineWidth: 2).frame(width: 24, height: 24); if selected.contains(c.id) { Circle().fill(Brand.yellow).frame(width: 24, height: 24); Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.black) } }
                        }.padding(.vertical, 10)
                    }.buttonStyle(.plain)
                    if i < bank.contacts.count - 1 { Rectangle().fill(Brand.hairline).frame(height: 1) }
                } } }
                PrimaryButton(title: ok ? T("Request \(money(per)) each", "Kërko \(money(per)) secili") : T("Request", "Kërko"), enabled: ok) {
                    for id in selected { if let c = bank.contacts.first(where: { $0.id == id }) { bank.request(from: c, amount: per, note: T("Split the bill", "Ndarje fature")) } }
                    dismiss()
                }
            }
            .navigationTitle(T("Split a bill", "Ndaj faturën")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.bg, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(T("Done", "U krye")) { dismiss() } } }
        }
    }
}

// MARK: - Bank transfer
struct BankTransferView: View {
    @EnvironmentObject var bank: BankModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    @State private var name = ""
    @State private var iban = ""
    @State private var amount = ""
    var amt: Double { Double(amount) ?? 0 }
    var ok: Bool { amt > 0 && amt <= bank.totalALL && iban.count >= 8 && !name.isEmpty }
    var body: some View {
        NavigationStack {
            ScreenScroll {
                RyzeField(label: T("Recipient name", "Emri i marrësit"), text: $name, placeholder: "Drin Hoxha")
                RyzeField(label: "IBAN", text: $iban, placeholder: "AL47 2026 1100 ...")
                AppCard { VStack(alignment: .leading, spacing: 8) {
                    Text(T("Amount", "Shuma")).font(.system(size: 12, weight: .bold)).tracking(1).foregroundColor(Brand.faint)
                    HStack(alignment: .firstTextBaseline, spacing: 6) { TextField("0", text: $amount).keyboardType(.numberPad).font(.system(size: 34, weight: .bold, design: .rounded)).foregroundColor(Brand.text).fixedSize(); Text("L").font(.system(size: 18, weight: .semibold)).foregroundColor(Brand.mute); Spacer() }
                    Text(T("Available", "E disponueshme") + " \(money(bank.totalALL))").font(.system(size: 12)).foregroundColor(Brand.mute)
                } }
                PrimaryButton(title: ok ? T("Send transfer", "Dërgo transfertën") : (amt > bank.totalALL ? T("Not enough funds", "Fonde të pamjaftueshme") : T("Send transfer", "Dërgo transfertën")), enabled: ok) { bank.transferOut(name, amt); dismiss() }
            }
            .navigationTitle(T("Bank transfer", "Transfertë bankare")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.bg, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(T("Done", "U krye")) { dismiss() } } }
        }
    }
}

// MARK: - Redeem store
struct RewardsStoreSheet: View {
    @EnvironmentObject var game: GameModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    @State private var coupon: Reward? = nil
    var body: some View {
        NavigationStack {
            ScreenScroll {
                HStack(spacing: 7) { Image(systemName: "star.circle.fill").foregroundColor(Brand.yellow); Text("\(game.coins) " + T("points to spend", "pikë për të përdorur")).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text) }
                ForEach(GameModel.rewards) { r in let owned = game.redeemed.contains(r.id); let locked = r.tierMin > game.tierIndex; let afford = game.coins >= r.cost
                    AppCard { HStack(spacing: 14) { IconTile(system: r.icon); VStack(alignment: .leading, spacing: 2) { Text(r.title).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text); Text(r.brand).font(.system(size: 13)).foregroundColor(Brand.mute) }; Spacer()
                        if owned { Image(systemName: "checkmark.seal.fill").foregroundColor(Brand.good) }
                        else if locked { HStack(spacing: 4) { Image(systemName: "lock.fill"); Text(TIERS[r.tierMin].name) }.font(.system(size: 13, weight: .semibold)).foregroundColor(Brand.faint) }
                        else { PillButton(title: "\(r.cost)", enabled: afford) { coupon = r } }
                    } }
                }
            }
            .navigationTitle(T("Redeem", "Përdor pikët")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.bg, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(T("Done", "U krye")) { dismiss() } } }
            .sheet(item: $coupon) { r in CouponRedeemedSheet(reward: r) }
        }
    }
}

// MARK: - Ways to earn
struct EarnSheet: View {
    @EnvironmentObject var game: GameModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    var open: [Mission] { game.missions.filter { !$0.claimed } }
    var body: some View {
        NavigationStack {
            ScreenScroll {
                Text(T("Complete real actions to earn points and XP.", "Përfundo veprime reale për të fituar pikë dhe XP.")).font(.system(size: 14)).foregroundColor(Brand.mute)
                if open.isEmpty { AppCard { Text(T("All done, nice! New ways to earn appear weekly.", "Të gjitha u krye! Mënyra të reja shfaqen çdo javë.")).font(.system(size: 14)).foregroundColor(Brand.mute) } }
                ForEach(open) { MissionRowView(m: $0) }
            }
            .navigationTitle(T("Ways to earn", "Si të fitosh")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.bg, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(T("Done", "U krye")) { dismiss() } } }
        }
    }
}

// MARK: - Search
struct SearchSheet: View {
    @EnvironmentObject var bank: BankModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    @State private var q = ""
    var txns: [Txn] { q.isEmpty ? [] : bank.transactions.filter { $0.merchant.localizedCaseInsensitiveContains(q) || $0.category.localizedCaseInsensitiveContains(q) } }
    var people: [Contact] { q.isEmpty ? [] : bank.contacts.filter { $0.name.localizedCaseInsensitiveContains(q) || $0.tag.localizedCaseInsensitiveContains(q) } }
    var body: some View {
        NavigationStack {
            ScreenScroll {
                HStack(spacing: 8) { Image(systemName: "magnifyingglass").foregroundColor(Brand.mute); TextField("", text: $q, prompt: Text(T("Search transactions, people", "Kërko transaksione, njerëz")).foregroundColor(Brand.faint)).foregroundColor(Brand.text).autocorrectionDisabled() }.padding(.horizontal, 14).frame(height: 48).liquidCapsule()
                if !people.isEmpty { Eyebrow(text: T("People", "Njerëz")); AppCard { VStack(spacing: 0) { ForEach(Array(people.enumerated()), id: \.element.id) { i, c in HStack(spacing: 12) { Avatar(name: c.name, size: 38); VStack(alignment: .leading, spacing: 2) { Text(c.name).font(.system(size: 15, weight: .medium)).foregroundColor(Brand.text); Text(c.tag).font(.system(size: 12)).foregroundColor(Brand.faint) }; Spacer() }.padding(.vertical, 9); if i < people.count - 1 { Rectangle().fill(Brand.hairline).frame(height: 1) } } } } }
                if !txns.isEmpty { Eyebrow(text: T("Transactions", "Transaksione")); AppCard { VStack(spacing: 0) { ForEach(Array(txns.enumerated()), id: \.element.id) { i, t in HStack(spacing: 12) { IconTile(system: t.icon, color: t.amount > 0 ? Brand.good : Brand.text, size: 38); VStack(alignment: .leading, spacing: 2) { Text(t.merchant).font(.system(size: 15, weight: .medium)).foregroundColor(Brand.text); Text("\(t.category) · \(t.day)").font(.system(size: 12)).foregroundColor(Brand.faint) }; Spacer(); Text("\(t.amount > 0 ? "+" : "-")\(money(t.amount, t.currency))").font(.system(size: 14, weight: .semibold)).foregroundColor(t.amount > 0 ? Brand.good : Brand.text) }.padding(.vertical, 9); if i < txns.count - 1 { Rectangle().fill(Brand.hairline).frame(height: 1) } } } } }
                if !q.isEmpty && txns.isEmpty && people.isEmpty { Text(T("No results", "Asnjë rezultat")).font(.system(size: 14)).foregroundColor(Brand.mute).frame(maxWidth: .infinity).padding(.top, 30) }
            }
            .navigationTitle(T("Search", "Kërko")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.bg, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(T("Done", "U krye")) { dismiss() } } }
        }
    }
}

// MARK: - Order physical card (preview + delivery map)
struct OrderCardSheet: View {
    @EnvironmentObject var bank: BankModel
    @EnvironmentObject var game: GameModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    @State private var address = "Rruga Myslym Shyri 14, Tiranë"
    @State private var ordered = false
    private let coord = CLLocationCoordinate2D(latitude: 41.31735, longitude: 19.81755)
    var body: some View {
        NavigationStack {
            ScreenScroll {
                CardFace(last4: bank.card.last4, name: game.name, style: bank.cardStyle, customText: bank.cardText)
                if ordered {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 52)).foregroundStyle(.white, Brand.good)
                        Text(T("Your card is on its way!", "Karta jote është në rrugë!")).font(.system(size: 20, weight: .bold)).foregroundColor(Brand.text)
                        Text(T("Free delivery to your address in 5-7 business days. We'll notify you when it ships.", "Dërgesë falas te adresa jote brenda 5-7 ditëve pune. Do të njoftohesh kur niset.")).font(.system(size: 15)).foregroundColor(Brand.mute).multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity).padding(.vertical, 18)
                    PrimaryButton(title: T("Done", "U krye")) { dismiss() }
                } else {
                    Eyebrow(text: T("Deliver to", "Dërgo te"))
                    Map(initialPosition: .region(MKCoordinateRegion(center: coord, latitudinalMeters: 1100, longitudinalMeters: 1100))) {
                        Marker(T("Your address", "Adresa jote"), systemImage: "shippingbox.fill", coordinate: coord).tint(Brand.yellow)
                    }
                    .frame(height: 170).clipShape(RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(Brand.hairline, lineWidth: 1)).allowsHitTesting(false)
                    RyzeField(label: T("Delivery address", "Adresa e dërgesës"), text: $address)
                    AppCard { HStack(spacing: 12) { IconTile(system: "clock.fill"); VStack(alignment: .leading, spacing: 2) { Text(T("Estimated delivery", "Dorëzimi i parashikuar")).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text); Text(T("5-7 business days · free", "5-7 ditë pune · falas")).font(.system(size: 12)).foregroundColor(Brand.mute) }; Spacer() } }
                    PrimaryButton(title: T("Order card", "Porosit kartën")) { withAnimation(.spring(response: 0.4)) { ordered = true }; game.realAction(T("Physical card ordered", "Karta u porosit"), missionId: nil, xp: 0, coins: 0) }
                }
            }
            .navigationTitle(T("Order card", "Porosit kartë")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.bg, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(Brand.text) } } }
        }
    }
}

// MARK: - Graceful placeholder for secondary destinations
struct ComingItem: Identifiable { let id = UUID(); let title: String }
struct ComingSoonSheet: View {
    let title: String
    var subtitle: String? = nil
    var icon: String = "hammer.fill"
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    init(title: String, subtitle: String? = nil, icon: String = "hammer.fill") { self.title = title; self.subtitle = subtitle; self.icon = icon }
    var body: some View {
        ZStack { Brand.bg.ignoresSafeArea()
            VStack(spacing: 14) {
                HStack { Spacer(); Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(Brand.text).frame(width: 36, height: 36).liquidCircle() } }
                Spacer()
                IconTile(system: icon, size: 64)
                Text(title).font(.system(size: 22, weight: .bold)).foregroundColor(Brand.text).multilineTextAlignment(.center)
                Text(subtitle ?? T("This is on the Ryze prototype roadmap, coming soon.", "Pjesë e prototipit Ryze, së shpejti.")).font(.system(size: 15)).foregroundColor(Brand.mute).multilineTextAlignment(.center).padding(.horizontal, 30)
                Spacer(); Spacer()
            }.padding(20)
        }
    }
}

// MARK: - Goal detail
struct GoalDetailView: View {
    @EnvironmentObject var bank: BankModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    let goalId: String
    @State private var showFund = false
    var goal: Goal? { bank.goals.first { $0.id == goalId } }
    var body: some View {
        ScreenScroll {
            if let g = goal {
                VStack(spacing: 12) {
                    ZStack { Ring(v: g.saved / g.target, size: 150); VStack(spacing: 4) { Text("\(Int(g.saved / g.target * 100))%").font(.system(size: 34, weight: .bold, design: .rounded)).foregroundColor(Brand.text); Image(systemName: g.icon).font(.system(size: 22)).foregroundColor(Brand.yellow) } }
                    Text(g.name).font(.system(size: 22, weight: .bold)).foregroundColor(Brand.text)
                    Text("\(money(g.saved)) " + T("of", "nga") + " \(money(g.target))").font(.system(size: 15)).foregroundColor(Brand.mute)
                    if g.saved < g.target { Text("\(money(g.target - g.saved)) " + T("to go", "mbeten")).font(.system(size: 13, weight: .semibold)).foregroundColor(Brand.yellow) }
                    else { HStack(spacing: 6) { Image(systemName: "checkmark.seal.fill").foregroundColor(Brand.good); Text(T("Goal reached!", "Synimi u arrit!")).font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.good) } }
                }.frame(maxWidth: .infinity).padding(.vertical, 10)
                PrimaryButton(title: T("Add money", "Shto para")) { showFund = true }
                AppCard { HStack(spacing: 12) { IconTile(system: "arrow.triangle.2.circlepath", size: 40); VStack(alignment: .leading, spacing: 2) { Text(T("Round-ups", "Rrumbullakimet")).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text); Text(T("Save spare change automatically", "Kurse kusurin automatikisht")).font(.system(size: 12)).foregroundColor(Brand.mute) }; Spacer(); Toggle("", isOn: Binding(get: { goal?.roundup ?? false }, set: { bank.setRoundup(goalId, $0) })).labelsHidden().tint(Brand.yellow) } }
                Button { bank.deleteGoal(goalId); dismiss() } label: { HStack(spacing: 14) { IconTile(system: "trash.fill", color: Brand.danger, size: 38); Text(T("Delete goal", "Fshi synimin")).font(.system(size: 16, weight: .semibold)).foregroundColor(Brand.danger); Spacer() }.padding(18) }.buttonStyle(PressStyle()).background(AppCardBG()).clipShape(RoundedRectangle(cornerRadius: 24))
            } else {
                AppCard { Text(T("This goal was closed.", "Ky synim u mbyll.")).font(.system(size: 14)).foregroundColor(Brand.mute) }
            }
        }
        .navigationTitle(goal?.name ?? T("Goal", "Synim")).navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.bg, for: .navigationBar)
        .sheet(isPresented: $showFund) { AmountSheet(mode: .fund, goalName: goal?.name) { amt, _ in bank.fundGoal(goalId, amt) }.presentationDetents([.medium]) }
    }
}

// MARK: - New savings goal
struct AddGoalSheet: View {
    @EnvironmentObject var bank: BankModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    @State private var name = ""
    @State private var target = ""
    @State private var icon = "target"
    @State private var roundup = true
    let icons = ["target", "iphone", "airplane", "car.fill", "house.fill", "gift.fill", "graduationcap.fill", "gamecontroller.fill", "camera.fill", "heart.fill", "bag.fill", "laptopcomputer"]
    var tgt: Double { Double(target) ?? 0 }
    var ok: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && tgt > 0 }
    var body: some View {
        NavigationStack {
            ScreenScroll {
                RyzeField(label: T("Goal name", "Emri i synimit"), text: $name, placeholder: T("New phone, trip to Italy...", "Telefon i ri, udhëtim..."))
                AppCard { VStack(alignment: .leading, spacing: 8) {
                    Text(T("Target amount", "Shuma e synuar")).font(.system(size: 12, weight: .bold)).tracking(1).foregroundColor(Brand.faint)
                    HStack(alignment: .firstTextBaseline, spacing: 6) { TextField("0", text: $target).keyboardType(.numberPad).font(.system(size: 36, weight: .bold, design: .rounded)).foregroundColor(Brand.text).fixedSize(); Text("L").font(.system(size: 20, weight: .semibold)).foregroundColor(Brand.mute); Spacer() }
                } }
                Eyebrow(text: T("Pick an icon", "Zgjidh një ikonë"))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(icons, id: \.self) { ic in Button { icon = ic } label: { Image(systemName: ic).font(.system(size: 18)).foregroundColor(icon == ic ? .black : Brand.text).frame(width: 46, height: 46).background(icon == ic ? AnyShapeStyle(Brand.gold) : AnyShapeStyle(Brand.surface)).clipShape(RoundedRectangle(cornerRadius: 13)).overlay(RoundedRectangle(cornerRadius: 13).stroke(icon == ic ? Color.clear : Brand.hairline, lineWidth: 1)) }.buttonStyle(PressStyle()) }
                }
                AppCard { HStack(spacing: 12) { IconTile(system: "arrow.triangle.2.circlepath", size: 40); VStack(alignment: .leading, spacing: 2) { Text(T("Round up spare change", "Rrumbullakos kusurin")).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.text); Text(T("Auto-save change from card spending", "Kurse automatikisht kusurin nga karta")).font(.system(size: 12)).foregroundColor(Brand.mute) }; Spacer(); Toggle("", isOn: $roundup).labelsHidden().tint(Brand.yellow) } }
                PrimaryButton(title: T("Create goal", "Krijo synimin"), enabled: ok) { bank.addGoal(name: name.trimmingCharacters(in: .whitespaces), target: tgt, icon: icon, roundup: roundup); dismiss() }
            }
            .navigationTitle(T("New goal", "Synim i ri")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.bg, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(Brand.text) } } }
        }
    }
}

// MARK: - Premium card face (any CardStyle + optional custom text)
struct CardFace: View {
    let last4: String
    var frozen: Bool = false
    var revealed: Bool = false
    var name: String = "RYZE"
    var style: CardStyle = .gold
    var label: String = "Debit · Premium"
    var customText: String = ""
    @AppStorage("ryze_lang") private var lang = "en"
    private var ink: Color { style.ink }
    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(LinearGradient(colors: style.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            Rectangle().fill(LinearGradient(colors: [Color.white.opacity(0.24), .clear], startPoint: .topLeading, endPoint: .center)).blendMode(.softLight)
            VStack(alignment: .leading, spacing: 0) {
                HStack { Image("RaiffeisenLogo").resizable().frame(width: 34, height: 34).clipShape(RoundedRectangle(cornerRadius: 9)); Spacer(); Text(label).font(.system(size: 12, weight: .semibold)).foregroundColor(ink.opacity(0.7)) }
                Spacer()
                if !customText.isEmpty { Text(customText.uppercased()).font(.system(size: 15, weight: .heavy)).tracking(0.5).foregroundColor(ink).lineLimit(1).padding(.bottom, 10) }
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 5).fill(ink.opacity(0.22)).frame(width: 38, height: 28).overlay(RoundedRectangle(cornerRadius: 5).stroke(ink.opacity(0.22), lineWidth: 1))
                    Image(systemName: "wave.3.right").font(.system(size: 14)).foregroundColor(ink.opacity(0.55))
                    Spacer()
                }
                Spacer().frame(height: 14)
                Text(revealed ? "4827  2156  9043  \(last4)" : "••••  ••••  ••••  \(last4)").font(.system(size: 18, weight: .semibold, design: .monospaced)).foregroundColor(ink)
                Spacer().frame(height: 12)
                HStack { Text(name.uppercased()).font(.system(size: 13, weight: .bold)).foregroundColor(ink).lineLimit(1); Spacer(); Text(revealed ? "09/29  ·  412" : "VISA").font(.system(size: 13, weight: .bold)).foregroundColor(ink) }
            }.padding(22)
            if frozen { ZStack { Color.black.opacity(0.5); VStack(spacing: 6) { Image(systemName: "snowflake").font(.system(size: 30)).foregroundColor(.white); Text(T("Frozen", "Ngrirë")).font(.system(size: 14, weight: .bold)).foregroundColor(.white) } } }
        }
        .frame(height: 208)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.white.opacity(0.16), lineWidth: 1))
        .shadow(color: style.swatch.opacity(0.32), radius: 22, y: 14)
        .shadow(color: .black.opacity(0.4), radius: 10, y: 6)
    }
}

// MARK: - Card spending limit
struct CardLimitSheet: View {
    @EnvironmentObject var bank: BankModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    let presets: [Double] = [25000, 50000, 100000, 200000]
    var body: some View {
        NavigationStack {
            ScreenScroll {
                AppCard { VStack(alignment: .leading, spacing: 8) {
                    Text(T("Monthly spending limit", "Limiti mujor i shpenzimeve")).font(.system(size: 12, weight: .bold)).tracking(1).foregroundColor(Brand.faint)
                    Text(money(bank.cardLimit)).font(.system(size: 34, weight: .bold, design: .rounded)).foregroundColor(Brand.text).contentTransition(.numericText()).animation(.snappy, value: bank.cardLimit)
                    ProgressBar(value: min(1, bank.cardSpent / bank.cardLimit))
                    Text("\(money(bank.cardSpent)) " + T("spent so far", "shpenzuar deri tani")).font(.system(size: 12)).foregroundColor(Brand.mute)
                } }
                Eyebrow(text: T("Quick set", "Vendos shpejt"))
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(presets, id: \.self) { p in Button { withAnimation(.snappy) { bank.cardLimit = p } } label: { Text(money(p)).font(.system(size: 16, weight: .semibold)).foregroundColor(bank.cardLimit == p ? .black : Brand.text).frame(maxWidth: .infinity).frame(height: 52).background(bank.cardLimit == p ? AnyShapeStyle(Brand.gold) : AnyShapeStyle(Brand.surface)).clipShape(RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(bank.cardLimit == p ? Color.clear : Brand.hairline, lineWidth: 1)) }.buttonStyle(PressStyle()) }
                }
                HStack(spacing: 12) {
                    PillButton(title: "− 5,000", style: .soft) { bank.cardLimit = max(5000, bank.cardLimit - 5000) }
                    PillButton(title: "+ 5,000", style: .soft) { bank.cardLimit += 5000 }
                    Spacer()
                }
                PrimaryButton(title: T("Save limit", "Ruaj limitin")) { dismiss() }
            }
            .navigationTitle(T("Card limit", "Limiti i kartës")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.bg, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(Brand.text) } } }
        }
    }
}

// MARK: - Apple Pay (add to wallet prototype)
struct ApplePaySheet: View {
    @EnvironmentObject var bank: BankModel
    @EnvironmentObject var game: GameModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    @State private var added = false
    var body: some View {
        NavigationStack {
            ScreenScroll {
                HStack(spacing: 6) { Image(systemName: "applelogo").font(.system(size: 20)); Text("Pay").font(.system(size: 24, weight: .semibold)) }.foregroundColor(Brand.text).frame(maxWidth: .infinity).padding(.top, 4)
                CardFace(last4: bank.card.last4, name: game.name, style: bank.cardStyle, customText: bank.cardText)
                if added {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 52)).foregroundStyle(.white, Brand.good)
                        Text(T("Added to Apple Wallet", "U shtua në Apple Wallet")).font(.system(size: 20, weight: .bold)).foregroundColor(Brand.text)
                        Text(T("Double-click the side button and use Face ID to pay with Ryze at any contactless terminal.", "Kliko dy herë butonin anësor dhe paguaj me Ryze përmes Face ID në çdo terminal.")).font(.system(size: 15)).foregroundColor(Brand.mute).multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity).padding(.vertical, 18)
                    PrimaryButton(title: T("Done", "U krye")) { dismiss() }
                } else {
                    AppCard { VStack(spacing: 0) {
                        walletRow(T("Card", "Karta"), "Ryze Debit  ••\(bank.card.last4)")
                        Divider().background(Brand.hairline)
                        walletRow(T("Device", "Pajisja"), "iPhone")
                        Divider().background(Brand.hairline)
                        walletRow(T("Use for", "Përdor për"), T("Contactless & in-app", "Pa kontakt & në app"))
                    } }
                    Text(T("Prototype, no real card is provisioned to Apple Wallet.", "Prototip, asnjë kartë reale nuk shtohet në Apple Wallet.")).font(.system(size: 12)).foregroundColor(Brand.faint).multilineTextAlignment(.center).frame(maxWidth: .infinity)
                    Button { withAnimation(.spring(response: 0.4)) { added = true }; game.realAction(T("Added to Apple Wallet", "U shtua në Apple Wallet"), missionId: nil, xp: 0, coins: 0) } label: {
                        HStack(spacing: 8) { Image(systemName: "applelogo"); Text(T("Add to Apple Wallet", "Shto në Apple Wallet")).font(.system(size: 17, weight: .semibold)) }.foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 54).background(Color.black).clipShape(RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18), lineWidth: 1))
                    }.buttonStyle(PressStyle())
                }
            }
            .navigationTitle("Apple Pay").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.bg, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(Brand.text) } } }
        }
    }
    func walletRow(_ k: String, _ v: String) -> some View { HStack { Text(k).font(.system(size: 14)).foregroundColor(Brand.mute); Spacer(); Text(v).font(.system(size: 15, weight: .medium)).foregroundColor(Brand.text) }.padding(.vertical, 12) }
}

// MARK: - Personalise card (colour + your own text)
struct CardStudioSheet: View {
    @EnvironmentObject var bank: BankModel
    @EnvironmentObject var game: GameModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ryze_lang") private var lang = "en"
    @State private var style: CardStyle = .gold
    @State private var text: String = ""
    var body: some View {
        NavigationStack {
            ScreenScroll {
                CardFace(last4: bank.card.last4, name: game.name, style: style, customText: text)
                Eyebrow(text: T("Colour", "Ngjyra"))
                HStack(spacing: 12) {
                    ForEach(CardStyle.allCases) { s in
                        Button { withAnimation(.snappy) { style = s } } label: {
                            VStack(spacing: 7) {
                                Circle().fill(LinearGradient(colors: s.colors, startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 44, height: 44).overlay(Circle().stroke(style == s ? Brand.text : Brand.hairline, lineWidth: style == s ? 2.5 : 1))
                                Text(s.title).font(.system(size: 11, weight: style == s ? .semibold : .regular)).foregroundColor(style == s ? Brand.text : Brand.mute)
                            }
                        }.buttonStyle(PressStyle()).frame(maxWidth: .infinity)
                    }
                }
                Eyebrow(text: T("Your text", "Teksti yt"))
                RyzeField(label: T("Printed on the card front", "Shkruar në pjesën e përparme të kartës"), text: Binding(get: { text }, set: { text = String($0.prefix(16)) }), placeholder: T("e.g. DREAM BIG", "p.sh. ËNDËRRO LART"))
                Text(T("Up to 16 characters.", "Deri në 16 shenja.")).font(.system(size: 12)).foregroundColor(Brand.faint)
                PrimaryButton(title: T("Apply to my card", "Apliko te karta ime")) { bank.cardStyle = style; bank.cardText = text; game.realAction(T("Card personalised", "Karta u personalizua"), missionId: nil, xp: 10, coins: 5); dismiss() }
            }
            .navigationTitle(T("Personalise card", "Personalizo kartën")).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.bg, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(Brand.text) } } }
            .onAppear { style = bank.cardStyle; text = bank.cardText }
        }
    }
}
