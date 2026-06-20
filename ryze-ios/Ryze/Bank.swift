import SwiftUI

// MARK: - Banking domain (behind a mock service; real BFF/microservices slot in later)
struct Account: Identifiable, Codable { let id: String; let name: String; let currency: String; var balance: Double; let icon: String }
struct Txn: Identifiable, Codable { let id = UUID(); let merchant: String; let category: String; let icon: String; let amount: Double; let currency: String; let day: String }
struct Contact: Identifiable, Codable { let id: String; let name: String; let tag: String; var onRyze: Bool = true }
enum MsgKind: Codable { case text, send, request }
struct PayMsg: Identifiable, Codable { let id = UUID(); let kind: MsgKind; let fromMe: Bool; var amount: Double = 0; var note: String = ""; var text: String = ""; var status: String = "paid" }
struct PaymentCard: Codable { var last4: String; var frozen: Bool; var online: Bool; var contactless: Bool; var atm: Bool }
struct Goal: Identifiable, Codable { let id: String; let name: String; let icon: String; let target: Double; var saved: Double; var roundup: Bool }
struct SpendCat: Identifiable { let id: String; let name: String; let icon: String; let amount: Double; let color: Color }

func money(_ v: Double, _ ccy: String = "ALL") -> String {
    let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = ccy == "EUR" ? 2 : 0
    let n = f.string(from: NSNumber(value: abs(v))) ?? "0"
    return ccy == "EUR" ? "€\(n)" : "\(n) L"
}

final class BankModel: ObservableObject {
    weak var game: GameModel?
    init() { if !(ProcessInfo.processInfo.environment.keys.contains { $0.hasPrefix("RYZE_") }) { loadState() } }
    @Published var hideBalance = false
    @Published var accounts: [Account] = [
        .init(id: "all", name: "Main", currency: "ALL", balance: 42580, icon: "banknote.fill"),
        .init(id: "eur", name: "Euro", currency: "EUR", balance: 312.40, icon: "eurosign.circle.fill"),
    ]
    @Published var transactions: [Txn] = [
        .init(merchant: "Salary, Universiteti", category: "Income", icon: "arrow.down.circle.fill", amount: 45000, currency: "ALL", day: "Today"),
        .init(merchant: "Spotify", category: "Entertainment", icon: "music.note", amount: -549, currency: "ALL", day: "Today"),
        .init(merchant: "Mulliri Vjetër", category: "Eating out", icon: "cup.and.saucer.fill", amount: -250, currency: "ALL", day: "Today"),
        .init(merchant: "Drin Hoxha", category: "Sent", icon: "paperplane.fill", amount: -1000, currency: "ALL", day: "Yesterday"),
        .init(merchant: "Conad", category: "Groceries", icon: "cart.fill", amount: -1840, currency: "ALL", day: "Yesterday"),
        .init(merchant: "Kinema Millennium", category: "Entertainment", icon: "film.fill", amount: -700, currency: "ALL", day: "Mon"),
        .init(merchant: "Top-up", category: "Added", icon: "plus.circle.fill", amount: 5000, currency: "ALL", day: "Mon"),
    ]
    @Published var contacts: [Contact] = [
        .init(id: "elsa", name: "Elsa Halili", tag: "@elsa"), .init(id: "drin", name: "Drin Hoxha", tag: "@drin"),
        .init(id: "mo", name: "Muhamed Alili", tag: "@mo"), .init(id: "sara", name: "Sara Berisha", tag: "@sara"),
        .init(id: "aleks", name: "Aleks Lime", tag: "@aleks"),
    ]
    @Published var threads: [String: [PayMsg]] = [
        "elsa": [.init(kind: .text, fromMe: false, text: "did you get the concert tickets?"),
                 .init(kind: .request, fromMe: false, amount: 1500, note: "concert ticket 🎟️", status: "pending")],
        "drin": [.init(kind: .send, fromMe: true, amount: 1000, note: "taxi last night 🚕", status: "paid")],
    ]
    @Published var card = PaymentCard(last4: "4827", frozen: false, online: true, contactless: true, atm: true)
    @Published var revealed = false
    @Published var virtualCard: PaymentCard? = ProcessInfo.processInfo.environment["RYZE_VCARD"] != nil ? PaymentCard(last4: "8842", frozen: false, online: true, contactless: false, atm: false) : nil
    @Published var virtualRevealed = false
    @Published var cardLimit: Double = 50000
    @Published var cardStyle: CardStyle = .gold
    @Published var cardText: String = ""
    @Published var goals: [Goal] = [
        .init(id: "phone", name: "New phone", icon: "iphone", target: 60000, saved: 18500, roundup: true),
        .init(id: "travel", name: "Interrail trip", icon: "airplane", target: 120000, saved: 24000, roundup: false),
    ]
    let categories: [SpendCat] = [
        .init(id: "c1", name: "Eating out", icon: "fork.knife", amount: 6400, color: Color(hex: 0xFF6F47)),
        .init(id: "c2", name: "Groceries", icon: "cart.fill", amount: 5200, color: Color(hex: 0x2FE3B6)),
        .init(id: "c3", name: "Entertainment", icon: "film.fill", amount: 3100, color: Color(hex: 0x8B5CFF)),
        .init(id: "c4", name: "Transport", icon: "bus.fill", amount: 1800, color: Color(hex: 0x46A8FF)),
    ]

