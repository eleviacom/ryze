import SwiftUI
import UIKit
import AVFoundation

struct WhyInfo: Identifiable { let id = UUID(); let title: String; let body: String }

// Muted, gapless looping video for full-bleed onboarding heroes.
// ponytail: all visible pages decode at once (only 3 short loops); pause offscreen if it ever stutters.
struct LoopingVideo: UIViewRepresentable {
    let name: String
    func makeUIView(context: Context) -> LoopingVideoView { LoopingVideoView(name: name) }
    func updateUIView(_ uiView: LoopingVideoView, context: Context) {}
}

final class LoopingVideoView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    private let queue = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    init(name: String) {
        super.init(frame: .zero)
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp4") else { return }
        queue.isMuted = true
        queue.automaticallyWaitsToMinimizeStalling = false   // no stall/pause at the loop boundary
        looper = AVPlayerLooper(player: queue, templateItem: AVPlayerItem(url: url))
        playerLayer.player = queue
        playerLayer.videoGravity = .resizeAspectFill
        queue.play()
    }
    required init?(coder: NSCoder) { fatalError() }
}

struct OnboardingFlow: View {
    @StateObject private var model = OnboardingModel()
    @EnvironmentObject var game: GameModel
    @State private var why: WhyInfo? = nil

    var body: some View {
        ZStack {
            ZStack { Color.black; RadialGradient(colors: [Brand.yellow.opacity(0.08), .clear], center: .top, startRadius: 6, endRadius: 440) }.ignoresSafeArea()

            switch model.phase {
            case .value: WelcomeCarousel(model: model)
            case .kyc: KycContainer(model: model, onWhyTap: { step in why = WhyInfo(title: step.title, body: step.why ?? step.body) })
            case .success: SuccessView { game.completeAccount(name: model.draft["firstName"]) }
            }

            if model.phase == .value {
                Button { game.completeAccount(name: model.draft["firstName"] ?? "Klevi") } label: {
                    Text(T("Skip", "Kapërce")).font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.mute)
                        .padding(.horizontal, 14).frame(height: 32).liquidCapsule()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 16).padding(.top, 4)
            }
        }
        .environment(\.colorScheme, .dark)
        .sheet(item: $why) { w in
            VStack(alignment: .leading, spacing: 16) {
                Text(w.title).font(.system(size: 24, weight: .bold)).foregroundColor(Brand.text)
                Text(w.body).font(.system(size: 16)).foregroundColor(Brand.mute).lineSpacing(3)
                Spacer()
                PrimaryButton(title: T("Got it", "E kuptova")) { why = nil }
            }
            .padding(24).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Brand.bg).presentationDetents([.medium])
        }
    }
}

// MARK: - Value carousel — full-bleed looping video heroes (Revolut-style)
struct WelcomeCarousel: View {
    @ObservedObject var model: OnboardingModel
    struct Slide { let video, title, body, cta: String }
    let slides = [
        // onboard1 — spinning gold Raiffeisen coin: brand / the account itself
        Slide(video: "onboard1", title: T("Money that finally gets you", "Paratë që më në fund të kuptojnë"),
              body: T("Ryze is the Raiffeisen account built for your twenties. Spend, save and level up in one place that feels like yours.", "Ryze është llogaria e Raiffeisen, ndërtuar për të rinjtë. Shpenzo, kurse dhe ngjitu në nivel, në një vend që ndihet i yti."), cta: T("Continue", "Vazhdo")),
        // onboard2 — floating currency coins: the real feature is in-app ALL <-> EUR exchange
        Slide(video: "onboard2", title: T("Euro and lek, side by side", "Euro dhe lek, krah për krah"),
              body: T("Hold both currencies and exchange between them in seconds, with the rate shown before you confirm.", "Mbaji të dyja monedhat dhe këmbe mes tyre në sekonda, me kursin që shfaqet para se ta konfirmosh."), cta: T("Continue", "Vazhdo")),
        // onboard3 — stack of gold/midnight/coral/mint cards: your card, your style
        Slide(video: "onboard3", title: T("A card that's all you", "Një kartë krejt e jotja"),
              body: T("Banana gold, midnight, coral or mint. Pick your style and tap to pay the moment you're approved.", "Ar banane, mesnatë, koral apo mentë. Zgjidh stilin tënd dhe paguaj me një prekje sapo të aprovohesh."), cta: T("Get started", "Fillo")),
    ]

