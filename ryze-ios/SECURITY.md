# Ryze — Security posture

Ryze is a **hackathon prototype** of a youth banking app. This document is an honest
account of what is hardened, what is deliberately out of scope, and the production path —
because for a banking product, overclaiming is itself a failure.

## What is implemented (this build)

**Screen-capture protection** (`AppSecurity.swift`)
- **App-switcher privacy cover** — when the app leaves `.active`, a branded cover replaces the
  UI so balances, cards and KYC do **not** appear in the iOS multitasking snapshot.
- **Screenshot detection** — `UIApplication.userDidTakeScreenshotNotification` re-masks the
  card/balance instantly and shows the user a warning toast.
- **Screen-recording / mirroring redaction** — `UIScreen.isCaptured` live-redacts the balance
  tile and card faces while a recording or AirPlay mirror is active.

**Authentication** (`AppSecurity.swift`, `AppViews.swift`)
- **Biometric reveal gate** — showing the full PAN / expiry / CVV requires Face ID / passcode
  (`LAContext`, `.deviceOwnerAuthentication`). Hiding never requires auth.
- **Opt-in app lock** — Settings ▸ Security enables a Face ID / passcode gate on cold launch
  and on resume after 60 s of inactivity (`NSFaceIDUsageDescription` is set in `project.yml`).

**Data at rest** (`Hardening.swift`)
- Bank and game snapshots are stored **AES-GCM encrypted** (`SecureStore`), with the 256-bit key
  held in the **Keychain** (`AfterFirstUnlockThisDeviceOnly`) and the file written with
  `completeFileProtectionUntilFirstUserAuthentication`. Legacy cleartext `UserDefaults` blobs are
  migrated once and deleted. (Previously the snapshots were plaintext `UserDefaults`.)

**PII hygiene**
- IBAN is **masked** by default with reveal-on-tap (`Sections.swift`).
- Copied reward codes use an **auto-expiring, local-only** pasteboard (`Clip.copySensitive`, 60 s).
- Network is **HTTPS-only** under Apple's default ATS; no sensitive values are logged.

## Known limitations (deliberate, hackathon scope)

- **iOS cannot block screenshots app-wide.** There is no public equivalent of Android's
  `FLAG_SECURE`. We evaluated the private `UITextField` secure-canvas trick to blank specific
  views in screenshots; it proved **inconsistent across the view hierarchy** (it blanked one card
  but not another), so it was removed in favour of the reliable detect-+-redact-+-privacy-cover
  approach above. Screenshot **detection fires after** the image is saved, so it is a nudge +
  auto-re-mask, not prevention.
- **The Riz LLM API key is bundled in the app** (`RizSecret.swift`, gitignored, never committed).
  A key shipped in any binary is extractable (`strings` on the `.ipa`); treat it as compromised
  and rotate it. The repo already contains the real fix — `riz-proxy/` (a Cloudflare Worker that
  holds the key server-side). Production: ship **no** on-device key and call the proxy, gated by
  **App Attest / DeviceCheck**.
- **Biometrics are intent confirmation, not a security boundary.** They stop shoulder-surfing and
  casual access; real auth requires the backend to enforce SCA / 3-D Secure. On a device with no
  passcode/biometry the gates fail **open** by design so a demo is never bricked.
- **No jailbreak / anti-debug checks.** They are all defeatable (advisory only) and risk bricking
  the demo; out of scope for the prototype.
- Encrypted storage only protects at rest if the device has a passcode; the app-level AES-GCM layer
  is what makes it robust regardless.

## Production roadmap

Server-held secrets + App Attest · backend-enforced SCA on payments · device-bound session tokens
in Keychain · certificate pinning at a stable gateway · de-identified/minimised LLM context ·
scoped CORS + auth + rate-limit on the proxy.
