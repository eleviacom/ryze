import SwiftUI
import LocalAuthentication
import Combine
import UIKit

// MARK: - Capture awareness (screenshots + screen recording / AirPlay mirroring)
final class CaptureGuard: ObservableObject {
    @Published var isCaptured = UIScreen.main.isCaptured
    @Published var screenshotTick = 0
    private var bag: Set<AnyCancellable> = []
    init() {
        NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
            .sink { [weak self] _ in self?.screenshotTick += 1 }.store(in: &bag)
        NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.isCaptured = UIScreen.main.isCaptured }.store(in: &bag)
    }
}

// MARK: - App-switcher privacy cover (hides content in the multitasking snapshot)
struct PrivacyCover: View {
    var body: some View {
        ZStack {
            Brand.bg.ignoresSafeArea()
            VStack(spacing: 14) {
                Image("RaiffeisenLogo").resizable().scaledToFit().frame(width: 60, height: 60).clipShape(RoundedRectangle(cornerRadius: 17))
                Text("Ryze").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(Brand.text)
            }
        }
    }
}

// MARK: - Biometric app lock (Face ID / passcode), opt-in, launch + inactivity relock
@MainActor
final class AppLockModel: ObservableObject {
    @Published var locked = false
    private var lastActive = Date()
    private let grace: TimeInterval = 60
    private var enabled: Bool { UserDefaults.standard.bool(forKey: "ryze_app_lock") }

    func armOnLaunch() { if enabled { locked = true } }
    func willResign() { lastActive = Date() }
    func didActivate() { if enabled && Date().timeIntervalSince(lastActive) > grace { locked = true } }

    func unlock() async {
        if await Self.evaluate(T("Unlock Ryze", "Shkyç Ryze")) { withAnimation(.easeOut(duration: 0.25)) { locked = false } }
    }
    // Step-up auth for a single action. Fails OPEN when no biometry/passcode is enrolled
    // (e.g. a bare simulator) so a demo is never bricked; on real hardware it prompts.
    static func confirm(_ reason: String) async -> Bool { await evaluate(reason) }

    private static func evaluate(_ reason: String) async -> Bool {
        let ctx = LAContext()
        ctx.localizedFallbackTitle = T("Use passcode", "Përdor kodin")
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &err) else { return true }
        return (try? await ctx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)) ?? false
    }
}

struct LockScreen: View {
    @ObservedObject var lock: AppLockModel
    var body: some View {
        ZStack {
            Brand.void.ignoresSafeArea()
            VStack(spacing: 20) {
                Image("RaiffeisenLogo").resizable().scaledToFit().frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 20))
                Text(T("Ryze is locked", "Ryze është kyçur")).font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                Button { Task { await lock.unlock() } } label: {
                    HStack(spacing: 8) { Image(systemName: "faceid"); Text(T("Unlock", "Shkyç")) }
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.black)
                        .padding(.horizontal, 26).frame(height: 50).background(Brand.yellow).clipShape(Capsule())
                }
            }
        }
        .environment(\.colorScheme, .dark)
        .task { await lock.unlock() }
    }
}

// MARK: - Redact sensitive surfaces live while a recording / mirror is active
private struct RedactWhileCapturing: ViewModifier {
    @EnvironmentObject var capture: CaptureGuard
    func body(content: Content) -> some View {
        content.overlay {
            if capture.isCaptured {
                ZStack {
                    RoundedRectangle(cornerRadius: 20).fill(Brand.elev3)
                    Label(T("Hidden while recording", "Fshehur gjatë regjistrimit"), systemImage: "eye.slash.fill")
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(Brand.mute)
                }
            }
        }
    }
}

extension View {
    func redactWhileCapturing() -> some View { modifier(RedactWhileCapturing()) }
}