    var body: some View {
        ZStack {
            TabView(selection: $model.slideIndex) {
                ForEach(0..<slides.count, id: \.self) { i in
                    SlideView(slide: slides[i]).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .animation(.easeInOut, value: model.slideIndex)

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    LogoTile(size: 30)
                    Text(T("Welcome to Ryze", "Mirë se erdhe te Ryze")).font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 24).padding(.top, 8)

                HStack(spacing: 6) {
                    ForEach(0..<slides.count, id: \.self) { i in
                        Capsule().fill(i <= model.slideIndex ? Brand.yellow : Color.white.opacity(0.25)).frame(height: 3)
                    }
                }
                .padding(.horizontal, 24).padding(.top, 14)

                Spacer()

                PrimaryButton(title: slides[model.slideIndex].cta) {
                    if model.slideIndex < slides.count - 1 { withAnimation { model.slideIndex += 1 } }
                    else { model.startKyc() }
                }
                .padding(.horizontal, 24).padding(.bottom, 8)
            }
        }
    }
}

struct SlideView: View {
    let slide: WelcomeCarousel.Slide
    var body: some View {
        ZStack {
            LoopingVideo(name: slide.video).ignoresSafeArea()
            // Heavier scrim up top (behind the header + title) and at the bottom (behind the
            // button), leaving the middle clear so the hero art reads. Also rescues slide 3's cream.
            LinearGradient(stops: [
                .init(color: .black.opacity(0.78), location: 0.0),
                .init(color: .black.opacity(0.45), location: 0.28),
                .init(color: .clear, location: 0.46),
                .init(color: .clear, location: 0.72),
                .init(color: .black.opacity(0.85), location: 0.92),
                .init(color: .black, location: 1.0),
            ], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            // Title + body pinned to the top, under the logo/progress header (Revolut layout).
            VStack(alignment: .leading, spacing: 12) {
                Text(slide.title).display(33).foregroundColor(.white).fixedSize(horizontal: false, vertical: true)
                Text(slide.body).font(.system(size: 17)).foregroundColor(.white.opacity(0.78)).lineSpacing(3)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24).padding(.top, 96)
        }
    }
}

// MARK: - KYC container
struct KycContainer: View {
    @ObservedObject var model: OnboardingModel
    let onWhyTap: (KycStepDef) -> Void

    func cta(_ id: String) -> String {
        switch id {
        case "phone": return T("Send code", "Dërgo kodin")
        case "otp": return T("Verify", "Verifiko")
        case "identity": return T("Continue", "Vazhdo")
        case "details": return T("Confirm", "Konfirmo")
        case "consents": return T("Agree & open my account", "Prano dhe hap llogarinë")
        default: return T("Continue", "Vazhdo")
        }
    }

    var body: some View {
        let step = model.current
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button { model.back() } label: { Image(systemName: "xmark").font(.system(size: 18, weight: .semibold)).foregroundColor(Brand.yellow) }
                ProgressBar(value: model.progress)
                LogoTile(size: 28)
            }
            .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(step.title).display(32).foregroundColor(Brand.text).fixedSize(horizontal: false, vertical: true).padding(.bottom, 10)
                    Text(step.body).font(.system(size: 17)).foregroundColor(Brand.mute).lineSpacing(3)
                    Button { onWhyTap(step) } label: {
                        Text(T("Why do we need it?", "Pse na duhet?")).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.yellow)
                    }.padding(.top, 8)

