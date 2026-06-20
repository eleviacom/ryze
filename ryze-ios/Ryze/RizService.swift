import Foundation

// Riz is LIVE when `endpoint` is set. Empty endpoint -> built-in offline replies.
enum RizConfig {
    static let endpoint = "https://ollama.com/api/chat"
    static let model = "gpt-oss:120b"
    static let apiKey = RizSecret.ollamaKey
    static var isConfigured: Bool { !endpoint.isEmpty }
}

struct RizService {
    static func reply(history: [RizMessage], context: String) async -> String? {
        guard RizConfig.isConfigured, let url = URL(string: RizConfig.endpoint) else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 45)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !RizConfig.apiKey.isEmpty { req.setValue("Bearer \(RizConfig.apiKey)", forHTTPHeaderField: "Authorization") }
        var messages: [[String: String]] = [["role": "system", "content": systemPrompt(context: context)]]
        for m in history.suffix(16) { messages.append(["role": m.fromUser ? "user" : "assistant", "content": m.text]) }
        let body: [String: Any] = ["model": RizConfig.model, "messages": messages, "stream": false, "options": ["temperature": 0.6]]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) ?? false,
                  let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
            if let m = j["message"] as? [String: Any], let c = m["content"] as? String, !c.isEmpty { return clean(c) }
            if let ch = j["choices"] as? [[String: Any]], let m = ch.first?["message"] as? [String: Any], let c = m["content"] as? String { return clean(c) }
            if let c = j["reply"] as? String { return clean(c) }
            if let c = j["content"] as? String { return clean(c) }
            return nil
        } catch { return nil }
    }

    // Strip only typographic dashes/ellipses; keep markdown (* - |) for the rich renderer.
    static func clean(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "—", with: ", ").replacingOccurrences(of: "–", with: "-").replacingOccurrences(of: "…", with: "...").replacingOccurrences(of: "--", with: ", ")
    }

    static func systemPrompt(context: String) -> String {
        """
        You are Riz, the in-app money assistant for Ryze, a youth banking app by Raiffeisen Bank Albania (ages 18-25).

        STYLE (strict)
        - Be VERY short: 1-2 sentences max, plus AT MOST one visual block. Never write long paragraphs or stack multiple charts.
        - Warm, upbeat, young. A tasteful emoji is fine. Use plain commas and hyphens, never long dashes or "--".
        - Reply ONLY in the language given by "Reply language" in USER CONTEXT (Albanian = standard Albanian used in Albania). All text inside visual blocks must be in that language too.
        - Money: Albanian Lek looks like "1,500 L"; Euro like "€312".

        VISUALS (rendered by the app as cards, so keep labels short)
        - Use ONE block only when it truly helps, else just 1-2 sentences.
        - Spend breakdown / comparison -> ```ryze-chart  (Label: number, short labels)
        - Goal or budget progress -> ```ryze-progress  (Title: saved/total)
        - 2-3 headline figures -> ```ryze-stats  (Label: value)
        - Plan comparison -> a small markdown table.

        KNOWLEDGE: RyzePoints (1 pt per 200 L x plan: Spark 1x, Lift 2x, Surge 4x, Apex 5x), plans, streaks, quests, squads, savings round-ups, fee-free FX, virtual/physical cards.
        RULES: Use only the figures in USER CONTEXT, never invent. Stay on money/Ryze. Never ask for passwords, PINs, OTP or card numbers. It is a prototype: point to in-app actions, do not claim to move real money.

        USER CONTEXT:
        \(context)
        """
    }
}
