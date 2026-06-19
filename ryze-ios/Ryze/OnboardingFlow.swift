import SwiftUI

struct WhyInfo: Identifiable { let id = UUID(); let title: String; let body: String }

struct OnboardingFlow: View {
    @StateObject private var model = OnboardingModel()
    @EnvironmentObject var game: GameModel
    @State private var why: WhyInfo? = nil

    var body: some View {
        ZStack {
            Brand.bg.ignoresSafeArea()

            switch model.phase {
            case .value: WelcomeCarousel(model: model)
            case .kyc: KycContainer(model: model, onWhyTap: { step in why = WhyInfo(title: step.title, body: step.why ?? step.body) })
            case .success: SuccessView { game.completeAccount(name: model.draft["firstName"]) }
            }

            if model.phase == .value {
                Button { game.completeAccount(name: model.draft["firstName"] ?? "Klevi") } label: {
                    Text("Skip \u{203A}").font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.mute)
                        .padding(.horizontal, 14).frame(height: 32).background(Brand.surface).clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 16).padding(.top, 4)
            }
        }
        .sheet(item: $why) { w in
            VStack(alignment: .leading, spacing: 16) {
                Text(w.title).font(.system(size: 24, weight: .bold)).foregroundColor(Brand.text)
                Text(w.body).font(.system(size: 16)).foregroundColor(Brand.mute).lineSpacing(3)
                Spacer()
                PrimaryButton(title: "Got it") { why = nil }
            }
            .padding(24).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Brand.bg).presentationDetents([.medium])
        }
    }
}

// MARK: - Value carousel
struct WelcomeCarousel: View {
    @ObservedObject var model: OnboardingModel
    struct Slide { let image, title, body, cta: String }
    let slides = [
        Slide(image: "welcomelogo", title: "Money that finally gets you",
              body: "Ryze is the Raiffeisen account built for your twenties. Spend, save, and level up — in one place that feels like yours.", cta: "Continue"),
        Slide(image: "openacct", title: "Open it in minutes, 100% online",
              body: "No branch, no paperwork, no fees to open. Just your ID and a quick video check — from your couch.", cta: "Continue"),
        Slide(image: "domore", title: "Do more, together",
              body: "Instant payments, real-time exchange, save while you spend, and rewards for inviting your crew.", cta: "Get started"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                LogoTile(size: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Eyebrow(text: "Raiffeisen")
                    Text("Ryze").font(.system(size: 18, weight: .semibold)).foregroundColor(Brand.text)
                }
                Spacer()
            }
            .padding(.horizontal, 24).padding(.top, 8)

            HStack(spacing: 6) {
                ForEach(0..<slides.count, id: \.self) { i in
                    Capsule().fill(i <= model.slideIndex ? Brand.yellow : Brand.hairline).frame(height: 3)
                }
            }
            .padding(.horizontal, 24).padding(.top, 14)

            TabView(selection: $model.slideIndex) {
                ForEach(0..<slides.count, id: \.self) { i in
                    SlideView(slide: slides[i]).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: model.slideIndex)

            PrimaryButton(title: slides[model.slideIndex].cta) {
                if model.slideIndex < slides.count - 1 { withAnimation { model.slideIndex += 1 } }
                else { model.startKyc() }
            }
            .padding(.horizontal, 24).padding(.bottom, 8)
        }
    }
}

struct SlideView: View {
    let slide: WelcomeCarousel.Slide
    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)
            if slide.image == "welcomelogo" {
                LogoHero()
            } else {
                Image(slide.image).resizable().scaledToFit().frame(height: UIScreen.main.bounds.height * 0.40)
            }
            VStack(alignment: .leading, spacing: 12) {
                Text(slide.title).display(33).foregroundColor(Brand.text).fixedSize(horizontal: false, vertical: true)
                Text(slide.body).font(.system(size: 17)).foregroundColor(Brand.mute).lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 24)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - KYC container
struct KycContainer: View {
    @ObservedObject var model: OnboardingModel
    let onWhyTap: (KycStepDef) -> Void