                    StepBody(model: model).padding(.top, 24)
                }
                .padding(.horizontal, 24).padding(.top, 6)
                .id(model.stepIndex)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)))
            }

            VStack(spacing: 10) {
                if step.id == "notifications" {
                    PrimaryButton(title: T("I want to be notified", "Dua të njoftohem")) { model.next() }
                    GhostButton(title: T("Maybe later", "Ndoshta më vonë")) { model.next() }
                } else {
                    PrimaryButton(title: cta(step.id), enabled: model.canContinue) { model.next() }
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 8)
        }
    }
}

struct StepBody: View {
    @ObservedObject var model: OnboardingModel
    @State private var showScan = false
    @State private var showFace = false
    func bind(_ key: String) -> Binding<String> {
        Binding(get: { model.draft[key] ?? "" }, set: { model.draft[key] = $0 })
    }
    var body: some View {
        switch model.current.id {
        case "phone":
            RyzeField(label: T("Phone number", "Numri i telefonit"), text: bind("phone"), placeholder: "69 123 4567", prefix: "🇦🇱 +355", keyboard: .phonePad)
        case "otp":
            VStack(alignment: .leading, spacing: 16) {
                OtpField(code: $model.otp)
                Text(T("Didn't get it? Resend in 30s · demo: any 6 digits", "Nuk e more? Ridërgo për 30s · demo: çdo 6 shifra")).font(.system(size: 13)).foregroundColor(Brand.faint)
            }
        case "identity":
            VStack(spacing: 18) {
                Image("identity").resizable().scaledToFit().frame(height: 240)
                actionRow(done: model.idScanned, icon: "camera.viewfinder", label: T("Scan ID card", "Skano letërnjoftimin"), doneLabel: T("ID scanned", "U skanua")) { showScan = true }
                actionRow(done: model.faceChecked, icon: "faceid", label: T("Face check", "Verifikim fytyre"), doneLabel: T("Verified", "U verifikua")) { showFace = true }
                Text(T("Capture is simulated in this prototype. No human reviews your video.", "Kapja është e simuluar në këtë prototip. Asnjë person nuk e shqyrton videon.")).font(.system(size: 12)).foregroundColor(Brand.faint).multilineTextAlignment(.center)
            }
            .sheet(isPresented: $showScan) { IDScanSheet { model.simulateScan() } }
            .sheet(isPresented: $showFace) { FaceCheckSheet { model.simulateFace() } }
        case "details":
            VStack(alignment: .leading, spacing: 14) {
                RyzeField(label: T("First name", "Emri"), text: bind("firstName"), placeholder: T("First name", "Emri"))
                RyzeField(label: T("Last name", "Mbiemri"), text: bind("lastName"), placeholder: T("Last name", "Mbiemri"))
                RyzeField(label: T("Date of birth", "Data e lindjes"), text: bind("dob"), placeholder: "DD/MM/YYYY", keyboard: .numbersAndPunctuation)
                RyzeField(label: "Email", text: bind("email"), placeholder: "you@email.com", keyboard: .emailAddress)
                if let e = model.ageError {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill").foregroundColor(Brand.yellow)
                        Text(e).font(.system(size: 13)).foregroundColor(Brand.mute)
                    }
                    .padding(12).liquidSurface(12)
                }
            }
        case "consents":
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Legal.consents) { c in
                    ConsentRowView(consent: c, checked: model.consents.contains(c.id)) { model.toggleConsent(c.id) }
                    if c.id != Legal.consents.last?.id { Divider().background(Brand.hairline) }
                }
                Text(Legal.disclaimer).font(.system(size: 12)).foregroundColor(Brand.faint).padding(.top, 12)
            }
        case "notifications":
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(Brand.yellow.opacity(0.12)).frame(width: 120, height: 120)
                    Image(systemName: "bell.badge.fill").font(.system(size: 52)).foregroundColor(Brand.yellow)
                }.padding(.vertical, 24)
            }.frame(maxWidth: .infinity)
        default: EmptyView()
        }
    }
    private func actionRow(done: Bool, icon: String, label: String, doneLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: done ? "checkmark.circle.fill" : icon).foregroundColor(done ? Brand.good : Brand.text)
                Text(done ? doneLabel : label).font(.system(size: 16, weight: .semibold)).foregroundColor(done ? Brand.mute : Brand.text)
                Spacer()
                if !done { Image(systemName: "chevron.right").foregroundColor(Brand.faint) }
            }
            .padding(.horizontal, 16).frame(height: 56)
            .liquidSurface(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Success + stub home
struct SuccessView: View {
    let onStart: () -> Void
    @State private var burst = 0
    var body: some View {
        ZStack {
            LoopingVideo(name: "onboard_success").ignoresSafeArea()
            // Same top+bottom scrim as the carousel so the title, body and button stay legible.
            LinearGradient(stops: [
                .init(color: .black.opacity(0.55), location: 0.0),
                .init(color: .clear, location: 0.30),
                .init(color: .clear, location: 0.48),
                .init(color: .black.opacity(0.9), location: 0.8),
                .init(color: .black, location: 1.0),
            ], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            CelebrationOverlay(trigger: burst).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 12) {
                Spacer()
                Text(T("Welcome to Ryze", "Mirë se erdhe te Ryze")).display(36).foregroundColor(.white).fixedSize(horizontal: false, vertical: true)
                Text(T("Your Raiffeisen account is open and ready. Your card is on its way, and your first quests are waiting.", "Llogaria jote Raiffeisen është e hapur dhe gati. Karta po vjen dhe sfidat e para të presin."))
                    .font(.system(size: 17)).foregroundColor(.white.opacity(0.8)).lineSpacing(3)
                PrimaryButton(title: T("Start playing", "Fillo të luash"), action: onStart).padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24).padding(.bottom, 24)
        }
        .onAppear { burst += 1 }
        .sensoryFeedback(.success, trigger: burst)
    }
}


struct RizSheet: View {
    let stepWhy: String?
    let seed: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [RizMessage] = []
    @State private var input = ""
    private let greeting = T("Hey, I'm Riz. I'll walk you through opening your account, nothing's submitted until you say so. Ask me to explain any step.", "Përshëndetje, unë jam Riz. Do të të shoqëroj në hapjen e llogarisë, asgjë nuk dërgohet derisa ta lejosh ti. Më kërko të të shpjegoj çdo hap.")

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                LogoTile(size: 34)
                Text("Riz").font(.system(size: 18, weight: .semibold)).foregroundColor(Brand.text)
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(Brand.mute) }
            }
            .padding(20)
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(messages) { m in
                        HStack {
                            if m.fromUser { Spacer(minLength: 40) }
                            Text(m.text).font(.system(size: 16))
                                .foregroundColor(m.fromUser ? Brand.onText : Brand.text)
                                .padding(.vertical, 10).padding(.horizontal, 14)
                                .background(m.fromUser ? Brand.text : Brand.bg)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(m.fromUser ? .clear : Brand.hairline, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            if !m.fromUser { Spacer(minLength: 40) }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            HStack(spacing: 8) {
                TextField("", text: $input, prompt: Text(T("Ask Riz...", "Pyet Riz...")).foregroundColor(Brand.faint))
                    .foregroundColor(Brand.text).padding(.horizontal, 16).frame(height: 48)
                    .background(Brand.bg).overlay(RoundedRectangle(cornerRadius: 12).stroke(Brand.hairline, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Button(action: send) {
                    Image(systemName: "arrow.up").font(.system(size: 18, weight: .bold)).foregroundColor(.black)
                        .frame(width: 48, height: 48).background(Brand.yellow).clipShape(Circle())
                }
            }
            .padding(20)
        }
        .background(Brand.surface)
        .onAppear { if messages.isEmpty { messages = [RizMessage(fromUser: false, text: seed ? (stepWhy ?? greeting) : greeting)] } }
    }

    private func send() {
        let q = input.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        input = ""
        messages.append(RizMessage(fromUser: true, text: q))
        messages.append(RizMessage(fromUser: false, text: Riz.reply(stepWhy: stepWhy, text: q)))
    }
}

struct LogoHero: View {
    @State private var glow = false
    private let dots: [(CGFloat, CGFloat, CGFloat)] = [(-128, -104, 6), (126, -70, 4), (-104, 96, 5), (112, 84, 3), (10, -140, 5), (140, 20, 3)]
    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [Brand.yellow.opacity(0.34), .clear], center: .center, startRadius: 6, endRadius: 185)).frame(width: 360, height: 360).scaleEffect(glow ? 1.06 : 0.94)
            Circle().stroke(Brand.yellow.opacity(0.25), lineWidth: 1).frame(width: 240, height: 240)
            ForEach(0..<dots.count, id: \.self) { i in Circle().fill(Brand.yellow).frame(width: dots[i].2, height: dots[i].2).offset(x: dots[i].0, y: dots[i].1).opacity(0.85) }
            LogoTile(size: 156).shadow(color: Brand.yellow.opacity(0.45), radius: 24, y: 8)
        }
        .frame(height: UIScreen.main.bounds.height * 0.42)
        .onAppear { withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { glow = true } }
    }
}

