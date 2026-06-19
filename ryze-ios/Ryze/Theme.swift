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
    static let void = Color(hex: 0x000000)            // reserved for the balance hero only
    static let bg = Color(hex: 0x0B0B0D)              // warm graphite canvas
    static let elev1 = Color(hex: 0x141417)
    static let elev2 = Color(hex: 0x1B1B1F)
    static let elev3 = Color(hex: 0x232328)
    static let surface = elev2                         // keep name for existing refs
    static let surfaceDeep = Color(hex: 0x0A0A0A)
    static let surfacePressed = elev3
    static let yellow = Color(hex: 0xFFE600)           // scarce: rings, ticks, glyphs, progress
    static let goldTop = Color(hex: 0xFFE45C)
    static let goldBot = Color(hex: 0xCF9A00)
    static let goldEdge = Color(hex: 0xFFF0A8)
    static var gold: LinearGradient { LinearGradient(stops: [.init(color: Color(hex: 0xFFE45C), location: 0), .init(color: Color(hex: 0xF2C200), location: 0.45), .init(color: Color(hex: 0xCF9A00), location: 1)], startPoint: .top, endPoint: .bottom) }
    static let onAccent = Color.black
    static let text = Color.white
    static let mute = Color.white.opacity(0.62)
    static let faint = Color.white.opacity(0.40)
    static let hairline = Color.white.opacity(0.08)
    static let good = Color(hex: 0x3CE0A0)
    static let danger = Color(hex: 0xE23B4A)
    static let violet = Color(hex: 0x7C5CFF)
    static let mint = Color(hex: 0x34E2B0)
    static let pink = Color(hex: 0xFF5C8A)
}

extension View {
    func specularBorder(_ radius: CGFloat) -> some View {
        overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(LinearGradient(colors: [Color.white.opacity(0.14), Color.white.opacity(0.03)], startPoint: .top, endPoint: .bottom), lineWidth: 1))
    }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration c: Configuration) -> some View {
        c.label.scaleEffect(c.isPressed ? 0.95 : 1).animation(.spring(response: 0.28, dampingFraction: 0.55), value: c.isPressed)
    }
}

// The Ryze signature shape — a flat-top hexagon used for the points glyph + celebration particles.
struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let pts = (0..<6).map { i -> CGPoint in
            let a = Double(i) * .pi / 3 - .pi / 2
            return CGPoint(x: rect.midX + rect.width / 2 * CGFloat(cos(a)), y: rect.midY + rect.height / 2 * CGFloat(sin(a)))
        }
        p.move(to: pts[0]); pts.dropFirst().forEach { p.addLine(to: $0) }; p.closeSubpath()
        return p
    }
}

// Signature celebration: yellow hexagon particles bursting outward, keyed to a trigger.
struct CelebrationOverlay: View {
    let trigger: Int
    @State private var t: CGFloat = 1
    private let count = 16
    var body: some View {
        GeometryReader { g in
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    let a = Double(i) / Double(count) * 2 * .pi
                    Hexagon().fill(i % 3 == 0 ? Color.white : Brand.yellow)
                        .frame(width: 13, height: 13)
                        .opacity(Double(1 - t))
                        .offset(x: CGFloat(cos(a)) * 170 * t, y: CGFloat(sin(a)) * 170 * t - 30)
                        .rotationEffect(.degrees(Double(t) * 200))
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
