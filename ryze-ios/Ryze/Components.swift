import SwiftUI
import MapKit

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
        Button(action: action) { label }.buttonStyle(PressStyle())
    }
    @ViewBuilder private var label: some View {
        let base = Text(title).font(.system(size: 17, weight: .semibold)).foregroundColor(Brand.text)
            .frame(maxWidth: .infinity).frame(height: 54)
        if #available(iOS 26.0, *) {
            base.glassEffect(.regular, in: .capsule)
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.16), lineWidth: 1))
        } else {
            base.overlay(Capsule().stroke(Brand.text, lineWidth: 1))
        }
    }
}

struct RyzeField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var prefix: String? = nil
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    var autocaps: TextInputAutocapitalization = .sentences
    @FocusState private var focused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased()).font(.system(size: 12, weight: .medium)).foregroundColor(Brand.mute).tracking(0.4)
            HStack(spacing: 8) {
                if let p = prefix { Text(p).font(.system(size: 17)).foregroundColor(Brand.text) }
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Brand.faint))
                    .focused($focused).keyboardType(keyboard).foregroundColor(Brand.text)
                    .textContentType(contentType).textInputAutocapitalization(autocaps)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16).frame(height: 56)
            .liquidSurface(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(focused ? Brand.text : .clear, lineWidth: 1.5))
        }
    }
}

// Native date wheel/calendar — guarantees DD/MM/YYYY, no manual "/" typing.
struct RyzeDateField: View {
    let label: String
    @Binding var text: String          // stored as dd/MM/yyyy
    @State private var date = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    private static let fmt: DateFormatter = { let f = DateFormatter(); f.calendar = Calendar(identifier: .gregorian); f.locale = Locale(identifier: "en_GB"); f.dateFormat = "dd/MM/yyyy"; return f }()
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased()).font(.system(size: 12, weight: .medium)).foregroundColor(Brand.mute).tracking(0.4)
            HStack(spacing: 8) {
                Image(systemName: "calendar").font(.system(size: 15)).foregroundColor(Brand.mute)
                DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.compact).labelsHidden().tint(Brand.yellow)
                Spacer()
            }
            .padding(.horizontal, 16).frame(height: 56).liquidSurface(12)
        }
        // Hydrate the wheel from an existing value, but DON'T seed draft["dob"] — leave it empty
        // until the user actually picks, so the age gate can't pass on an un-entered birthday.
        .onAppear { if let d = Self.fmt.date(from: text) { date = d } }
        .onChange(of: date) { _, d in text = Self.fmt.string(from: d) }
    }
}

// MARK: - Address autocomplete (MapKit MKLocalSearchCompleter, biased to Albania)
final class AddressCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
        completer.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 41.33, longitude: 19.82),
                                              latitudinalMeters: 250_000, longitudinalMeters: 250_000)
    }
    func update(_ q: String) {
        let t = q.trimmingCharacters(in: .whitespaces)
        if t.count < 3 { results = [] } else { completer.queryFragment = t }
    }
    func clear() { results = [] }
    func completerDidUpdateResults(_ c: MKLocalSearchCompleter) { results = Array(c.results.prefix(4)) }
    func completer(_ c: MKLocalSearchCompleter, didFailWithError error: Error) { results = [] }
}

struct AddressAutocompleteField: View {
    let label: String
    @Binding var street: String
    var onPick: (_ street: String, _ city: String, _ postal: String) -> Void
    @StateObject private var completer = AddressCompleter()
    @FocusState private var focused: Bool
    @State private var suppress = false   // skip the query that our own pick() write would trigger
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased()).font(.system(size: 12, weight: .medium)).foregroundColor(Brand.mute).tracking(0.4)
            TextField("", text: $street, prompt: Text(T("Start typing your address", "Fillo të shkruash adresën")).foregroundColor(Brand.faint))
                .focused($focused).foregroundColor(Brand.text).autocorrectionDisabled()
                .textContentType(.fullStreetAddress)
                .padding(.horizontal, 16).frame(height: 56).liquidSurface(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(focused ? Brand.text : .clear, lineWidth: 1.5))
                .onChange(of: street) { _, v in if suppress { suppress = false } else { completer.update(v) } }
                // Clear suggestions only after focus truly leaves (delayed so a pending row tap still lands).
                .onChange(of: focused) { _, f in if !f { DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { if !focused { completer.clear() } } } }
            // Not gated on `focused`: keeping the list mounted through the tap lets the Button action fire
            // instead of being cancelled when the keyboard resigns first responder.
            if !completer.results.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(completer.results.enumerated()), id: \.offset) { i, r in
                        Button { pick(r) } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "mappin.circle.fill").font(.system(size: 16)).foregroundColor(Brand.yellow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.title).font(.system(size: 15)).foregroundColor(Brand.text)
                                    if !r.subtitle.isEmpty { Text(r.subtitle).font(.system(size: 12)).foregroundColor(Brand.mute).lineLimit(1) }
                                }
                                Spacer(minLength: 0)
                            }.padding(.vertical, 10).padding(.horizontal, 14).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                        if i < completer.results.count - 1 { Divider().background(Brand.hairline) }
                    }
                }.liquidSurface(12)
            }
        }
    }
    private func pick(_ r: MKLocalSearchCompletion) {
        MKLocalSearch(request: .init(completion: r)).start { resp, _ in
            let p = resp?.mapItems.first?.placemark
            let st = [p?.subThoroughfare, p?.thoroughfare].compactMap { $0 }.joined(separator: " ")
            DispatchQueue.main.async {                 // MapKit usually calls back on main; be explicit + deterministic
                suppress = true
                street = st.isEmpty ? r.title : st
                completer.clear()
                focused = false
                onPick(street, p?.locality ?? "", p?.postalCode ?? "")
            }
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
            .frame(width: 46, height: 56)
            .liquidSurface(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(i == code.count ? Brand.text : .clear, lineWidth: 1.5))
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
