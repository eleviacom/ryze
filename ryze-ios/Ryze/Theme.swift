import SwiftUI
import UIKit

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: alpha)
    }
    init(lightHex: UInt, darkHex: UInt) {
        self = Color(uiColor: UIColor { t in UIColor(t.userInterfaceStyle == .dark ? Color(hex: darkHex) : Color(hex: lightHex)) })
    }
}

func T(_ en: String, _ sq: String) -> String { ((ProcessInfo.processInfo.environment["RYZE_LANG"] ?? UserDefaults.standard.string(forKey: "ryze_lang")) ?? "en") == "sq" ? sq : en }

// Revolut system + Raiffeisen yellow as the single scarce stamp.
enum Brand {
    static let void = Color(hex: 0x000000)            // balance hero + onboarding (art is flat-black; keep pure)
    static let bg = Color(lightHex: 0xF4F3EF, darkHex: 0x151412)        // warm charcoal, lifted off pure black
    static let elev1 = Color(lightHex: 0xFAFAF6, darkHex: 0x1E1C19)
    static let elev2 = Color(lightHex: 0xFFFFFF, darkHex: 0x272421)     // cards, visibly warm, not dead
    static let elev3 = Color(lightHex: 0xECEAE4, darkHex: 0x332F2B)
    static let surface = elev2
    static let surfaceDeep = Color(hex: 0x100F0D)
    static let surfacePressed = elev3
    static let yellow = Color(hex: 0xF8D01F)           // Banana Yellow, the brand stamp
    static let goldTop = Color(hex: 0xFFE470)
    static let goldBot = Color(hex: 0xD4A200)
    static let goldEdge = Color(hex: 0xFFEFA8)
    static var gold: LinearGradient { LinearGradient(stops: [.init(color: Color(hex: 0xFFE470), location: 0), .init(color: Color(hex: 0xF8D01F), location: 0.5), .init(color: Color(hex: 0xD4A200), location: 1)], startPoint: .top, endPoint: .bottom) }
    static let onAccent = Color.black
    static let yellowInk = Color(lightHex: 0xB8860B, darkHex: 0xF8D01F)   // yellow as foreground on adaptive (light/white) surfaces
    static let shadow1 = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor.black.withAlphaComponent(0.6) : UIColor.black.withAlphaComponent(0.05) })
    static let shadow2 = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor.black.withAlphaComponent(0.4) : UIColor.black.withAlphaComponent(0.08) })
    static let onText = Color(lightHex: 0xFFFFFF, darkHex: 0x000000)   // inverse of text: ink for high-contrast (Brand.text-bg) buttons/bubbles
    static let specularTop = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.14) : UIColor.black.withAlphaComponent(0.07) })
    static let specularBot = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.03) : UIColor.black.withAlphaComponent(0.02) })
    static let text = Color(lightHex: 0x131210, darkHex: 0xFFFFFF)
    static let mute = Color(lightHex: 0x6A6A66, darkHex: 0xB0B0B0)      // palette Gray
    static let faint = Color(lightHex: 0x83837C, darkHex: 0x76736D)
    static let hairline = Color(uiColor: UIColor { t in t.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.09) : UIColor.black.withAlphaComponent(0.10) })
    static let good = Color(lightHex: 0x12A86A, darkHex: 0x2FD98A)
    static let danger = Color(hex: 0xFF4D52)
    static let violet = Color(hex: 0x8B5CFF)
    static let mint = Color(hex: 0x2FE3B6)
    static let pink = Color(hex: 0xFF5C8A)
    static let coral = Color(hex: 0xFF6F47)
    static let sky = Color(hex: 0x46A8FF)
}

// Card personalisation styles (colour + ink), physical card + virtual + custom.
enum CardStyle: String, CaseIterable, Identifiable, Codable {
    case gold, midnight, coral, mint
    var id: String { rawValue }
    var title: String {
        switch self {
        case .gold: return T("Banana Gold", "Ari Banane")
        case .midnight: return T("Midnight", "Mesnatë")
        case .coral: return T("Coral", "Koral")
        case .mint: return T("Mint", "Mentë")
        }
    }
    var colors: [Color] {
        switch self {
        case .gold: return [Color(hex: 0xFFE470), Color(hex: 0xF8D01F), Color(hex: 0xD4A200)]
        case .midnight: return [Color(hex: 0x3A2E6E), Color(hex: 0x18161F)]
        case .coral: return [Color(hex: 0xFF8A5C), Color(hex: 0xD93D2E)]
        case .mint: return [Color(hex: 0x4DE9B6), Color(hex: 0x0F9E76)]
        }
    }
    var ink: Color { (self == .gold || self == .mint) ? .black : .white }
    var swatch: Color { colors.first ?? Brand.yellow }
}

extension View {
    func specularBorder(_ radius: CGFloat) -> some View {
        overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(LinearGradient(colors: [Brand.specularTop, Brand.specularBot], startPoint: .top, endPoint: .bottom), lineWidth: 1))
    }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration c: Configuration) -> some View {
        c.label.scaleEffect(c.isPressed ? 0.95 : 1).animation(.spring(response: 0.28, dampingFraction: 0.55), value: c.isPressed)
    }
}

// Signature celebration: yellow + white confetti (dots and chips) bursting outward, keyed to a trigger.
struct CelebrationOverlay: View {
    let trigger: Int
    @State private var t: CGFloat = 1
    private let count = 18
    var body: some View {
        GeometryReader { g in
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    let a = Double(i) / Double(count) * 2 * .pi
                    Group {
                        if i % 2 == 0 {
                            Circle().fill(i % 3 == 0 ? Color.white : Brand.yellow).frame(width: 10, height: 10)
                        } else {
                            RoundedRectangle(cornerRadius: 3).fill(i % 3 == 0 ? Color.white : Brand.yellow).frame(width: 12, height: 7)
                        }
                    }
                    .opacity(Double(1 - t))
                    .offset(x: CGFloat(cos(a)) * 175 * t, y: CGFloat(sin(a)) * 175 * t - 30)
                    .rotationEffect(.degrees(Double(t) * 220))
                }
            }
            .frame(width: g.size.width, height: g.size.height)
            .allowsHitTesting(false)
        }
        .onChange(of: trigger) { _, _ in t = 0; withAnimation(.easeOut(duration: 0.9)) { t = 1 } }
    }
}

extension Text {
    func display(_ size: CGFloat = 40) -> Text { self.font(.system(size: size, weight: .bold, design: .default)).tracking(-1) }
}