// Final-card branded seal: real Raiffeisen logo + circular signature ring + celebration burst.
struct SuccessSeal: View {
    @State private var pop = false
    @State private var burst = 0
    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [Brand.yellow.opacity(0.28), .clear], center: .center, startRadius: 6, endRadius: 165)).frame(width: 300, height: 300)
            CelebrationOverlay(trigger: burst).frame(width: 300, height: 300)
            Circle().stroke(Brand.yellow.opacity(0.35), lineWidth: 2).frame(width: 188, height: 188).rotationEffect(.degrees(pop ? 0 : 40))
            Circle().stroke(Brand.gold, lineWidth: 4).frame(width: 150, height: 150).opacity(0.55)
            ZStack(alignment: .bottomTrailing) {
                LogoTile(size: 110).shadow(color: Brand.yellow.opacity(0.4), radius: 22, y: 8)
                Image(systemName: "checkmark.circle.fill").font(.system(size: 34)).foregroundStyle(.white, Brand.good).background(Circle().fill(Brand.void).padding(3)).offset(x: 8, y: 8)
            }
        }
        .frame(height: 300)
        .scaleEffect(pop ? 1 : 0.72).opacity(pop ? 1 : 0)
        .onAppear { withAnimation(.spring(response: 0.55, dampingFraction: 0.6)) { pop = true }; burst += 1 }
    }
}