    func cta(_ id: String) -> String {
        switch id {
        case "phone": return "Send code"
        case "otp": return "Verify"
        case "identity": return "Continue"
        case "details": return "Confirm"
        case "consents": return "Agree & open my account"
        default: return "Continue"
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
                        Text("Why do we need it?").font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.yellow)
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
                    PrimaryButton(title: "I want to be notified") { model.next() }
                    GhostButton(title: "Maybe later") { model.next() }
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
    func bind(_ key: String) -> Binding<String> {
        Binding(get: { model.draft[key] ?? "" }, set: { model.draft[key] = $0 })
    }
    var body: some View {
        switch model.current.id {
        case "phone":
            RyzeField(label: "Phone number", text: bind("phone"), placeholder: "69 123 4567", prefix: "🇦🇱 +355", keyboard: .phonePad)
        case "otp":
            VStack(alignment: .leading, spacing: 16) {
                OtpField(code: $model.otp)
                Text("Didn’t get it? Resend in 30s · demo: any 6 digits").font(.system(size: 13)).foregroundColor(Brand.faint)
            }
        case "identity":
            VStack(spacing: 18) {
                Image("identity").resizable().scaledToFit().frame(height: 240)
                actionRow(done: model.idScanned, icon: "camera.viewfinder", label: "Scan ID card", doneLabel: "ID scanned") { model.simulateScan() }
                actionRow(done: model.faceChecked, icon: "faceid", label: "Face check", doneLabel: "Verified") { model.simulateFace() }
                Text("Capture is simulated in this prototype. No human reviews your video.").font(.system(size: 12)).foregroundColor(Brand.faint).multilineTextAlignment(.center)
            }
        case "details":
            VStack(alignment: .leading, spacing: 14) {
                RyzeField(label: "First name", text: bind("firstName"), placeholder: "First name")
                RyzeField(label: "Last name", text: bind("lastName"), placeholder: "Last name")
                RyzeField(label: "Date of birth", text: bind("dob"), placeholder: "DD/MM/YYYY", keyboard: .numbersAndPunctuation)
                RyzeField(label: "Email", text: bind("email"), placeholder: "you@email.com", keyboard: .emailAddress)
                if let e = model.ageError {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill").foregroundColor(Brand.yellow)
                        Text(e).font(.system(size: 13)).foregroundColor(Brand.mute)
                    }
                    .padding(12).background(Brand.surface).clipShape(RoundedRectangle(cornerRadius: 12))
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
            .background(Brand.surface)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Brand.hairline, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Success + stub home
struct SuccessView: View {
    let onStart: () -> Void
    @State private var pop = false
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image("success").resizable().scaledToFit().frame(height: 280)
                .scaleEffect(pop ? 1 : 0.7).opacity(pop ? 1 : 0)
                .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { pop = true } }
            VStack(spacing: 12) {
                Text("Welcome to Ryze").display(38).foregroundColor(Brand.text).fixedSize(horizontal: false, vertical: true).multilineTextAlignment(.center)
                Text("Your Raiffeisen account is open and ready. Your card is on its way, and your first quests are waiting.")
                    .font(.system(size: 17)).foregroundColor(Brand.mute).multilineTextAlignment(.center).lineSpacing(3)
            }
            .padding(.horizontal, 24).padding(.top, 8)
            Spacer()
            PrimaryButton(title: "Start playing", action: onStart).padding(.horizontal, 24).padding(.bottom, 12)
        }
    }
}


// MARK: - Riz buddy
struct RizFab: View {
    let action: () -> Void
    @State private var pulse = false
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: action) {
                    ZStack(alignment: .topTrailing) {
                        LogoTile(size: 52)
                        Circle().fill(Brand.yellow).frame(width: 20, height: 20)
                            .overlay(Text("?").font(.system(size: 12, weight: .bold)).foregroundColor(.black))
                            .overlay(Circle().stroke(Brand.bg, lineWidth: 2))
                            .offset(x: 5, y: -5)
                    }
                    .scaleEffect(pulse ? 1.06 : 1)
                }
                .padding(.trailing, 18).padding(.bottom, 90)
            }
        }
        .onAppear { withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) { pulse = true } }
    }
}

struct RizSheet: View {
    let stepWhy: String?
    let seed: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [RizMessage] = []
    @State private var input = ""
    private let greeting = "Hey, I’m Riz. I’ll walk you through opening your account — nothing’s submitted until you say so. Ask me to explain any step."

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
                                .foregroundColor(m.fromUser ? .black : Brand.text)
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
                TextField("", text: $input, prompt: Text("Ask Riz…").foregroundColor(Brand.faint))
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
