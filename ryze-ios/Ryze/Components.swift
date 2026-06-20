import SwiftUI

struct PrimaryButton: View {
    let title: String
    var enabled: Bool = true
    let action: () -> Void
    var body: some View {
        Button(action: { if enabled { action() } }) {
            Text(title).font(.system(size: 17, weight: .semibold)).foregroundColor(Brand.onText)
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(Brand.text).clipShape(Capsule())
        }
        .buttonStyle(PressStyle())
        .opacity(enabled ? 1 : 0.35)
        .animation(.easeOut(duration: 0.15), value: enabled)
    }
}

struct GhostButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.system(size: 17, weight: .semibold)).foregroundColor(Brand.text)
                .frame(maxWidth: .infinity).frame(height: 54)
                .overlay(Capsule().stroke(Brand.text, lineWidth: 1))
        }.buttonStyle(PressStyle())
    }
}

struct RyzeField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var prefix: String? = nil
    var keyboard: UIKeyboardType = .default
    @FocusState private var focused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased()).font(.system(size: 12, weight: .medium)).foregroundColor(Brand.mute).tracking(0.4)
            HStack(spacing: 8) {
                if let p = prefix { Text(p).font(.system(size: 17)).foregroundColor(Brand.text) }
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Brand.faint))
                    .focused($focused).keyboardType(keyboard).foregroundColor(Brand.text)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16).frame(height: 56)
            .background(Brand.surface)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(focused ? Brand.text : Brand.hairline, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct OtpField: View {
    @Binding var code: String
    @FocusState private var focused: Bool
    var body: some View {
        ZStack {
            TextField("", text: $code).keyboardType(.numberPad).focused($focused)
                .foregroundColor(.clear).tint(.clear).frame(height: 1).opacity(0.02)
                .onChange(of: code) { _, n in code = String(n.filter(\.isNumber).prefix(6)) }
            HStack(spacing: 8) { ForEach(0..<6, id: \.self) { cell($0) } }
                .contentShape(Rectangle()).onTapGesture { focused = true }
        }
        .onAppear { focused = true }
    }
    private func cell(_ i: Int) -> some View {
        let chars = Array(code)
        let ch = i < chars.count ? String(chars[i]) : ""
        return Text(ch).font(.system(size: 22, weight: .semibold)).foregroundColor(Brand.text)
            .frame(width: 46, height: 56).background(Brand.surface)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(i == code.count ? Brand.text : Brand.hairline, lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ConsentRowView: View {
    let consent: ConsentDef
    let checked: Bool
    let onToggle: () -> Void
    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(checked ? Brand.yellow : Color.clear)
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(checked ? Brand.yellow : Brand.hairline, lineWidth: 1.5))
                        .frame(width: 24, height: 24)
                    if checked { Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundColor(.black) }
                }
                Text(consent.label).font(.system(size: 13)).foregroundColor(Brand.text)
                    .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

struct ProgressBar: View {
    var value: Double
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Brand.hairline)
                Capsule().fill(Brand.yellow).frame(width: max(6, g.size.width * value))
            }
        }
        .frame(height: 4)
        .animation(.easeInOut(duration: 0.3), value: value)
    }
}

struct LogoTile: View {
    var size: CGFloat = 56
    var body: some View {
        Image("RaiffeisenLogo").resizable().scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.28))
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View {
        HStack(spacing: 7) { Capsule().fill(Brand.yellowInk).frame(width: 14, height: 2); Text(text.uppercased()).font(.system(size: 11, weight: .semibold)).tracking(1.4).foregroundColor(Brand.faint) }
    }
}
