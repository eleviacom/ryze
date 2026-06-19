import SwiftUI

// MARK: - Banking domain (behind a mock service; real BFF/microservices slot in later)
struct Account: Identifiable { let id: String; let name: String; let currency: String; var balance: Double; let icon: String }
struct Txn: Identifiable { let id = UUID(); let merchant: String; let category: String; let icon: String; let amount: Double; let currency: String; let day: String }
struct Contact: Identifiable { let id: String; let name: String; let tag: String; var onRyze: Bool = true }
enum MsgKind { case text, send, request }
struct PayMsg: Identifiable { let id = UUID(); let kind: MsgKind; let fromMe: Bool; var amount: Double = 0; var note: String = ""; var text: String = ""; var status: String = "paid" }
struct PaymentCard { var last4: String; var frozen: Bool; var online: Bool; var contactless: Bool; var atm: Bool }
struct Goal: Identifiable { let id: String; let name: String; let icon: String; let target: Double; var saved: Double; var roundup: Bool }
struct SpendCat: Identifiable { let id: String; let name: String; let icon: String; let amount: Double; let color: Color }

func money(_ v: Double, _ ccy: String = "ALL") -> String {
    let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = ccy == "EUR" ? 2 : 0
    let n = f.string(from: NSNumber(value: abs(v))) ?? "0"
    return ccy == "EUR" ? "€\(n)" : "\(n) L"
}

final class BankModel: ObservableObject {
    weak var game: GameModel?
    @Published var hideBalance = false
    @Published var accounts: [Account] = [
        .init(id: "all", name: "Main", currency: "ALL", balance: 42580, icon: "banknote.fill"),
        .init(id: "eur", name: "Euro", currency: "EUR", balance: 312.40, icon: "eurosign.circle.fill"),
    ]
    @Published var transactions: [Txn] = [
        .init(merchant: "Salary — Universiteti", category: "Income", icon: "arrow.down.circle.fill", amount: 45000, currency: "ALL", day: "Today"),
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
    @Published var goals: [Goal] = [
        .init(id: "phone", name: "New phone", icon: "iphone", target: 60000, saved: 18500, roundup: true),
        .init(id: "travel", name: "Interrail trip", icon: "airplane", target: 120000, saved: 24000, roundup: false),
    ]
    let categories: [SpendCat] = [
        .init(id: "c1", name: "Eating out", icon: "fork.knife", amount: 6400, color: Color(hex: 0xFF8A5C)),
        .init(id: "c2", name: "Groceries", icon: "cart.fill", amount: 5200, color: Color(hex: 0x34E2B0)),
        .init(id: "c3", name: "Entertainment", icon: "film.fill", amount: 3100, color: Color(hex: 0x7C5CFF)),
        .init(id: "c4", name: "Transport", icon: "bus.fill", amount: 1800, color: Color(hex: 0x4DA3FF)),
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
    func toggleFreeze() { card.frozen.toggle() }
}
