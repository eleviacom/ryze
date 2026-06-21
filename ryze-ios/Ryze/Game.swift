import SwiftUI

// MARK: - Domain
struct Mission: Identifiable, Codable {
    let id: String; let title: String; let desc: String; let icon: String
    let xp: Int; let coins: Int; let category: String
    var progress: Int; let target: Int; var claimed: Bool; var aiGenerated: Bool = false
}
struct Reward: Identifiable { let id: String; let title: String; let brand: String; let icon: String; let cost: Int; var tierMin: Int = 0 }
struct Badge: Identifiable, Codable { let id: String; let title: String; let icon: String; let desc: String; var earned: Bool }
struct LeaderRow: Identifiable { let id: String; let name: String; let xp: Int; var you: Bool = false }
struct SquadMember: Identifiable, Codable { let id: String; let name: String; var contributed: Int }
struct Toast: Equatable { let label: String; let xp: Int; let coins: Int; var respect: Int = 0 }

// Unlockable city map (GTA-style fog of war): spots you discover by visiting, each worth points + respect.
enum SpotKind: String, Codable { case atm, shop, landmark, park, spot }
struct DiscoverySpot: Identifiable { let id, name, sub, icon: String; let x, y: Double; let points, respect: Int; let kind: SpotKind }

struct Tier { let name: String; let minLevel: Int; let color: Color; let perk: String }
let TIERS: [Tier] = [
    .init(name: "Rookie", minLevel: 1, color: Color(hex: 0x9BA1AD), perk: "1% cashback on card spend"),
    .init(name: "Saver", minLevel: 5, color: Color(hex: 0x34E2B0), perk: "2% cashback + free savings goals"),
    .init(name: "Pro", minLevel: 10, color: Color(hex: 0x4DA3FF), perk: "3% cashback + premium rewards"),
    .init(name: "Elite", minLevel: 20, color: Brand.yellow, perk: "5% cashback + Helsinki perks"),
]

struct LevelInfo { let level: Int; let intoLevel: Int; let needed: Int; let progress: Double }
func xpForLevel(_ l: Int) -> Int { 80 + l * 60 }
func levelInfo(_ xp: Int) -> LevelInfo {
    var level = 1, rem = max(0, xp)
    while rem >= xpForLevel(level) { rem -= xpForLevel(level); level += 1 }
    let need = xpForLevel(level)
    return LevelInfo(level: level, intoLevel: rem, needed: need, progress: Double(rem) / Double(need))
}
func tierForLevel(_ level: Int) -> (Tier, Int) {
    var idx = 0
    for (i, t) in TIERS.enumerated() where level >= t.minLevel { idx = i }
    return (TIERS[idx], idx)
}
func streakMultiplier(_ s: Int) -> Double { min(2, 1 + Double(s) * 0.1) }

// MARK: - Model
final class GameModel: ObservableObject {
    @Published var onboarded = false
    @Published var kycVerified = false
    @Published var name = "Friend"
    @Published var xp = 0
    @Published var coins = 120
    @Published var streak = 0
    @Published var lastCheckIn: String? = nil
    @Published var savedTotal = 0
    @Published var invites = 0
    @Published var redeemed: Set<String> = []
    @Published var missions: [Mission] = GameModel.seedMissions
    @Published var badges: [Badge] = GameModel.seedBadges
    @Published var squad = GameModel.seedSquad
    @Published var aiMission: Mission? = nil
    @Published var toast: Toast? = nil
    @Published var pendingRizPrompt: String? = nil   // analytics insight → Assistant tab deep-link (transient)
    @Published var avatarData: Data? = nil
    @Published var plan: String = "spark"
    @Published var celebrate = 0
    @Published var showWelcome = false               // first-run starter-challenges sheet, shown once after onboarding
    @Published var respect = 0                        // GTA-style "respect" earned by discovering the city
    @Published var discovered: Set<String> = []       // unlocked discovery-map spot ids
    let referralCode = "RYZE-\(Int.random(in: 1000...9999))"

