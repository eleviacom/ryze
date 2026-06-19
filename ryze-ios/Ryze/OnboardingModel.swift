import SwiftUI

struct KycStepDef: Identifiable {
    let id: String
    let title: String
    let body: String
    let why: String
    var image: String? = nil
}

final class OnboardingModel: ObservableObject {
    enum Phase { case value, kyc, success }

    @Published var phase: Phase = .value
    @Published var slideIndex = 0
    @Published var stepIndex = 0
    @Published var draft: [String: String] = [:]
    @Published var consents: Set<String> = []
    @Published var otp = ""
    @Published var idScanned = false
    @Published var faceChecked = false
    @Published var ageError: String? = nil

    init() {
        // ponytail: QA-only deep-link via env (unset in production)
        let e = ProcessInfo.processInfo.environment
        switch e["RYZE_PHASE"] { case "kyc": phase = .kyc; case "success": phase = .success; default: break }
        if let n = e["RYZE_STEP"], let i = Int(n) { stepIndex = i }
        if let n = e["RYZE_SLIDE"], let i = Int(n) { slideIndex = i }
        if e["RYZE_PREFILL"] != nil {
            draft["phone"] = "69 123 456"; draft["firstName"] = "Klevi"; draft["lastName"] = "Berisha"
            draft["dob"] = "14/03/2004"; draft["email"] = "klevi@ryze.al"; otp = "123456"
        }
        if e["RYZE_FLAGS"] != nil { idScanned = true; faceChecked = true }
        if e["RYZE_CONSENT"] != nil { consents = Set(Legal.consents.filter(\.mandatory).map(\.id)) }
    }

    let steps: [KycStepDef] = [
        .init(id: "phone", title: "What’s your number?",
              body: "We’ll text you a code to confirm it’s you. Your phone keeps your account secure — never used for marketing without your say-so.",
              why: "We verify your phone so only you can reach the account. Albania’s code is +355."),
        .init(id: "otp", title: "Enter your code",
              body: "We sent a 6-digit code to your phone. Keep it private — staff will never ask for it. (Demo: any 6 digits work.)",
              why: "The one-time code proves the phone is yours. Never share it."),
        .init(id: "identity", title: "Verify it’s you",
              body: "Two quick taps: scan your ID, then a fast face check. It’s fully automatic — no human watches your video.",
              why: "By law a bank confirms who you are (KYC, “Know Your Customer”). No person reviews your video live.",
              image: "identity"),
        .init(id: "details", title: "Confirm your details",
              body: "We read these from your ID — just check they’re right. You must be 18 to open this account on your own.",
              why: "We confirm you’re 18+ (full legal capacity in Albania) and that your name matches your ID."),
        .init(id: "consents", title: "The agreements",
              body: "Have a read and tick what applies. The first ones are required to open your account; marketing is your choice.",
              why: "These consents record your agreement, as every regulated bank must."),
        .init(id: "notifications", title: "Stay one step ahead",
              body: "Get alerts for security codes, payments, streaks and rewards. Optional — change it anytime in Settings.",
              why: "Alerts help you catch anything odd early. It’s optional."),
    ]

    var current: KycStepDef { steps[min(stepIndex, steps.count - 1)] }
    var progress: Double { Double(stepIndex + 1) / Double(steps.count) }

    // MARK: validation
    func ageFromDob(_ s: String) -> Int? {
        let p = s.split(separator: "/")
        guard p.count == 3, let d = Int(p[0]), let m = Int(p[1]), let y = Int(p[2]) else { return nil }
        var c = DateComponents(); c.year = y; c.month = m; c.day = d
        guard let birth = Calendar.current.date(from: c) else { return nil }
        return Calendar.current.dateComponents([.year], from: birth, to: Date()).year
    }

    var canContinue: Bool {
        switch current.id {
        case "phone": return (draft["phone"] ?? "").filter(\.isNumber).count >= 6
        case "otp": return otp.count == 6
        case "identity": return idScanned && faceChecked
        case "details":
            let name = !(draft["firstName"] ?? "").isEmpty && !(draft["lastName"] ?? "").isEmpty
            return name && ageFromDob(draft["dob"] ?? "") != nil
        case "consents": return Legal.consents.filter(\.mandatory).allSatisfy { consents.contains($0.id) }
        default: return true
        }
    }

    // MARK: navigation
    func startKyc() { withAnimation(.easeInOut) { phase = .kyc } }

    func next() {
        if current.id == "details" {
            guard let age = ageFromDob(draft["dob"] ?? "") else { ageError = "Please enter your date of birth as DD/MM/YYYY."; return }
            if age < 18 { ageError = "Ryze is for ages 18–25 — come back when you turn 18. That’s the only reason."; return }
            ageError = nil
        }
        if stepIndex < steps.count - 1 {
            withAnimation(.easeInOut(duration: 0.28)) { stepIndex += 1 }
        } else {
            withAnimation(.easeInOut) { phase = .success }
        }
    }

    func back() {
        if stepIndex > 0 { withAnimation(.easeInOut(duration: 0.25)) { stepIndex -= 1; ageError = nil } }
        else { withAnimation(.easeInOut) { phase = .value } }
    }

    func toggleConsent(_ id: String) {
        if consents.contains(id) { consents.remove(id) } else { consents.insert(id) }
    }

    // MARK: simulated KYC (demo)
    func simulateScan() {
        withAnimation(.spring) { idScanned = true }
        draft["firstName"] = draft["firstName"] ?? "Klevi"
        draft["lastName"] = draft["lastName"] ?? "Berisha"
        draft["dob"] = draft["dob"] ?? "14/03/2004"
    }
    func simulateFace() { withAnimation(.spring) { faceChecked = true } }
}
