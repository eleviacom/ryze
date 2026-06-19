import SwiftUI

// MARK: - Domain
struct Mission: Identifiable {
    let id: String; let title: String; let desc: String; let icon: String
    let xp: Int; let coins: Int; let category: String
    var progress: Int; let target: Int; var claimed: Bool; var aiGenerated: Bool = false
}
struct Reward: Identifiable { let id: String; let title: String; let brand: String; let icon: String; let cost: Int; var tierMin: Int = 0 }
struct Badge: Identifiable { let id: String; let title: String; let icon: String; let desc: String; var earned: Bool }
struct LeaderRow: Identifiable { let id: String; let name: String; let xp: Int; var you: Bool = false }
struct SquadMember: Identifiable { let id: String; let name: String; var contributed: Int }
struct Toast: Equatable { let label: String; let xp: Int; let coins: Int }

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
    @Published var celebrate = 0
    let referralCode = "RYZE-\(Int.random(in: 1000...9999))"

    init() {
        if ProcessInfo.processInfo.environment["RYZE_HOME"] != nil {
            name = "Klevi"; xp = 320; coins = 480; streak = 4; kycVerified = true; onboarded = true
            if let i = missions.firstIndex(where: { $0.id == "ob-verify" }) { missions[i].progress = 1; missions[i].claimed = true }
        }
    }

    var li: LevelInfo { levelInfo(xp) }
    var tier: Tier { tierForLevel(li.level).0 }
    var tierIndex: Int { tierForLevel(li.level).1 }

    static let leaderboard: [LeaderRow] = [
        .init(id: "l1", name: "Elsa", xp: 1840), .init(id: "l2", name: "Muhamed", xp: 1520),
        .init(id: "l3", name: "Aleks", xp: 980), .init(id: "l4", name: "Drin", xp: 610), .init(id: "l5", name: "Sara", xp: 430),
    ]

    private func today() -> String { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date()) }
    private func fire(_ label: String, _ xpG: Int, _ coinsG: Int) {
        toast = Toast(label: label, xp: xpG, coins: coinsG); celebrate += 1
        let snap = celebrate
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { if self.celebrate == snap { self.toast = nil } }
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
        if let n = name, !n.isEmpty { self.name = n }
        if let i = missions.firstIndex(where: { $0.id == "ob-verify" }) { missions[i].progress = missions[i].target; missions[i].claimed = true }
        xp += 120; coins += 50; kycVerified = true; evalBadges()
        fire("Account opened!", 120, 50)
        withAnimation(.easeInOut) { onboarded = true }
    }

    func resetDemo() {
        xp = 0; coins = 120; streak = 0; lastCheckIn = nil; savedTotal = 0; invites = 0
        redeemed = []; missions = GameModel.seedMissions; badges = GameModel.seedBadges
        squad = GameModel.seedSquad; aiMission = nil; onboarded = false; kycVerified = false; name = "Friend"
    }

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
    ]
    static let seedBadges: [Badge] = [
        .init(id: "b-first-invite", title: "Connector", icon: "person.2.fill", desc: "Invited your first friend", earned: false),
        .init(id: "b-streak7", title: "On Fire", icon: "flame.fill", desc: "7-day streak", earned: false),
        .init(id: "b-level10", title: "Pro", icon: "trophy.fill", desc: "Reached level 10", earned: false),
        .init(id: "b-onboard", title: "All Set", icon: "checkmark.seal.fill", desc: "Finished onboarding", earned: false),
        .init(id: "b-squad", title: "Team Player", icon: "person.3.fill", desc: "Completed a squad goal", earned: false),
        .init(id: "b-saver", title: "Stacker", icon: "banknote.fill", desc: "Saved €100 total", earned: false),
    ]
    static let seedSquad = Squad(name: "Tirana Crew", goalTitle: "Invite 10 friends together", goal: 10, progress: 4, rewardCoins: 500,
        members: [.init(id: "m0", name: "You", contributed: 1), .init(id: "m1", name: "Elsa", contributed: 2), .init(id: "m2", name: "Drin", contributed: 1)])
}

struct Squad { let name: String; let goalTitle: String; let goal: Int; var progress: Int; let rewardCoins: Int; var members: [SquadMember] }