    init() {
        let env = ProcessInfo.processInfo.environment
        if !(env.keys.contains { $0.hasPrefix("RYZE_") }) { loadState() }
        if env["RYZE_HOME"] != nil {
            name = "Klevi"; xp = 320; coins = 480; streak = 4; kycVerified = true; onboarded = true
            if let i = missions.firstIndex(where: { $0.id == "ob-verify" }) { missions[i].progress = 1; missions[i].claimed = true }
        }
        if env["RYZE_WELCOME"] != nil { onboarded = true; showWelcome = true }   // demo/screenshot hook
        if env["RYZE_MAP"] != nil { discovered = ["blok", "atm-blok", "skanderbeg", "toptani", "pazari"]; respect = 230 }   // demo/screenshot hook
        if let pl = env["RYZE_PLAN"] { plan = pl }
    }

    // MARK: - Persistence
    private struct Snapshot: Codable {
        var onboarded = false, kycVerified = false
        var name = "Friend"
        var xp = 0, coins = 120, streak = 0, invites = 0, savedTotal = 0
        var lastCheckIn: String? = nil
        var redeemed: Set<String> = []
        var plan = "spark"
        var avatarData: Data? = nil
        var missions: [Mission] = []
        var badges: [Badge] = []
        var squad: Squad? = nil
        var respect = 0
        var discovered: Set<String> = []
    }
    func saveState() {
        let s = Snapshot(onboarded: onboarded, kycVerified: kycVerified, name: name, xp: xp, coins: coins, streak: streak, invites: invites, savedTotal: savedTotal, lastCheckIn: lastCheckIn, redeemed: redeemed, plan: plan, avatarData: avatarData, missions: missions, badges: badges, squad: squad, respect: respect, discovered: discovered)
        if let d = try? JSONEncoder().encode(s) { SecureStore.save(d, "game") }
    }
    func loadState() {
        var data = SecureStore.load("game")
        if data == nil, let legacy = UserDefaults.standard.data(forKey: "ryze_game_v1") {   // one-time migration off cleartext UserDefaults
            data = legacy; SecureStore.save(legacy, "game"); UserDefaults.standard.removeObject(forKey: "ryze_game_v1")
        }
        guard let d = data, let s = try? JSONDecoder().decode(Snapshot.self, from: d) else { return }
        onboarded = s.onboarded; kycVerified = s.kycVerified; name = s.name; xp = s.xp; coins = s.coins; streak = s.streak; invites = s.invites; savedTotal = s.savedTotal; lastCheckIn = s.lastCheckIn; redeemed = s.redeemed; plan = s.plan; avatarData = s.avatarData
        if !s.missions.isEmpty { missions = s.missions }
        if !s.badges.isEmpty { badges = s.badges }
        if let sq = s.squad { squad = sq }
        respect = s.respect; discovered = s.discovered
    }

    var li: LevelInfo { levelInfo(xp) }
    var planLabel: String { ["spark": "Ryze Spark", "lift": "Ryze Lift", "surge": "Ryze Surge", "apex": "Ryze Apex"][plan] ?? "Ryze Spark" }
    func setPlan(_ id: String) { plan = id; fire("Welcome to \(planLabel)", 0, 0) }
    var tier: Tier { tierForLevel(li.level).0 }
    var tierIndex: Int { tierForLevel(li.level).1 }

    static let leaderboard: [LeaderRow] = [
        .init(id: "l1", name: "Elsa", xp: 1840), .init(id: "l2", name: "Muhamed", xp: 1520),
        .init(id: "l3", name: "Aleks", xp: 980), .init(id: "l4", name: "Drin", xp: 610), .init(id: "l5", name: "Sara", xp: 430),
    ]