    var totalALL: Double { accounts.first { $0.currency == "ALL" }?.balance ?? 0 }
    var savedTotal: Double { goals.reduce(0) { $0 + $1.saved } }

    private func allIndex() -> Int? { accounts.firstIndex { $0.currency == "ALL" } }

    func send(to c: Contact, amount: Double, note: String) {
        if let i = allIndex() { accounts[i].balance -= amount }
        threads[c.id, default: []].append(PayMsg(kind: .send, fromMe: true, amount: amount, note: note, status: "paid"))
        transactions.insert(Txn(merchant: c.name, category: "Sent", icon: "paperplane.fill", amount: -amount, currency: "ALL", day: "Today"), at: 0)
        game?.realAction("Sent \(money(amount)) to \(c.name.split(separator: " ").first.map(String.init) ?? c.name)", missionId: "m-transfer", xp: 40, coins: 20)
    }
    func request(from c: Contact, amount: Double, note: String) {
        threads[c.id, default: []].append(PayMsg(kind: .request, fromMe: true, amount: amount, note: note, status: "pending"))
        game?.realAction("Requested \(money(amount))", missionId: "m-request", xp: 20, coins: 10)
    }
    func sendText(_ id: String, _ t: String) { threads[id, default: []].append(PayMsg(kind: .text, fromMe: true, text: t)) }
    func payRequest(_ cid: String, _ msgId: UUID) {
        guard let mi = threads[cid]?.firstIndex(where: { $0.id == msgId }) else { return }
        let amt = threads[cid]![mi].amount
        threads[cid]![mi].status = "paid"
        if let i = allIndex() { accounts[i].balance -= amt }
        game?.realAction("Paid request", missionId: "m-transfer", xp: 30, coins: 15)
    }
    func addMoney(_ amount: Double) {
        if let i = allIndex() { accounts[i].balance += amount }
        transactions.insert(Txn(merchant: "Top-up", category: "Added", icon: "plus.circle.fill", amount: amount, currency: "ALL", day: "Today"), at: 0)
        game?.realAction("Added \(money(amount))", missionId: "m-topup", xp: 30, coins: 10)
    }
    func fundGoal(_ id: String, _ amount: Double) {
        guard let gi = goals.firstIndex(where: { $0.id == id }) else { return }
        goals[gi].saved += amount
        if let i = allIndex() { accounts[i].balance -= amount }
        game?.realAction("Saved \(money(amount)) toward \(goals[gi].name)", missionId: "m-goal", xp: 50, coins: 25)
    }
    let fxRate: Double = 98.5   // ALL per 1 EUR (prototype rate)
    var monthIncome: Double { transactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount } }
    var monthSpend: Double { transactions.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) } }
    func exchange(toEUR: Bool, amount: Double) {
        guard amount > 0,
              let ai = accounts.firstIndex(where: { $0.currency == "ALL" }),
              let ei = accounts.firstIndex(where: { $0.currency == "EUR" }) else { return }
        if toEUR {
            accounts[ai].balance -= amount
            accounts[ei].balance += amount / fxRate
            transactions.insert(Txn(merchant: "Exchanged to EUR", category: "Exchange", icon: "arrow.left.arrow.right", amount: -amount, currency: "ALL", day: "Today"), at: 0)
        } else {
            accounts[ei].balance -= amount
            accounts[ai].balance += amount * fxRate
            transactions.insert(Txn(merchant: "Exchanged to ALL", category: "Exchange", icon: "arrow.left.arrow.right", amount: amount * fxRate, currency: "ALL", day: "Today"), at: 0)
        }
        game?.realAction("Exchanged \(money(amount, toEUR ? "ALL" : "EUR"))", missionId: nil, xp: 15, coins: 5)
    }
    func transferOut(_ name: String, _ amount: Double) {
        if let i = allIndex() { accounts[i].balance -= amount }
        transactions.insert(Txn(merchant: name, category: "Transfer", icon: "building.columns.fill", amount: -amount, currency: "ALL", day: "Today"), at: 0)
        game?.realAction("Sent \(money(amount)) to \(name)", missionId: "m-transfer", xp: 40, coins: 20)
    }
    func addGoal(name: String, target: Double, icon: String, roundup: Bool) {
        goals.append(Goal(id: UUID().uuidString, name: name, icon: icon, target: target, saved: 0, roundup: roundup))
        game?.realAction("Started goal: \(name)", missionId: "m-goal", xp: 50, coins: 20)
    }
    func setRoundup(_ id: String, _ on: Bool) { if let i = goals.firstIndex(where: { $0.id == id }) { goals[i].roundup = on } }
    func deleteGoal(_ id: String) { goals.removeAll { $0.id == id } }
    func createVirtualCard() {
        virtualCard = PaymentCard(last4: String(format: "%04d", Int.random(in: 1000...9999)), frozen: false, online: true, contactless: false, atm: false)
        game?.realAction("Virtual card created", missionId: nil, xp: 20, coins: 10)
    }
    func toggleVirtualFreeze() { virtualCard?.frozen.toggle() }
    func deleteVirtualCard() { virtualCard = nil; virtualRevealed = false }
    var cardSpent: Double { monthSpend }
    // MARK: - Persistence
    private struct Snapshot: Codable {
        var hideBalance = false
        var accounts: [Account] = []
        var transactions: [Txn] = []
        var goals: [Goal] = []
        var card: PaymentCard? = nil
        var virtualCard: PaymentCard? = nil
        var cardStyle: CardStyle = .gold
        var cardText = ""
        var cardLimit: Double = 50000
        var threads: [String: [PayMsg]] = [:]
    }
    func saveState() {
        let s = Snapshot(hideBalance: hideBalance, accounts: accounts, transactions: transactions, goals: goals, card: card, virtualCard: virtualCard, cardStyle: cardStyle, cardText: cardText, cardLimit: cardLimit, threads: threads)
        if let d = try? JSONEncoder().encode(s) { UserDefaults.standard.set(d, forKey: "ryze_bank_v1") }
    }
    func loadState() {
        guard let d = UserDefaults.standard.data(forKey: "ryze_bank_v1"), let s = try? JSONDecoder().decode(Snapshot.self, from: d) else { return }
        hideBalance = s.hideBalance
        if !s.accounts.isEmpty { accounts = s.accounts }
        if !s.transactions.isEmpty { transactions = s.transactions }
        if !s.goals.isEmpty { goals = s.goals }
        if let c = s.card { card = c }
        virtualCard = s.virtualCard; cardStyle = s.cardStyle; cardText = s.cardText; cardLimit = s.cardLimit
        if !s.threads.isEmpty { threads = s.threads }
    }
    func toggleFreeze() { card.frozen.toggle() }
}