// MARK: - Simulated KYC capture (camera-style scan experiences)
struct IDScanSheet: View {
    let onDone: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var scanning = false
    @State private var done = false
    @State private var line = false
    var body: some View {
        ZStack { Color.black.ignoresSafeArea()
            VStack(spacing: 22) {
                HStack { Button { dismiss() } label: { Image(systemName: "xmark").font(.system(size: 17, weight: .semibold)).foregroundColor(.white) }; Spacer(); Text(T("Scan your ID", "Skano letërnjoftimin")).font(.system(size: 17, weight: .semibold)).foregroundColor(.white); Spacer(); Color.clear.frame(width: 20) }.padding(.top, 8)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)).frame(width: 300, height: 190)
                    RoundedRectangle(cornerRadius: 16).stroke(done ? Brand.good : Brand.yellow, style: StrokeStyle(lineWidth: 3, dash: (scanning || done) ? [] : [9, 7])).frame(width: 300, height: 190)
                    if done { Image(systemName: "checkmark.circle.fill").font(.system(size: 64)).foregroundStyle(.white, Brand.good) }
                    else { VStack(spacing: 10) { Image(systemName: "person.text.rectangle").font(.system(size: 44)).foregroundColor(.white.opacity(0.5)); if !scanning { Text(T("Front of your ID card", "Pjesa e përparme e letërnjoftimit")).font(.system(size: 13)).foregroundColor(.white.opacity(0.6)) } } }
                    if scanning && !done { Rectangle().fill(LinearGradient(colors: [.clear, Brand.yellow, .clear], startPoint: .leading, endPoint: .trailing)).frame(width: 292, height: 3).offset(y: line ? 88 : -88) }
                }
                Spacer()
                Text(done ? T("ID captured", "Letërnjoftimi u kap") : (scanning ? T("Hold steady, scanning...", "Qëndro i palëvizur, po skanohet...") : T("Align the front of your ID inside the frame", "Vendos pjesën e përparme brenda kornizës"))).font(.system(size: 14)).foregroundColor(.white.opacity(0.75)).multilineTextAlignment(.center).frame(height: 40)
                if !done { Button { startScan() } label: { Text(scanning ? T("Scanning...", "Po skanohet...") : T("Capture", "Kap")).font(.system(size: 17, weight: .semibold)).foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 54).background(Brand.yellow).clipShape(Capsule()) }.buttonStyle(PressStyle()).opacity(scanning ? 0.5 : 1).disabled(scanning).padding(.horizontal, 24) }
            }.padding(20)
        }
    }
    func startScan() {
        scanning = true
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { line = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) { withAnimation(.spring) { done = true }; DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { onDone(); dismiss() } }
    }
}