    private func today() -> String { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date()) }
    private func fire(_ label: String, _ xpG: Int, _ coinsG: Int, respect: Int = 0) {
        toast = Toast(label: label, xp: xpG, coins: coinsG, respect: respect); celebrate += 1
        let snap = celebrate
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { if self.celebrate == snap { self.toast = nil } }
    }

    // Visit/check-in at a city spot: unlock it, clear the fog, bank points + respect.
    func discover(_ s: DiscoverySpot) {
        guard !discovered.contains(s.id) else { return }
        discovered.insert(s.id)
        coins += s.points; respect += s.respect; xp += s.points / 3
        evalBadges()
        fire("📍 " + T("\(s.name) unlocked", "\(s.name) u zhbllokua"), s.points / 3, s.points, respect: s.respect)
    }

    func generateAi() {
        if aiMission != nil { return }
        if streak < 3 {
            aiMission = Mission(id: "ai", title: "Start a 3-day streak", desc: "Check in tomorrow to grow your multiplier", icon: "sparkles", xp: 60, coins: 25, category: "daily", progress: 0, target: 1, claimed: false, aiGenerated: true)
        } else if invites < 3 {
            aiMission = Mission(id: "ai", title: "Invite one more friend", desc: "Your squad is close to its goal", icon: "sparkles", xp: 120, coins: 60, category: "social", progress: 0, target: 1, claimed: false, aiGenerated: true)
        } else {
            aiMission = Mission(id: "ai", title: "Save your way to level \(li.level + 1)", desc: "Move €10 into a goal", icon: "sparkles", xp: 90, coins: 35, category: "daily", progress: 0, target: 1, claimed: false, aiGenerated: true)
        }
    }

    func progress(_ id: String, by: Int = 1) {
        if let i = missions.firstIndex(where: { $0.id == id }) {
            missions[i].progress = min(missions[i].target, missions[i].progress + by)
            if id == "w-save" { savedTotal += by }
        }
        if aiMission?.id == id { aiMission?.progress = min(aiMission!.target, (aiMission?.progress ?? 0) + by) }
    }

    func claim(_ id: String) {
        var m: Mission?
        if let i = missions.firstIndex(where: { $0.id == id }) { m = missions[i] }
        else if aiMission?.id == id { m = aiMission }
        guard let mission = m, !mission.claimed, mission.progress >= mission.target else { return }
        let mult = mission.category == "daily" ? streakMultiplier(streak) : 1
        let c = Int(Double(mission.coins) * mult)
        xp += mission.xp; coins += c
        if let i = missions.firstIndex(where: { $0.id == id }) { missions[i].claimed = true }
        if aiMission?.id == id { aiMission?.claimed = true }
        evalBadges(); fire(mission.title, mission.xp, c)
    }

    func dailyCheckIn() {
        if lastCheckIn == today() { return }
        streak += 1; lastCheckIn = today()
        let mult = streakMultiplier(streak)
        let xpG = Int(30 * mult), cG = Int(10 * mult)
        xp += xpG; coins += cG
        if let i = missions.firstIndex(where: { $0.id == "m-checkin" }) { missions[i].progress = 1; missions[i].claimed = true }
        evalBadges(); fire("Day \(streak) streak!", xpG, cG)
    }

    func redeem(_ id: String) {
        guard let r = GameModel.rewards.first(where: { $0.id == id }), coins >= r.cost, !redeemed.contains(id) else { return }
        coins -= r.cost; redeemed.insert(id); fire("Redeemed \(r.title)", 0, -r.cost)
    }

    func simulateReferral() {
        invites += 1
        squad.progress = min(squad.goal, squad.progress + 1)
        if let i = squad.members.firstIndex(where: { $0.name == "You" }) { squad.members[i].contributed += 1 }
        if let i = missions.firstIndex(where: { $0.id == "s-invite" }) { missions[i].progress = missions[i].target }
        xp += 200; coins += 100; evalBadges(); fire("Friend joined Ryze!", 200, 100)
    }

    func realAction(_ label: String, missionId: String?, xp xpG: Int, coins cG: Int) {
        xp += xpG; coins += cG
        if let id = missionId, let i = missions.firstIndex(where: { $0.id == id }), !missions[i].claimed {
            missions[i].progress = min(missions[i].target, missions[i].progress + 1)
            if missions[i].progress >= missions[i].target { missions[i].claimed = true }
        }
        evalBadges(); fire(label, xpG, cG)
    }

    func completeAccount(name: String?) {
        guard !onboarded else { return }   // idempotent: ignore double-taps from Success/Skip
        if let n = name, !n.isEmpty { self.name = n }
        if let i = missions.firstIndex(where: { $0.id == "ob-verify" }) { missions[i].progress = missions[i].target; missions[i].claimed = true }
        xp += 120; coins += 50; kycVerified = true; evalBadges()
        fire("\(planLabel) opened!", 120, 50)   // single toast, names the chosen plan (set silently before this call)
        withAnimation(.easeInOut) { onboarded = true }
        saveState()                            // persist immediately, don't wait for backgrounding
        // First entry into the app: surface the starter challenges once MainTabView has settled.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.showWelcome = true }
    }

    func resetDemo() {
        xp = 0; coins = 120; streak = 0; lastCheckIn = nil; savedTotal = 0; invites = 0
        redeemed = []; missions = GameModel.seedMissions; badges = GameModel.seedBadges
        squad = GameModel.seedSquad; aiMission = nil; onboarded = false; kycVerified = false; name = "Friend"
        UserDefaults.standard.removeObject(forKey: "ryze_game_v1"); UserDefaults.standard.removeObject(forKey: "ryze_bank_v1")
        SecureStore.remove("game"); SecureStore.remove("bank")
    }

    // Lightweight toast (no XP/coins) — used for security notices like screenshot detection.
    func notify(_ label: String) { fire(label, 0, 0) }

    private func evalBadges() {
        let level = li.level
        let onboardDone = missions.first { $0.id == "ob-verify" }?.claimed ?? false
        let cond: [String: Bool] = [
            "b-first-invite": invites >= 1, "b-streak7": streak >= 7, "b-level10": level >= 10,
            "b-onboard": onboardDone, "b-squad": squad.progress >= squad.goal, "b-saver": savedTotal >= 100,
        ]
        for i in badges.indices { if cond[badges[i].id] == true { badges[i].earned = true } }
    }
}

