import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: alpha)
    }
}

// Revolut system + Raiffeisen yellow as the single scarce stamp.
enum Brand {
    static let bg = Color(hex: 0x000000)        // pure black; art now has flat black bg
    static let surface = Color(hex: 0x16181A)   // elevated card
    static let surfaceDeep = Color(hex: 0x0A0A0A)
    static let yellow = Color(hex: 0xFFE600)
    static let goldTop = Color(hex: 0xFFE600)
    static let goldBot = Color(hex: 0xF5B700)
    static var gold: LinearGradient { LinearGradient(colors: [goldTop, goldBot], startPoint: .topLeading, endPoint: .bottomTrailing) }
    static let onAccent = Color.black
    static let text = Color.white
    static let mute = Color.white.opacity(0.62)
    static let faint = Color.white.opacity(0.40)
    static let hairline = Color.white.opacity(0.12)
    static let good = Color(hex: 0x3CE0A0)
    static let danger = Color(hex: 0xE23B4A)
    static let violet = Color(hex: 0x7C5CFF)
    static let mint = Color(hex: 0x34E2B0)
    static let pink = Color(hex: 0xFF5C8A)
}

extension Text {
    func display(_ size: CGFloat = 40) -> Text { self.font(.system(size: size, weight: .bold, design: .default)).tracking(-1) }
}
