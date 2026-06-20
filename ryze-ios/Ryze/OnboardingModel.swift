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
        .init(id: "phone", title: T("What's your number?", "Sa e ke numrin?"),
              body: T("We'll text you a code to confirm it's you. Your phone keeps your account secure and is never used for marketing without your say-so.", "Do të të dërgojmë një kod për të konfirmuar se je ti. Numri yt e mban llogarinë të sigurt dhe nuk përdoret kurrë për marketing pa lejen tënde."),
              why: T("We verify your phone so only you can reach the account. Albania's code is +355.", "E verifikojmë numrin që vetëm ti të hysh në llogari. Kodi i Shqipërisë është +355.")),
        .init(id: "otp", title: T("Enter your code", "Vendos kodin"),
              body: T("We sent a 6-digit code to your phone. Keep it private, staff will never ask for it. (Demo: any 6 digits work.)", "Të dërguam një kod me 6 shifra. Mbaje privat, stafi nuk do ta kërkojë kurrë. (Demo: çdo 6 shifra funksionojnë.)"),
              why: T("The one-time code proves the phone is yours. Never share it.", "Kodi njëpërdorimsh provon se numri është yti. Mos ia jep askujt.")),
        .init(id: "identity", title: T("Verify it's you", "Verifiko që je ti"),
              body: T("Two quick taps: scan your ID, then a fast face check. It's fully automatic, no human watches your video.", "Dy hapa të shpejtë: skano letërnjoftimin, pastaj një verifikim i shpejtë i fytyrës. Plotësisht automatik, asnjë person nuk e sheh videon tënde."),
              why: T("By law a bank confirms who you are (KYC, Know Your Customer). No person reviews your video live.", "Me ligj, banka konfirmon kush je (KYC, Njih Klientin Tënd). Asnjë person nuk e shqyrton videon drejtpërdrejt."),
              image: "identity"),
        .init(id: "details", title: T("Confirm your details", "Konfirmo të dhënat"),
              body: T("We read these from your ID, just check they're right. You must be 18 to open this account on your own.", "I lexuam nga letërnjoftimi yt, vetëm sigurohu që janë të sakta. Duhet të jesh 18 vjeç për ta hapur këtë llogari vetë."),
              why: T("We confirm you're 18+ (full legal capacity in Albania) and that your name matches your ID.", "Konfirmojmë që je mbi 18 vjeç (zotësi e plotë juridike në Shqipëri) dhe që emri përputhet me letërnjoftimin.")),
        .init(id: "consents", title: T("The agreements", "Marrëveshjet"),
              body: T("Have a read and tick what applies. The first ones are required to open your account; marketing is your choice.", "Lexoji dhe shëno ato që vlejnë. Të parat janë të detyrueshme për të hapur llogarinë; marketingu është zgjedhja jote."),
              why: T("These consents record your agreement, as every regulated bank must.", "Këto pëlqime regjistrojnë miratimin tënd, siç kërkon çdo bankë e rregulluar.")),
        .init(id: "notifications", title: T("Stay one step ahead", "Rri një hap përpara"),
              body: T("Get alerts for security codes, payments, streaks and rewards. Optional, change it anytime in Settings.", "Merr njoftime për kodet e sigurisë, pagesat, seritë dhe shpërblimet. Opsionale, ndryshoje kurdo te Cilësimet."),
              why: T("Alerts help you catch anything odd early. It's optional.", "Njoftimet të ndihmojnë të kapësh herët çdo gjë të çuditshme. Janë opsionale.")),
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
            guard let age = ageFromDob(draft["dob"] ?? "") else { ageError = T("Please enter your date of birth as DD/MM/YYYY.", "Vendos datën e lindjes në formatin DD/MM/VVVV."); return }
            if age < 18 { ageError = T("Ryze is for ages 18-25, come back when you turn 18. That's the only reason.", "Ryze është për moshat 18-25, kthehu kur të mbushësh 18. Kjo është e vetmja arsye."); return }
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