// MARK: - Seed data
extension GameModel {
    static let seedMissions: [Mission] = [
        .init(id: "ob-verify", title: "Verify your identity", desc: "Open your account", icon: "person.text.rectangle", xp: 120, coins: 50, category: "starter", progress: 0, target: 1, claimed: false),
        .init(id: "m-topup", title: "Add your first money", desc: "Top up your account", icon: "plus.circle.fill", xp: 80, coins: 30, category: "starter", progress: 0, target: 1, claimed: false),
        .init(id: "m-card", title: "Order your card", desc: "Get a Ryze card on its way", icon: "creditcard.fill", xp: 100, coins: 40, category: "starter", progress: 0, target: 1, claimed: false),
        .init(id: "m-transfer", title: "Make your first transfer", desc: "Send money to a friend", icon: "paperplane.fill", xp: 120, coins: 50, category: "starter", progress: 0, target: 1, claimed: false),
        .init(id: "m-split", title: "Split a bill", desc: "Share a cost with friends", icon: "person.2.fill", xp: 90, coins: 40, category: "starter", progress: 0, target: 1, claimed: false),
        .init(id: "m-goal", title: "Start a savings goal", desc: "Save toward something", icon: "flag.fill", xp: 90, coins: 30, category: "starter", progress: 0, target: 1, claimed: false),
        .init(id: "m-checkin", title: "Daily check-in", desc: "Keep your streak alive", icon: "sun.max.fill", xp: 30, coins: 10, category: "daily", progress: 0, target: 1, claimed: false),
        .init(id: "m-roundup", title: "Round-up 5 days", desc: "Save your spare change", icon: "arrow.triangle.2.circlepath", xp: 130, coins: 50, category: "weekly", progress: 0, target: 5, claimed: false),
        .init(id: "s-invite", title: "Invite a friend", desc: "You both earn 200 coins", icon: "person.2", xp: 200, coins: 100, category: "social", progress: 0, target: 1, claimed: false),
    ]
    static let rewards: [Reward] = [
        .init(id: "r-spotify", title: "1 month Spotify", brand: "Spotify", icon: "music.note", cost: 300),
        .init(id: "r-coffee", title: "€5 coffee voucher", brand: "Mulliri Vjetër", icon: "cup.and.saucer", cost: 150),
        .init(id: "r-cinema", title: "Cinema ticket", brand: "Kinema Millennium", icon: "film", cost: 250),
        .init(id: "r-cashback", title: "+1% cashback boost", brand: "Ryze", icon: "bolt.fill", cost: 400, tierMin: 1),
        .init(id: "r-data", title: "5GB mobile data", brand: "ONE", icon: "antenna.radiowaves.left.and.right", cost: 200),
        .init(id: "r-merch", title: "Ryze hoodie", brand: "Ryze", icon: "tshirt", cost: 800, tierMin: 2),
        .init(id: "r-glovo", title: "20% off Glovo", brand: "Glovo", icon: "bag.fill", cost: 200),
        .init(id: "r-kfc", title: "Free KFC box", brand: "KFC", icon: "takeoutbag.and.cup.and.straw.fill", cost: 350),
        .init(id: "r-game", title: "1 month Game Pass", brand: "Xbox", icon: "gamecontroller.fill", cost: 500, tierMin: 1),
        .init(id: "r-fashion", title: "15% off Pull&Bear", brand: "Pull&Bear", icon: "tshirt.fill", cost: 250),
    ]
    static let seedBadges: [Badge] = [
        .init(id: "b-first-invite", title: "Connector", icon: "person.2.fill", desc: "Invited your first friend", earned: false),
        .init(id: "b-streak7", title: "On Fire", icon: "flame.fill", desc: "7-day streak", earned: false),
        .init(id: "b-level10", title: "Pro", icon: "trophy.fill", desc: "Reached level 10", earned: false),
        .init(id: "b-onboard", title: "All Set", icon: "checkmark.seal.fill", desc: "Finished onboarding", earned: false),
        .init(id: "b-squad", title: "Team Player", icon: "person.3.fill", desc: "Completed a squad goal", earned: false),
        .init(id: "b-saver", title: "Stacker", icon: "banknote.fill", desc: "Saved €100 total", earned: false),
    ]
    // Discovery-map spots — normalized (x,y) positions on a stylized Tirana map. Visit to unlock.
    static let discoverySpots: [DiscoverySpot] = [
        .init(id: "skanderbeg", name: "Skanderbeg Square", sub: "Landmark", icon: "flag.fill", x: 0.50, y: 0.44, points: 60, respect: 20, kind: .landmark),
        .init(id: "ethem", name: "Et'hem Bey Mosque", sub: "Landmark", icon: "building.columns.fill", x: 0.56, y: 0.40, points: 50, respect: 15, kind: .landmark),
        .init(id: "pyramid", name: "Pyramid of Tirana", sub: "Landmark", icon: "triangle.fill", x: 0.40, y: 0.55, points: 60, respect: 20, kind: .landmark),
        .init(id: "toptani", name: "Toptani Center", sub: "Shopping", icon: "cart.fill", x: 0.58, y: 0.34, points: 50, respect: 15, kind: .shop),
        .init(id: "pazari", name: "Pazari i Ri", sub: "Market", icon: "basket.fill", x: 0.68, y: 0.31, points: 45, respect: 14, kind: .shop),
        .init(id: "blok", name: "Blloku", sub: "Nightlife", icon: "music.note", x: 0.45, y: 0.63, points: 40, respect: 12, kind: .spot),
        .init(id: "atm-blok", name: "Raiffeisen ATM · Blloku", sub: "ATM", icon: "banknote.fill", x: 0.53, y: 0.67, points: 30, respect: 10, kind: .atm),
        .init(id: "atm-center", name: "Raiffeisen ATM · Center", sub: "ATM", icon: "banknote.fill", x: 0.60, y: 0.48, points: 30, respect: 10, kind: .atm),
        .init(id: "uni", name: "University of Tirana", sub: "Landmark", icon: "graduationcap.fill", x: 0.44, y: 0.77, points: 40, respect: 12, kind: .landmark),
        .init(id: "park", name: "Grand Park & Lake", sub: "Park", icon: "leaf.fill", x: 0.57, y: 0.82, points: 40, respect: 12, kind: .park),
        .init(id: "teg", name: "TEG Mall", sub: "Shopping", icon: "bag.fill", x: 0.80, y: 0.80, points: 50, respect: 15, kind: .shop),
        .init(id: "dajti", name: "Dajti Ekspres", sub: "Cable car", icon: "cablecar.fill", x: 0.87, y: 0.20, points: 70, respect: 25, kind: .landmark),
    ]
    static let seedSquad = Squad(name: "Tirana Crew", goalTitle: "Invite 10 friends together", goal: 10, progress: 4, rewardCoins: 500,
        members: [.init(id: "m0", name: "You", contributed: 1), .init(id: "m1", name: "Elsa", contributed: 2), .init(id: "m2", name: "Drin", contributed: 1)])
}

struct Squad: Codable { let name: String; let goalTitle: String; let goal: Int; var progress: Int; let rewardCoins: Int; var members: [SquadMember] }
