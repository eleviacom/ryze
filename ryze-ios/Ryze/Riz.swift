import Foundation

// Riz — the AI buddy. Hard safety guard + offline local replies (no API key needed
// for the demo). A real backend proxy can replace localReply later.
struct RizMessage: Identifiable, Equatable {
    let id = UUID()
    let fromUser: Bool
    let text: String
}

enum Riz {
    static func guardInput(_ t: String) -> String? {
        let s = t.lowercased()
        if s.range(of: #"\b\d{4,8}\b"#, options: .regularExpression) != nil
            || s.contains("otp") || s.contains("pin") || s.contains("password") || s.contains("cvv") || s.contains("code") {
            return "Don’t share codes, PINs or passwords with anyone — including me. Just enter the code on the screen above. (Hard rule, for your safety.)"
        }
        if s.contains("fraud") || s.contains("stolen") || s.contains("blocked") || s.contains("complain") {
            return "That’s one for a real person on the Raiffeisen team. Want me to point you to in-app support?"
        }
        if s.contains("should i") || s.contains("which account") || s.contains("recommend") || s.contains("invest") {
            return "I can explain how the options work, but what’s right for your money is your call — I can’t advise on that. Want me to connect you with a Raiffeisen specialist?"
        }
        return nil
    }

    static func reply(stepWhy: String?, text: String) -> String {
        if let g = guardInput(text) { return g }
        let s = text.lowercased()
        if s.contains("safe") || s.contains("secure") || s.contains("trust") || s.contains("privacy") || s.contains("protect") {
            return "Yes. Raiffeisen is supervised by the Bank of Albania, your deposits are insured by the ASD, and your data is handled under Albanian Law No. 124/2024. We use these details only to open and run your account."
        }
        if s.contains("how long") || s.contains("time") || s.contains("quick") {
            return "It takes a few minutes. Nothing is submitted until the final step, so take your time."
        }
        if let w = stepWhy { return w }
        return "I’m here to explain any step — ask me what something means or why it’s needed."
    }
}