struct FaceCheckSheet: View {
    let onDone: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var scanning = false
    @State private var done = false
    @State private var progress: CGFloat = 0
    var body: some View {
        ZStack { Color.black.ignoresSafeArea()
            VStack(spacing: 22) {
                HStack { Button { dismiss() } label: { Image(systemName: "xmark").font(.system(size: 17, weight: .semibold)).foregroundColor(.white) }; Spacer(); Text(T("Face check", "Verifikim fytyre")).font(.system(size: 17, weight: .semibold)).foregroundColor(.white); Spacer(); Color.clear.frame(width: 20) }.padding(.top, 8)
                Spacer()
                ZStack {
                    Circle().stroke(Color.white.opacity(0.12), lineWidth: 5).frame(width: 230, height: 230)
                    Circle().trim(from: 0, to: done ? 1 : progress).stroke(done ? Brand.good : Brand.yellow, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90)).frame(width: 230, height: 230)
                    if done { Image(systemName: "checkmark.circle.fill").font(.system(size: 64)).foregroundStyle(.white, Brand.good) }
                    else { Image(systemName: "face.smiling").font(.system(size: 76)).foregroundColor(.white.opacity(0.4)) }
                }
                Spacer()
                Text(done ? T("Verified", "U verifikua") : (scanning ? T("Hold still, looking...", "Rri i qetë, po shikohet...") : T("Center your face in the circle", "Vendos fytyrën në rreth"))).font(.system(size: 14)).foregroundColor(.white.opacity(0.75)).frame(height: 40)
                if !done { Button { startFace() } label: { Text(scanning ? T("Checking...", "Po kontrollohet...") : T("Start face check", "Fillo verifikimin")).font(.system(size: 17, weight: .semibold)).foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 54).background(Brand.yellow).clipShape(Capsule()) }.buttonStyle(PressStyle()).opacity(scanning ? 0.5 : 1).disabled(scanning).padding(.horizontal, 24) }
            }.padding(20)
        }
    }
    func startFace() {
        scanning = true
        withAnimation(.easeInOut(duration: 1.6)) { progress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) { withAnimation(.spring) { done = true }; DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { onDone(); dismiss() } }
    }
}
