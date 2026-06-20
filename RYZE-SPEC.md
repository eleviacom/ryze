# Executive Summary

**Ryze** is a gamified mobile bank for young Albanians (ages 14–25), built on real Raiffeisen banking rails and delivered as a native SwiftUI app for iOS 17+. It takes the intimidating "first bank account" and turns it into a product Gen-Z actually wants to open, use, and stay with — by wrapping everyday banking (accounts, cards, payments, KYC) in an AI money coach, social payments, savings goals, and a rewards game.

Ryze was built by team **PentaByte** for **JunctionX Tirana 2026**, on the Raiffeisen challenge track **"Play · Invite · Belong."**

### The problem
For most young people a first bank account is paperwork, not empowerment. Traditional banking apps are built for adults, in adult language, with zero guidance and no reason to build good habits early. The result is low financial literacy, low engagement, and a generation that learns money the hard way.

### The solution
Ryze keeps **real banking** but makes it feel like the apps young people already love. Six pillars:

| Pillar | What it delivers |
|---|---|
| **2-minute onboarding** | Fully online KYC (phone, OTP, ID scan, face check), Albania-correct legal disclosures, 18+ age handling, EN + Albanian. |
| **Riz, the AI money coach** | Ask *"How am I spending this month?"* and get a real answer from your actual data — with input-safety guardrails and an offline fallback that works even without an API key. |
| **Social money** | Send and request like texting (chat threads with money bubbles); split bills with your crew in seconds. |
| **Cards** | Virtual + physical, freeze & limits, biometric reveal of card details, and a Card Studio to personalise. |
| **Grow** | Savings goals with round-ups, plus spending analytics. |
| **Rewards game** | Daily streaks, levels/tiers, AI-generated missions tied to *real money actions*, a squad goal, invite-to-earn, and a points store with real-brand coupons redeemed by QR. |

### Why it fits "Play · Invite · Belong"
Every mechanic maps directly to the track: **Play** (streaks, levels, missions), **Invite** (referrals, squad goal), **Belong** (identity, rewards, community). Crucially, points are earned through *good financial behaviour*, so engagement and financial literacy rise together.

### Status
This specification describes a **hackathon prototype**. Banking rails, the Riz backend, and several flows are functional; persistence, security hardening, and the design system are production-grade in spirit, but real Raiffeisen API integration and regulated controls (SCA/3-D Secure, server-held secrets, legal sign-off) are explicitly future work. Where something is a stub or mock, this document says so.

---

# Product Overview

### Target users
Albanian youth, 14–25. Primary persona: a Gen-Z first-time account holder who lives in chat apps, expects instant and social interactions, and has never been taught to manage money. Under-18 handling is part of onboarding (a parent/guardian view is roadmap, not built).

### Platform & stack at a glance
| Aspect | Detail |
|---|---|
| Platform | Native **SwiftUI**, iOS 17+ |
| Bundle id | `al.raiffeisen.ryze` |
| Architecture | Modular models — `BankModel`, `GameModel`, `OnboardingModel`, Riz service — mapping 1:1 to the challenge's logical services |
| Localisation | English + Albanian (EN/SQ), switchable |
| Currency | Albanian Lek (ALL) with ALL↔EUR exchange |
| Appearance | Adaptive light/dark |
| AI | Riz runs on a live backend (Cloudflare Worker proxy) with a safe on-device offline fallback |
| Design | Revolut-grade system around a single scarce Raiffeisen "Banana Yellow" stamp on a warm-dark canvas |

### Information architecture
The app is a five-tab experience with Profile reachable from the top-bar avatar:

| Tab | Icon | Purpose |
|---|---|---|
| **Home** | `house.fill` | Bento dashboard: balance, level/points, move-money console, goal & spend, recent activity |
| **Cards** | `creditcard.fill` | Virtual + physical cards, freeze/limits, Card Studio |
| **Pay** | `paperplane.fill` | Send / request / split, social chat threads with money bubbles |
| **Assistant (Riz)** | `sparkles` | AI money coach |
| **Rewards** | `gift.fill` | Streaks, missions, squad goal, points store |

The chapters that follow specify each of these areas in depth, followed by the design system, security & architecture, the roadmap, and reference appendices.

# Onboarding & KYC

### 1. Purpose & Scope

The onboarding domain covers the full account-opening journey from first launch to a funded-and-ready home screen: a three-slide value carousel, a six-step KYC (Know Your Customer) flow, and a celebratory success screen. It is implemented natively in SwiftUI, runs in a forced dark color scheme (`.environment(\.colorScheme, .dark)`), and is fully bilingual (English / Albanian) via the `T(en, sq)` helper.

**Prototype disclosure (load-bearing):** The entire KYC capture pipeline is simulated. ID scanning and face/liveness checks animate but capture nothing. `Legal.disclaimer` states verbatim: *"Ryze is a hackathon prototype for Raiffeisen Bank Albania. It is not a live banking service. All legal texts, consents and figures are drafts requiring final legal and compliance review."* The OTP step accepts any 6 digits. No data is transmitted to any backend; everything lives in the in-memory `draft` dictionary.

The flow is driven by two files plus legal copy:
- `OnboardingFlow.swift` — all views (carousel, KYC container, step bodies, simulated capture sheets, success seal, Riz assistant sheet).
- `OnboardingModel.swift` — the `OnboardingModel` state machine, step definitions, validation, navigation.
- `Legal.swift` — the `Legal` enum (consents, disclaimers, deposit-insurance and info-notice copy).

### 2. State Model (`OnboardingModel`)

`OnboardingModel` is a `final class` conforming to `ObservableObject`. It owns the entire onboarding state.

#### 2.1 Top-level phase

| Type | Definition |
|---|---|
| `enum Phase` | `case value`, `case kyc`, `case success` |

`OnboardingFlow.body` switches on `model.phase`:

| Phase | View rendered |
|---|---|
| `.value` | `WelcomeCarousel(model:)` |
| `.kyc` | `KycContainer(model:onWhyTap:)` |
| `.success` | `SuccessView { game.completeAccount(name:) }` |

#### 2.2 Published properties

| Property | Type | Initial | Role |
|---|---|---|---|
| `phase` | `Phase` | `.value` | Current macro-stage |
| `slideIndex` | `Int` | `0` | Active carousel slide (0–2) |
| `stepIndex` | `Int` | `0` | Active KYC step index (0–5) |
| `draft` | `[String: String]` | `[:]` | Free-form field store keyed by field name |
| `consents` | `Set<String>` | `[]` | IDs of accepted consents |
| `otp` | `String` | `""` | OTP digits entered |
| `idScanned` | `Bool` | `false` | ID-scan simulation completed |
| `faceChecked` | `Bool` | `false` | Face-check simulation completed |
| `ageError` | `String?` | `nil` | DOB/age validation message for the details step |

`draft` keys used across the flow: `phone`, `firstName`, `lastName`, `dob`, `email`.

#### 2.3 Derived properties

| Property | Type | Definition |
|---|---|---|
| `current` | `KycStepDef` | `steps[min(stepIndex, steps.count - 1)]` (index-clamped) |
| `progress` | `Double` | `Double(stepIndex + 1) / Double(steps.count)` — so step 1 of 6 reads `0.166…`, step 6 reads `1.0` |
| `canContinue` | `Bool` | Per-step validation gate (see §6) |

### 3. KYC Step Definition (`KycStepDef`)

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | Stable identifier used for switching (`phone`, `otp`, `identity`, `details`, `consents`, `notifications`) |
| `title` | `String` | Localized screen title |
| `body` | `String` | Localized explanatory paragraph |
| `why` | `String` | Localized "Why do we need it?" expansion |
| `image` | `String?` | Optional asset name; only `identity` sets one (`"identity"`) |

### 4. Value Carousel (`.value` phase)

#### 4.1 Layout (`WelcomeCarousel`)

- Header: `LogoTile(size: 30)` + an `Eyebrow(text: "Raiffeisen")` over a "Ryze" title.
- Progress: three `Capsule`s, filled `Brand.yellow` when `i <= model.slideIndex`, else `Brand.hairline`, height `3`.
- A `TabView` bound to `$model.slideIndex`, paged with `indexDisplayMode: .never`, animated with `.easeInOut`.
- A `PrimaryButton` whose title is the active slide's `cta`.

Slides are a local `struct Slide { let image, title, body, cta: String }`. Three slides:

| # | image asset | Title (EN / SQ) | CTA (EN / SQ) |
|---|---|---|---|
| 0 | `welcomelogo` (renders `LogoHero` instead of the image) | "Money that finally gets you" / "Paratë që më në fund të kuptojnë" | "Continue" / "Vazhdo" |
| 1 | `openacct` | "Open it in minutes, 100% online" / "Hape në pak minuta, 100% online" | "Continue" / "Vazhdo" |
| 2 | `domore` | "Do more, together" / "Bëj më shumë, bashkë" | "Get started" / "Fillo" |

Slide bodies (EN):
- Slide 0: "Ryze is the Raiffeisen account built for your twenties. Spend, save, and level up, in one place that feels like yours."
- Slide 1: "No branch, no paperwork, no fees to open. Just your ID and a quick video check, from your couch."
- Slide 2: "Instant payments, real-time exchange, save while you spend, and rewards for inviting your crew."

#### 4.2 Slide rendering (`SlideView`)

If `slide.image == "welcomelogo"`, renders the animated `LogoHero` (radial glow + 6 orbiting yellow dots + `LogoTile(size: 156)`, glow loops every `1.8s`, autoreversing). Otherwise renders the named `Image` scaled to `UIScreen.main.bounds.height * 0.40`. Title uses `.display(33)`; body uses `size: 17`, `Brand.mute`.

#### 4.3 Carousel CTA behavior

```
if model.slideIndex < slides.count - 1 { withAnimation { model.slideIndex += 1 } }
else { model.startKyc() }
```

`startKyc()` animates `phase = .kyc`. Once in KYC the carousel is not re-entered except by backing out of the first KYC step (see §5.4).

### 5. KYC Flow (`.kyc` phase)

#### 5.1 Step order (exact, from `OnboardingModel.steps`)

| Index | `id` | Title (EN / SQ) | CTA (EN / SQ) |
|---|---|---|---|
| 0 | `phone` | "What's your number?" / "Sa e ke numrin?" | "Send code" / "Dërgo kodin" |
| 1 | `otp` | "Enter your code" / "Vendos kodin" | "Verify" / "Verifiko" |
| 2 | `identity` | "Verify it's you" / "Verifiko që je ti" | "Continue" / "Vazhdo" |
| 3 | `details` | "Confirm your details" / "Konfirmo të dhënat" | "Confirm" / "Konfirmo" |
| 4 | `consents` | "The agreements" / "Marrëveshjet" | "Agree & open my account" / "Prano dhe hap llogarinë" |
| 5 | `notifications` | "Stay one step ahead" / "Rri një hap përpara" | (dual button, see §5.8) |

CTA strings come from `KycContainer.cta(_:)`; default fallback is "Continue" / "Vazhdo". The `identity` step's CTA never gates progression on its own (the inline action rows do — see §5.6).

#### 5.2 Container chrome (`KycContainer`)

Top bar (left→right): an `xmark` button (`Brand.yellow`) wired to `model.back()`; a `ProgressBar(value: model.progress)`; a `LogoTile(size: 28)`. Below, a `ScrollView` containing the step title (`.display(32)`), body (`size: 17`, `Brand.mute`), a "Why do we need it?" / "Pse na duhet?" button (`Brand.yellow`), and the per-step `StepBody`. The scroll content is keyed `.id(model.stepIndex)` and uses an asymmetric slide+opacity transition (insertion from trailing, removal to leading).

The "Why do we need it?" button calls `onWhyTap(step)`, which in `OnboardingFlow` populates a `WhyInfo` and presents a `.medium`-detent sheet showing `step.why ?? step.body` with a "Got it" / "E kuptova" `PrimaryButton`.

#### 5.3 Step 0 — Phone (`phone`)

- **Body (EN):** "We'll text you a code to confirm it's you. Your phone keeps your account secure and is never used for marketing without your say-so."
- **Why (EN):** "We verify your phone so only you can reach the account. Albania's code is +355."
- **Input:** a single `RyzeField`, label "Phone number" / "Numri i telefonit", placeholder `69 123 4567`, fixed prefix `🇦🇱 +355`, keyboard `.phonePad`, bound to `draft["phone"]`.
- **Validation:** `(draft["phone"] ?? "").filter(\.isNumber).count >= 6` — at least 6 numeric digits.

#### 5.4 Step 1 — OTP (`otp`)

- **Body (EN):** "We sent a 6-digit code to your phone. Keep it private, staff will never ask for it. (Demo: any 6 digits work.)"
- **Why (EN):** "The one-time code proves the phone is yours. Never share it."
- **Input:** `OtpField(code: $model.otp)` plus a `Brand.faint` hint: "Didn't get it? Resend in 30s · demo: any 6 digits" / "Nuk e more? Ridërgo për 30s · demo: çdo 6 shifra". **Placeholder/stub:** the "Resend in 30s" text is static copy; no resend timer or resend action is implemented.
- **Validation:** `otp.count == 6`. Any 6 digits pass; there is no real code to match against.

#### 5.5 Step 2 — Identity (`identity`)

- **Body (EN):** "Two quick taps: scan your ID, then a fast face check. It's fully automatic, no human watches your video."
- **Why (EN):** "By law a bank confirms who you are (KYC, Know Your Customer). No person reviews your video live."
- **Layout:** `Image("identity")` (height 240), two `actionRow`s, and a disclaimer: "Capture is simulated in this prototype. No human reviews your video." / "Kapja është e simuluar në këtë prototip. Asnjë person nuk e shqyrton videon."
  - Row 1 — "Scan ID card" / "Skano letërnjoftimin", icon `camera.viewfinder`, done label "ID scanned" / "U skanua". Opens `IDScanSheet` (`showScan`).
  - Row 2 — "Face check" / "Verifikim fytyre", icon `faceid`, done label "Verified" / "U verifikua". Opens `FaceCheckSheet` (`showFace`).
- A completed row shows a green (`Brand.good`) `checkmark.circle.fill`, the done label, and hides the chevron.
- **Validation:** `idScanned && faceChecked` — both simulations must finish.

##### Simulated ID scan (`IDScanSheet`)

Full-screen black sheet. A 300×190 framed region with a dashed (`[9, 7]`) `Brand.yellow` border that goes solid while scanning/done. Tapping "Capture" / "Kap" calls `startScan()`: sets `scanning`, animates a yellow scan line (offset −88↔88, 0.8s autoreversing), then after **1.7s** sets `done` (green border + checkmark), and after a further **0.7s** calls `onDone()` (→ `model.simulateScan()`) and dismisses. Status text cycles: "Align the front of your ID inside the frame" → "Hold steady, scanning..." → "ID captured" (with SQ equivalents). The "Front of your ID card" hint and the explicit framing copy reference the front of the card only; no back-of-card or document-type selection exists.

`simulateScan()` sets `idScanned = true` and back-fills `draft` defaults **only if not already set**: `firstName = "Klevi"`, `lastName = "Berisha"`, `dob = "14/03/2004"`. This is the mock "OCR read" feeding the details step.

##### Simulated face/liveness (`FaceCheckSheet`)

Full-screen black sheet. A 230×230 ring whose trim animates 0→1 over **1.6s** when "Start face check" / "Fillo verifikimin" is tapped (`startFace()` sets `scanning`). After **1.7s** sets `done`; after a further **0.7s** calls `onDone()` (→ `model.simulateFace()`) and dismisses. Status text: "Center your face in the circle" → "Hold still, looking..." → "Verified". `simulateFace()` only sets `faceChecked = true`.

#### 5.6 Step 3 — Details (`details`)

- **Body (EN):** "We read these from your ID, just check they're right. You must be 18 to open this account on your own."
- **Why (EN):** "We confirm you're 18+ (full legal capacity in Albania) and that your name matches your ID."
- **Inputs (`RyzeField`s):**

| Label (EN / SQ) | `draft` key | Placeholder | Keyboard |
|---|---|---|---|
| First name / Emri | `firstName` | First name / Emri | default |
| Last name / Mbiemri | `lastName` | Last name / Mbiemri | default |
| Date of birth / Data e lindjes | `dob` | `DD/MM/YYYY` | `.numbersAndPunctuation` |
| Email | `email` | `you@email.com` | `.emailAddress` |

- When `model.ageError != nil`, an inline notice card (`info.circle.fill` in `Brand.yellow`, message in `Brand.mute`, on `Brand.surface`) renders below the fields.
- **Field-level validation (`canContinue`):** first and last name both non-empty AND `ageFromDob(dob) != nil`. Note: email is collected but **not validated** anywhere, and `idScanned`/`faceChecked` from the prior step are not re-checked here.

#### 5.7 Step 4 — Consents (`consents`)

- **Body (EN):** "Have a read and tick what applies. The first ones are required to open your account; marketing is your choice."
- **Why (EN):** "These consents record your agreement, as every regulated bank must."
- Renders `ConsentRowView` for each `Legal.consents` entry with a `Divider` between rows (except after the last), toggled via `model.toggleConsent(c.id)`; checked state is `model.consents.contains(c.id)`. Below the list, `Legal.disclaimer` renders in `Brand.faint` at size 12.
- **Validation:** all mandatory consents accepted: `Legal.consents.filter(\.mandatory).allSatisfy { consents.contains($0.id) }`.

#### 5.8 Step 5 — Notifications (`notifications`)

- **Body (EN):** "Get alerts for security codes, payments, streaks and rewards. Optional, change it anytime in Settings."
- **Why (EN):** "Alerts help you catch anything odd early. It's optional."
- Decorative only: a `bell.badge.fill` icon (52pt, `Brand.yellow`) inside a 120×120 yellow-tinted circle.
- **Special footer:** unlike every other step, this renders two buttons — `PrimaryButton` "I want to be notified" / "Dua të njoftohem" and `GhostButton` "Maybe later" / "Ndoshta më vonë". Both call `model.next()`; there is **no actual notification-permission request** wired up (placeholder/stub). `canContinue` defaults to `true` here.

#### 5.9 Forward navigation (`next()`)

```
if current.id == "details" {
  guard let age = ageFromDob(draft["dob"] ?? "") else { ageError = "...DD/MM/YYYY."; return }
  if age < 18 { ageError = "Ryze is for ages 18-25..."; return }
  ageError = nil
}
if stepIndex < steps.count - 1 { stepIndex += 1 (0.28s ease) }
else { phase = .success }
```

On the final step (`notifications`), `next()` transitions to `.success`.

#### 5.10 Backward navigation (`back()`)

The `xmark` top-bar button calls `back()`:
- If `stepIndex > 0`: decrement `stepIndex` (0.25s ease) and clear `ageError`.
- If `stepIndex == 0`: return to `phase = .value` (the carousel). There is no confirmation prompt; the carousel re-appears at its last `slideIndex`.

### 6. Validation Summary (`canContinue`)

| Step `id` | Condition for enabled CTA |
|---|---|
| `phone` | ≥ 6 numeric digits in `draft["phone"]` |
| `otp` | `otp.count == 6` |
| `identity` | `idScanned && faceChecked` |
| `details` | `firstName` and `lastName` non-empty AND `ageFromDob(dob) != nil` |
| `consents` | all `mandatory` consents present in `consents` |
| `notifications` (default) | always `true` |

The `PrimaryButton` is passed `enabled: model.canContinue`, so it is visually/functionally disabled until the gate passes (except `notifications`, which has its own dual-button footer).

### 7. Age Handling (18+ Logic)

`ageFromDob(_:)` splits the DOB string on `/`, requires exactly 3 integer components (day/month/year), builds a `DateComponents`, and returns whole years between birth and `Date()` via `Calendar.current`. Returns `nil` on any parse failure.

Two distinct gates:
1. **Field validation** (`canContinue`): only requires `ageFromDob != nil` — i.e. a *parseable* date. The age value is not checked here, so the CTA can enable for an under-18 date.
2. **Submit-time enforcement** (`next()` for `details`): on tap, if DOB is unparseable → `ageError` = "Please enter your date of birth as DD/MM/YYYY." / "Vendos datën e lindjes në formatin DD/MM/VVVV." If `age < 18` → `ageError` = "Ryze is for ages 18-25, come back when you turn 18. That's the only reason." / "Ryze është për moshat 18-25, kthehu kur të mbushësh 18. Kjo është e vetmja arsye." Both return without advancing.

The copy frames Ryze as **ages 18–25**, but the only enforced bound in code is the lower bound (`age < 18`); there is **no upper-bound (25) check**. The prefilled QA DOB `14/03/2004` yields age 22 relative to the project date (2026), passing the gate.

### 8. Consents & Legal Disclosures (`Legal`)

#### 8.1 `ConsentDef`

| Field | Type |
|---|---|
| `id` | `String` |
| `mandatory` | `Bool` |
| `label` | `String` |

`Legal.consents` (note: consent labels are **English-only**; not wrapped in `T()`):

| `id` | mandatory | Label |
|---|---|---|
| `agreements` | `true` | "I agree to the Framework Agreement, General Terms, Tariff and Privacy Policy, the Information Notice (Law 124/2024), and I confirm the KYC/AML, beneficial-owner, PEP, tax (CRS/FATCA) and deposit-insurance (ASD) declarations." |
| `biometric` | `true` | "I consent to the automated processing of my facial image (liveness check) to verify my identity." |
| `marketing` | `false` | "Send me personalised offers, news and rewards from Raiffeisen. (Optional, turn off anytime.)" |

#### 8.2 Static legal strings

| Constant | Summary of content |
|---|---|
| `disclaimer` | Hackathon-prototype notice (rendered on consents step); states it is not a live banking service and all texts/figures are drafts. |
| `depositInsurance` | ASD insurance under **Law No. 53/2014**, up to **2,500,000 ALL** (≈ €26,000, indicative) per depositor per bank; FX deposits converted at Bank of Albania rate. **Not referenced by any onboarding view in these files** — defined but unused here. |
| `infoNotice` | Controller = Raiffeisen Bank Sh.a.; processing for account operation and legal obligations (AML Law 9917/2008; CRS Law 4/2020; FATCA) and liveness with consent; recipients include Bank of Albania, AIF, General Directorate of Taxation, ASD; data-subject rights under **Law No. 124/2024** (complaints: idp.al). **Not referenced by any onboarding view in these files** — defined but unused here. |

The source header comment flags the legal state: *"Corrected, web-verified legal copy (Albania). Law 124/2024 (not repealed 9887), ASD deposit insurance 2,500,000 ALL, AML recipient AIF, personal NID tax id. PROTOTYPE, final wording requires Raiffeisen legal sign-off."*

### 9. Success Screen (`.success` phase)

`SuccessView` renders a centered `SuccessSeal`, a title "Welcome to Ryze" / "Mirë se erdhe te Ryze" (`.display(38)`), and body "Your Raiffeisen account is open and ready. Your card is on its way, and your first quests are waiting." / "Llogaria jote Raiffeisen është e hapur dhe gati. Karta po vjen dhe sfidat e para të presin." A `PrimaryButton` "Start playing" / "Fillo të luash" invokes `onStart`.

`onStart` is `game.completeAccount(name: model.draft["firstName"])` — the firstName captured (or mock-OCR'd) during onboarding is handed to the `GameModel` to seed the account. This is the handoff point out of onboarding into the main app.

`SuccessSeal` is a branded animation: yellow radial glow, a `CelebrationOverlay(trigger:)` burst, two concentric rings (`Brand.yellow` at 35%, `Brand.gold` at 4pt), a `LogoTile(size: 110)`, and a green `checkmark.circle.fill` badge. It springs in on appear (`response: 0.55, dampingFraction: 0.6`) and fires the burst once.

### 10. Dev "Skip" Path & QA Deep-Links

#### 10.1 On-screen Skip button

Only during `.value`, a top-trailing "Skip" / "Kapërce" capsule button is shown. It calls `game.completeAccount(name: model.draft["firstName"] ?? "Klevi")` — bypassing the entire KYC flow and going straight into the app, defaulting the name to **"Klevi"** when no firstName was entered. This Skip is **not** available once KYC begins.

#### 10.2 Environment-driven QA deep-links (`OnboardingModel.init`)

Commented `// ponytail: QA-only deep-link via env (unset in production)`. The initializer reads `ProcessInfo` environment variables:

| Env var | Effect |
|---|---|
| `RYZE_PHASE` | `"kyc"` → start in `.kyc`; `"success"` → start in `.success`; otherwise unchanged |
| `RYZE_STEP` | integer → sets `stepIndex` |
| `RYZE_SLIDE` | integer → sets `slideIndex` |
| `RYZE_PREFILL` | (presence) prefills `draft`: phone `69 123 456`, firstName `Klevi`, lastName `Berisha`, dob `14/03/2004`, email `klevi@ryze.al`, otp `123456` |
| `RYZE_FLAGS` | (presence) sets `idScanned = true`, `faceChecked = true` |
| `RYZE_CONSENT` | (presence) accepts all mandatory consents: `Set(Legal.consents.filter(\.mandatory).map(\.id))` |

These are intended to be unset in production; they exist solely to land QA at any screen with state pre-populated.

### 11. The "Riz" Assistant (`RizSheet`)

`RizSheet` is a chat surface defined in this file but **not presented from any onboarding view here** (no `.sheet`/navigation wires it into `OnboardingFlow` in these three files — its presenter lives elsewhere). It seeds a greeting: "Hey, I'm Riz. I'll walk you through opening your account, nothing's submitted until you say so. Ask me to explain any step." / SQ equivalent. It accepts `stepWhy: String?` and `seed: Bool`; if `seed` is true it opens with `stepWhy ?? greeting`. User messages append a `RizMessage(fromUser: true)` and a reply from `Riz.reply(stepWhy:text:)` (the `Riz` responder and `RizMessage` type are defined outside these files). Input placeholder: "Ask Riz..." / "Pyet Riz...".

### 12. Localization (EN / SQ)

All user-facing copy in the views and step definitions uses the `T(en, sq)` helper (e.g. `T("Continue", "Vazhdo")`), giving full English/Albanian parity for titles, bodies, why-texts, CTAs, validation/error messages, and capture-sheet status text. **Exceptions (English-only):** the three `Legal.consents` labels, `Legal.disclaimer`, `Legal.depositInsurance`, and `Legal.infoNotice` are plain strings, not `T()`-wrapped, so they display in English regardless of language selection.

### 13. Edge Cases & Open Items

- **OTP resend is cosmetic** — "Resend in 30s" copy with no timer or resend action.
- **Notifications step requests no real permission** — both footer buttons just advance.
- **Email never validated** — collected into `draft["email"]` but no format check gates progression.
- **No upper age bound** — copy says 18–25 but only `< 18` is rejected.
- **`canContinue` for `details` accepts under-18 dates** (only `nil`-checks parse); the real rejection happens at `next()` submit time.
- **Mock OCR back-fill** — `simulateScan()` writes `Klevi` / `Berisha` / `14/03/2004` only when those fields are empty, so re-scanning will not overwrite edited values.
- **Backing out of step 0 silently returns to the carousel** with no confirmation.
- **`depositInsurance` and `infoNotice`** are authored but unused by any view in these files.
- **Entire capture pipeline is simulated** with fixed timers (ID: 1.7s + 0.7s; face: 1.6s ring + 1.7s + 0.7s); no camera, no network, no human review — explicitly disclosed in-UI.

Source files: `/Users/eleviacom/raiffaiesen/ryze-ios/Ryze/OnboardingFlow.swift`, `/Users/eleviacom/raiffaiesen/ryze-ios/Ryze/OnboardingModel.swift`, `/Users/eleviacom/raiffaiesen/ryze-ios/Ryze/Legal.swift`.

# Accounts & Money Movement

## Overview

The Accounts & Money Movement domain is owned by `BankModel`, an `ObservableObject` that holds all banking state (accounts, transactions, contacts, chat threads) and exposes every money-movement operation as a method. The model is a self-contained mock: the source comment states it sits "behind a mock service; real BFF/microservices slot in later." There is no network layer; all balances mutate locally in memory and persist via an encrypted `SecureStore` snapshot.

This chapter covers the account/balance/currency model, the transaction ledger, contacts, the three peer operations (`send` / `request` / split), the Pay tab and its chat threads with money bubbles, and the `AmountSheet` that drives amount entry. Currency exchange (ALL↔EUR) is included because it directly mutates the accounts. Cards (`PaymentCard`, `CardFace`, virtual cards) and savings goals (`Goal`, `GrowView`) are mutated by `BankModel` too but are documented in their own chapters; this chapter references them only where money movement touches them.

> Note on `GameModel` coupling: most money operations call `game?.realAction(...)` to award XP/RyzePoints and advance gamification missions. The exact XP/coin values are listed per-operation below, but the gamification mechanics themselves belong to the Rewards chapter.

---

## Data Model

All banking types are declared at the top of `Bank.swift`. The relevant ones for this domain:

### `Account`

`struct Account: Identifiable, Codable`

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | Stable identifier (`"all"`, `"eur"`). |
| `name` | `String` | Display name (`"Main"`, `"Euro"`). |
| `currency` | `String` | ISO-like code; only `"ALL"` and `"EUR"` exist. |
| `balance` | `Double` (`var`) | Mutable. ALL stored as whole Lek; EUR as decimal. |
| `icon` | `String` | SF Symbol name. |

Seed accounts (`@Published var accounts`):

| id | name | currency | balance | icon |
|---|---|---|---|---|
| `all` | Main | ALL | `42580` | `banknote.fill` |
| `eur` | Euro | EUR | `312.40` | `eurosign.circle.fill` |

The system assumes exactly one ALL account and one EUR account. Helpers locate them by currency, not by id:
- `totalALL` → balance of the first account where `currency == "ALL"` (else `0`).
- `allIndex()` (private) → index of the first ALL account.
- `exchange(...)` looks up both ALL and EUR by `firstIndex(where: currency == ...)`.

Several views index the EUR account positionally as `accounts[1]` (e.g. the Home balance tile reads `bank.accounts[1].balance` for the EUR sub-line). This is a hard-coded assumption that the EUR account is the second element; reordering or removing accounts would crash or misreport. Flag: fragile positional access.

### `Txn`

`struct Txn: Identifiable, Codable`

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | Auto-generated (`let id = UUID()`). |
| `merchant` | `String` | Counterparty / label. |
| `category` | `String` | Free-text category (see categories below). |
| `icon` | `String` | SF Symbol name. |
| `amount` | `Double` | Signed: positive = inflow, negative = outflow. |
| `currency` | `String` | Always `"ALL"` for generated transactions. |
| `day` | `String` | Human bucket label (`"Today"`, `"Yesterday"`, `"Mon"`), not a real date. |

`day` is a display string, never parsed; there is no real timestamp on a transaction. Sorting/recency is purely insertion order (new transactions are `insert(..., at: 0)`).

Seed ledger (`@Published var transactions`), in order:

| merchant | category | icon | amount | currency | day |
|---|---|---|---|---|---|
| Salary, Universiteti | Income | `arrow.down.circle.fill` | `45000` | ALL | Today |
| Spotify | Entertainment | `music.note` | `-549` | ALL | Today |
| Mulliri Vjetër | Eating out | `cup.and.saucer.fill` | `-250` | ALL | Today |
| Drin Hoxha | Sent | `paperplane.fill` | `-1000` | ALL | Yesterday |
| Conad | Groceries | `cart.fill` | `-1840` | ALL | Yesterday |
| Kinema Millennium | Entertainment | `film.fill` | `-700` | ALL | Mon |
| Top-up | Added | `plus.circle.fill` | `5000` | ALL | Mon |

Categories produced by operations: `Income`, `Entertainment`, `Eating out`, `Sent`, `Groceries`, `Added`, `Transfer`, `Exchange`. The Pay tab's "Recent" filter whitelists `["Sent", "Added", "Transfer", "Exchange"]`.

### `Contact`

`struct Contact: Identifiable, Codable`

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | Stable key, also the thread key in `threads`. |
| `name` | `String` | Full name. |
| `tag` | `String` | `@handle`. |
| `onRyze` | `Bool` | Defaults to `true`. Every seed contact is on Ryze; the flag is never set `false` and never gates behavior — UI always renders "on Ryze". |

Seed contacts (`@Published var contacts`):

| id | name | tag |
|---|---|---|
| elsa | Elsa Halili | @elsa |
| drin | Drin Hoxha | @drin |
| mo | Muhamed Alili | @mo |
| sara | Sara Berisha | @sara |
| aleks | Aleks Lime | @aleks |

There is no add-contact flow; the contact list is fixed seed data.

### `MsgKind` and `PayMsg`

`enum MsgKind: Codable { case text, send, request }`

`struct PayMsg: Identifiable, Codable`

| Field | Type | Default | Notes |
|---|---|---|---|
| `id` | `UUID` | auto | |
| `kind` | `MsgKind` | — | `.text`, `.send`, or `.request`. |
| `fromMe` | `Bool` | — | `true` = sent by the local user. |
| `amount` | `Double` | `0` | Used by `.send` / `.request`. |
| `note` | `String` | `""` | Optional memo. |
| `text` | `String` | `""` | Body for `.text` messages. |
| `status` | `String` | `"paid"` | Free-text status: `"paid"` or `"pending"`. |

`status` is a raw `String`, not an enum. Only two values exist in code: `"paid"` and `"pending"`. The money bubble renders `status.capitalized` directly, and pending-request detection compares `status == "pending"`.

### Threads

`@Published var threads: [String: [PayMsg]]` — keyed by `Contact.id`. Seed threads:

| Contact | Messages |
|---|---|
| `elsa` | `.text` (from them): "did you get the concert tickets?" · `.request` (from them): amount `1500`, note `"concert ticket 🎟️"`, status `"pending"` |
| `drin` | `.send` (from me): amount `1000`, note `"taxi last night 🚕"`, status `"paid"` |

Contacts `mo`, `sara`, `aleks` start with no thread (empty on first open).

### Currency formatting — `money(_:_:)`

Free function (`Bank.swift`):

```
func money(_ v: Double, _ ccy: String = "ALL") -> String
```

- Uses a `.decimal` `NumberFormatter`. `maximumFractionDigits` = `2` for EUR, `0` for everything else.
- Formats the **absolute value** (`abs(v)`); the sign is never emitted by `money`. Callers prepend `+`/`-`/`−` themselves.
- Output: EUR → `€<n>` (e.g. `€312.4`); all other → `<n> L` (e.g. `42,580 L`).

`Flows.swift` declares a `fileprivate plainNum(_:_:)` twin used by `ExchangeView` for the converted (output) amount; it formats the signed value (no `abs`) but is otherwise identical formatting logic.

### Exchange rate — `fxRate`

`let fxRate: Double = 98.5` — ALL per 1 EUR, commented "(prototype rate)". Fixed constant; no live FX. Note the seed EUR balance (`312.40`) and the seed ALL balance are unrelated to this rate; it only governs conversions performed in-app.

### Derived/computed properties on `BankModel`

| Property | Definition | Use |
|---|---|---|
| `totalALL` | First ALL account balance, else `0` | Headline balance everywhere. |
| `savedTotal` | Sum of `goals[].saved` | Savings chapter. |
| `monthIncome` | Sum of `transactions` where `amount > 0` | Analytics "Money in". |
| `monthSpend` | Sum of `abs(amount)` where `amount < 0` | Analytics "Money out"; also `cardSpent`. |
| `cardSpent` | `== monthSpend` | Cards chapter. |

`monthIncome`/`monthSpend` aggregate the **entire** transaction array regardless of `day`; "month" is nominal, not a real date window.

---

## Persistence

`BankModel` serializes a `private struct Snapshot: Codable` to an encrypted store.

Snapshot fields: `hideBalance`, `accounts`, `transactions`, `goals`, `card`, `virtualCard`, `cardStyle`, `cardText`, `cardLimit`, `threads`. (`contacts`, `categories`, and `fxRate` are NOT persisted — they are always the hard-coded seed values.)

- `saveState()` — encodes the snapshot with `JSONEncoder` and calls `SecureStore.save(d, "bank")`. (Implementation of `SecureStore` is out of scope for this chapter; it is the encrypted-storage layer.)
- `loadState()` — reads `SecureStore.load("bank")`. One-time migration: if the secure store is empty but legacy cleartext `UserDefaults` key `"ryze_bank_v1"` exists, it copies the data into `SecureStore`, then removes the `UserDefaults` key. Decodes the snapshot and applies each field; collections are only overwritten when non-empty (`if !s.accounts.isEmpty`, etc.) so an empty/partial snapshot falls back to seeds.
- `saveState()` is defined but **not called anywhere in these three files** — no view triggers a save. Flag: state is loaded but apparently never persisted from within this domain's code (a save call presumably lives elsewhere, e.g. on scene-phase change, or is a TODO).

### Init / environment hooks

`init()` reads `ProcessInfo.environment`:
- If **no** env var with prefix `RYZE_` is set → `loadState()` runs (normal launch restores persisted state).
- If `RYZE_REVEAL` is set → `revealed = true; virtualRevealed = true` (card-detail reveal; Cards chapter).
- `RYZE_VCARD` set → seeds a virtual card (Cards chapter).

So when any `RYZE_*` variable is present (screenshot/demo mode), persistence load is skipped and the model uses pristine seed data. Other `RYZE_*` hooks consumed by views in this domain: `RYZE_TAB` (initial selected tab), `RYZE_THREAD` (deep-link a Pay chat thread open on launch).

---

## Money-Movement Operations (`BankModel` methods)

Every operation mutates in-memory state synchronously and (except `sendText`) records a transaction and/or awards gamification. **No operation validates against available balance** — balances can go negative. Validation, where it exists, lives in the calling view (`ExchangeView`, `BankTransferView`), not in the model.

| Method | Signature | Balance effect | Transaction inserted | Thread effect | XP / coins | missionId |
|---|---|---|---|---|---|---|
| `send` | `send(to: Contact, amount: Double, note: String)` | ALL `-= amount` | `merchant=name, category="Sent", icon=paperplane.fill, amount=-amount` | appends `.send` `fromMe:true` `status:"paid"` | xp 40 / coins 20 | `m-transfer` |
| `request` | `request(from: Contact, amount: Double, note: String)` | none | none | appends `.request` `fromMe:true` `status:"pending"` | xp 20 / coins 10 | `m-request` |
| `sendText` | `sendText(_ id: String, _ t: String)` | none | none | appends `.text` `fromMe:true` | none | — |
| `payRequest` | `payRequest(_ cid: String, _ msgId: UUID)` | ALL `-= amt` (msg's amount) | none | sets that msg's `status = "paid"` | xp 30 / coins 15 | `m-transfer` |
| `addMoney` | `addMoney(_ amount: Double)` | ALL `+= amount` | `merchant="Top-up", category="Added", icon=plus.circle.fill, amount=+amount` | none | xp 30 / coins 10 | `m-topup` |
| `exchange` | `exchange(toEUR: Bool, amount: Double)` | see below | `category="Exchange"` | none | xp 15 / coins 5 | `nil` |
| `transferOut` | `transferOut(_ name: String, _ amount: Double)` | ALL `-= amount` | `merchant=name, category="Transfer", icon=building.columns.fill, amount=-amount` | none | xp 40 / coins 20 | `m-transfer` |

Notes:
- `send` derives the toast counterparty as the contact's **first name only** (`c.name.split(separator: " ").first`), e.g. "Sent 1,000 L to Drin". `transferOut` and `exchange` use the full provided string.
- `payRequest` records **no** `Txn` (the balance drops but no ledger row is created) and does not verify the request was incoming/`fromMe == false`; it pays any message found by id, flipping its status to `"paid"`. Flag: missing ledger entry + no fromMe guard.
- `request` records no transaction and no balance change — it is purely a thread artifact awaiting the other side. There is no counterparty/back-end, so a request is never actually fulfilled by the other person; it can only be paid locally if it appears as an incoming pending request.

### `exchange(toEUR:amount:)` detail

Guards: `amount > 0` and both ALL and EUR accounts must be found; otherwise returns silently.

- `toEUR == true`: ALL `-= amount`; EUR `+= amount / fxRate`; inserts `Txn(merchant: "Exchanged to EUR", category: "Exchange", icon: "arrow.left.arrow.right", amount: -amount, currency: "ALL", day: "Today")`.
- `toEUR == false`: EUR `-= amount`; ALL `+= amount * fxRate`; inserts `Txn(merchant: "Exchanged to ALL", ..., amount: +amount * fxRate, currency: "ALL", day: "Today")`.

The recorded transaction is always denominated in ALL (the EUR-side leg is not logged separately). The toast formats the input amount in the **source** currency (`money(amount, toEUR ? "ALL" : "EUR")`). `exchange` passes `missionId: nil`, so it grants XP/coins but advances no mission.

---

## The `AmountSheet`

Defined in `AppViews.swift`. A single reusable amount-entry sheet driving four operations.

```
struct AmountSheet: View {
    enum Mode { case send, request, add, fund }
    let mode: Mode; var contact: Contact? = nil; var goalName: String? = nil
    let onConfirm: (Double, String) -> Void
}
```

The sheet is dumb: it collects an amount + note and calls back `onConfirm(amount, note)`. The actual `BankModel` mutation is wired by the caller's closure.

### Mode-driven copy

| Mode | Title (EN / SQ) | CTA (EN / SQ) | Note field shown? |
|---|---|---|---|
| `.send` | Send money / Dërgo para | Send / Dërgo | yes |
| `.request` | Request money / Kërko para | Request / Kërko | yes |
| `.add` | Add money / Shto para | Add money / Shto | no |
| `.fund` | Add to goal / Shto te synimi | Save / Ruaj | no |

### Layout & behavior

- Header: title + `xmark` close button (`dismiss()`).
- If `contact != nil`: a row with `Avatar`, name, and `@tag`.
- If `goalName != nil`: the goal name in muted text.
- Amount entry: a large (52pt) `TextField` bound to `@State amount: String`, `keyboardType(.numberPad)`, with a trailing `"L"` suffix. **Hard-coded Lek** — the sheet always shows `L` and never offers EUR.
- Note field (`.send`/`.request` only): centered `TextField` with placeholder "Add a note 💬 / Shto një shënim 💬", bound to `@State note`.
- CTA: `PrimaryButton(title: cta, enabled: (Double(amount) ?? 0) > 0)`. Disabled until the parsed amount is `> 0`. On tap: `onConfirm(Double(amount) ?? 0, note); dismiss()`.

Parsing uses `Double(amount)`; a numeric pad restricts to digits, so the amount is effectively a non-negative integer Lek value. No upper bound, no balance check at the sheet level for `.send`/`.request`/`.add`/`.fund`.

### Where `AmountSheet` is instantiated

| Caller | Mode | onConfirm | Detent |
|---|---|---|---|
| `HomeView` "Add" sheet | `.add` | `bank.addMoney(amt)` | `.medium` |
| `PayView` "Add" flow | `.add` | `bank.addMoney(amt)` | `.medium` |
| `ChatThreadView` | `.send` / `.request` | `bank.send(...)` or `bank.request(...)` | `.large` |
| `GrowView` fund / `GoalDetailView` | `.fund` | `bank.fundGoal(gid, amt)` | `.medium` (savings chapter) |

---

## The Pay Tab (`PayView`)

Tab index `2` in `MainTabView`, labeled "Pay / Paguaj" (`paperplane.fill`). Wrapped in a `NavigationStack(path: $path)` where `path: [String]` holds contact ids; `RYZE_THREAD` env var can pre-push one thread on launch.

### Screen structure (top to bottom)

1. **Header** — large title "Pay / Paguaj" and a wallet pill showing current ALL balance: `wallet.pass.fill` + `money(bank.totalALL)`, or `•••` when `bank.hideBalance` is on.
2. **Action console** (`AppCard`, four equal tiles split by hairline dividers):

| Tile | Icon | Label (EN/SQ) | Action |
|---|---|---|---|
| Add | `plus` | Add / Shto | `flow = .add` → `AmountSheet(.add)` |
| Scan | `qrcode` | Scan / Skano | `flow = .scan` → `ScanPayView` |
| Bank | `building.columns.fill` | Bank / Banka | `flow = .bank` → `BankTransferView` |
| Split | `person.2.fill` | Split / Ndaj | `flow = .split` → `SplitBillView` |

`PayFlow` enum: `case add, scan, bank, split`.

3. **Requests section** (only if `pending` non-empty) — eyebrow "Requests / Kërkesa". `pending` is computed as: for each contact, take the **last** message in their thread; include it iff `kind == .request && !fromMe && status == "pending"`. Each renders an `AppCard` with avatar, name, "asks / kërkon {amount} · {note}", and a **Pay** `PillButton` → `bank.payRequest(c.id, m.id)`. With seed data, only Elsa's `1500` "concert ticket 🎟️" request appears here.
4. **Pay-a-friend** — eyebrow "Pay a friend / Paguaj një mik", then a search field bound to `@State search`. Placeholder "Search name or @tag / Kërko emër ose @tag".
5. **Horizontal contact rail** (only when `search` is empty) — all `bank.contacts` as `Avatar`(56) + first name, each a `NavigationLink(value: c.id)` into the chat thread.
6. **Contact list** (`AppCard`) — `filtered` contacts (all, or name/tag case-insensitive match of `search`), each a `NavigationLink` row: avatar, name, "{tag} · on Ryze / në Ryze", chevron.
7. **Recent** (only when results exist and `search` empty) — eyebrow "Recent / Së fundmi", up to 4 transactions from `recent` (transactions whose category ∈ `["Sent","Added","Transfer","Exchange"]`), as read-only rows.

`navigationDestination(for: String.self)` resolves a contact id to `ChatThreadView(contact:)`.

### `PayView` edge cases
- Empty search → rail + full contact list + recent shown. Non-empty search → rail and recent hidden; only the filtered contact list shows. No "no results" empty state in `PayView` (unlike `SearchSheet`).
- `pending` only inspects the **last** message per thread, so an older pending request buried under a newer text/message would not surface in the Requests section.

---

## Chat Threads & Money Bubbles (`ChatThreadView`)

Pushed from `PayView`. Displays one contact's `threads[contact.id]` (empty array if none).

### Layout
- **Custom header bar** (inside the view body, above the system nav title which is set to `contact.name`): `Avatar`(44), name, "{tag} · on Ryze", and two trailing buttons — **Request** (outline pill, opens `AmountSheet(.request)`) and **Send** (yellow pill, opens `AmountSheet(.send)`).
- **Message list** — `ScrollViewReader` + `ScrollView`; on `msgs.count` change it animates `scrollTo(last)`. Each `PayMsg` renders via `bubble(_:)`.
- **Composer bar** — a `Menu` `+` button (yellow circle) offering "Send money / Dërgo para" and "Request money / Kërko para"; a text `TextField` (placeholder "Message / Mesazh"); and an up-arrow send button (dimmed to 0.4 opacity when the trimmed text is empty). Sending calls `bank.sendText(contact.id, trimmed)` and clears the field.

### Sheet wiring
`ChatThreadView` wraps the `AmountSheet.Mode` in a small `SheetWrap: Identifiable` (`id` = 0 for `.send`, 1 for `.request`) to drive `.sheet(item:)`, presented at `.large` detent. On confirm it routes to `bank.send` or `bank.request` accordingly.

### `bubble(_:)` — text vs money
- `.text`: a rounded chat bubble. Right-aligned + dark fill (`Brand.text`) when `fromMe`; left-aligned + elevated surface with hairline when from them. `Spacer(minLength: 36)` enforces side gutter.
- `.send` / `.request`: rendered by `moneyBubble(_:)`.

### `moneyBubble(_:)` — gold money card
A 232pt-wide gold card containing:
- Leading icon — `paperplane.fill` for `.send`, `arrow.down.left` for `.request`.
- Label — "Sent / Dërguar" (send) or "Request / Kërkesë" (request), and the amount in 24pt via `money(m.amount)`.
- The `note` (if non-empty).
- Status row — `checkmark.circle.fill` + status when `"paid"`, else `clock.fill` + status; text is `m.status.capitalized`.
- **Inline Pay button** — shown only when `incoming == (kind == .request && !fromMe && status == "pending")`. It's a dark `PillButton` titled "Pay / Paguaj {money}" → `bank.payRequest(contact.id, m.id)`.

So a pending **incoming** request is payable both from the `PayView` Requests section and from inside the thread bubble. Tapping Pay flips that message's status to `"paid"` (re-rendering as a paid bubble, hiding the button) and deducts the amount from ALL.

### Edge cases
- A pending request **you** sent (`fromMe == true`) shows the clock/pending status with **no** Pay button — there is no counterparty to fulfill it; it remains pending indefinitely.
- `sendText` with whitespace-only input is blocked by the composer's `trimmingCharacters` check.
- Opening a thread with no messages shows the header + empty scroll area + composer.

---

## Split-Bill Flow (`SplitBillView`, `Flows.swift`)

Reached from Pay → Split. A `NavigationStack` sheet titled "Split a bill / Ndaj faturën".

### State & math
- `@State amount: String` (numeric pad, `L` suffix), `@State selected: Set<String>` (selected contact ids).
- `amt = Double(amount) ?? 0`.
- `heads = selected.count + 1` — the payer (local user) is always counted as one head.
- `per = heads > 0 ? amt / Double(heads) : 0` — equal split, payer included.
- `ok = amt > 0 && !selected.isEmpty`.

### Screen
1. Total-bill card: amount field + when `ok`, a yellow line "Split {heads} ways · {money(per)} each / Ndaje në {heads} · {per} secili".
2. "Split with / Ndaj me" — every `bank.contacts` row is a toggle; selected rows show a filled yellow check circle, others an outline ring.
3. `PrimaryButton` — title "Request {money(per)} each / Kërko {per} secili" when `ok`, else "Request / Kërko"; enabled only when `ok`. On tap it loops `selected` and for each contact calls `bank.request(from: c, amount: per, note: T("Split the bill","Ndarje fature"))`, then dismisses.

### Behavior / edges
- Split **requests** each selected friend for their per-head share; it does **not** request the payer's own share (the payer's head only divides the total). It moves no money — it appends a pending `.request` (`fromMe: true`) to each selected thread and awards `request`'s xp 20 / coins 10 per contact.
- Because each generated request is `fromMe: true`, none become payable in-app (consistent with the request limitation above).
- Per-head amount is an unrounded `Double` (e.g. `1000 / 3 = 333.33...`), but `money` renders ALL with 0 fraction digits, so the displayed/stored share appears as `333 L` while the underlying `PayMsg.amount` keeps full precision.
- No selection or zero amount → CTA disabled.

---

## Exchange Flow (`ExchangeView`, `Flows.swift`)

ALL↔EUR converter. Opened from Home (Exchange tile) and from `GrowView`'s "Convert currency" card. `NavigationStack` titled "Exchange / Këmbe".

### State
- `@State toEUR = true` (direction), `@State amount: String`.
- `amt = Double(amount) ?? 0`.
- `fromCcy = toEUR ? "ALL" : "EUR"`, `toCcy` is the opposite.
- `converted = toEUR ? amt / fxRate : amt * fxRate`.
- `srcBalance` = balance of the `fromCcy` account.
- `ok = amt > 0 && amt <= srcBalance` — **this view does enforce sufficient funds.**

### Screen
- **From** row (`input: true`): label, "{ccy} · {balance}", and an editable `decimalPad` field. (EUR→ALL direction allows decimals here.)
- A swap button (`arrow.up.arrow.down`, gold circle) toggling `toEUR`.
- **To** row (`input: false`): shows the read-only `converted` value via `plainNum(converted, ccy)`, animated with numeric transition.
- Rate line: "Exchange rate / Kursi i këmbimit" → `1 EUR = 98.5 L` (`String(format: "%.1f", fxRate)`).
- `PrimaryButton`: enabled iff `ok`. Title is "Exchange / Këmbe" normally; if `amt > srcBalance` it reads "Not enough funds / Fonde të pamjaftueshme". On tap: `bank.exchange(toEUR: toEUR, amount: amt); dismiss()`.

### Edges
- Insufficient funds disables the CTA and relabels it. Zero/empty amount disables it.
- The displayed converted amount is purely informational; the model recomputes the conversion itself in `exchange`.

---

## Bank Transfer Flow (`BankTransferView`, `Flows.swift`)

Reached from Pay → Bank. External (out-of-network) transfer by IBAN. `NavigationStack` titled "Bank transfer / Transfertë bankare".

### State & validation
- `@State name`, `@State iban`, `@State amount`.
- `amt = Double(amount) ?? 0`.
- `ok = amt > 0 && amt <= bank.totalALL && iban.count >= 8 && !name.isEmpty` — requires positive amount within ALL balance, an IBAN of at least 8 chars, and a non-empty recipient name.

### Screen
- `RyzeField` "Recipient name / Emri i marrësit" (placeholder "Drin Hoxha").
- `RyzeField` "IBAN" (placeholder "AL47 2026 1100 ...").
- Amount card: numeric-pad field with `L` suffix and "Available {money(totalALL)}" subtext.
- `PrimaryButton`: enabled iff `ok`; title "Send transfer / Dërgo transfertën", or "Not enough funds / Fonde të pamjaftueshme" when `amt > totalALL`. On tap: `bank.transferOut(name, amt); dismiss()`.

IBAN format is only length-checked (`>= 8`); there is no checksum or country validation. The transfer is mock — `transferOut` only debits ALL and logs a `Transfer` row; nothing is sent anywhere.

---

## Scan & Pay (`ScanPayView`, `Flows.swift`)

Reached from Pay → Scan. Segmented control between **Scan** and **My code**.

- **My code**: renders a QR via `qrImage("ryze://pay/\(game.referralCode)")` (the referral code lives in `GameModel`; the deep-link scheme `ryze://pay/...` is defined here but there is no handler for inbound scans). Shows "@{name} · {referralCode}" and "Show this to get paid instantly".
- **Scan**: a static viewfinder graphic (`qrcode.viewfinder`) with copy "Point at a Ryze QR to pay" and the explicit disclaimer "Camera isn't available in the simulator / Kamera nuk disponohet në simulator".

Flag: Scan & Pay is non-functional — there is no camera capture, no QR decoding, and no money movement. It is a visual stub. The `ryze://pay/<code>` URL is generated but not consumed.

---

## Home Tab — Money Surfaces (`HomeView`)

The Home dashboard (tab `0`) surfaces account/transaction state and routes into money flows. Money-relevant elements:

### Balance tile
- Header "Balance / Gjendja" with an eye toggle that flips `bank.hideBalance` (animated `eye`/`eye.slash`).
- Large `money(bank.totalALL)` with `.numericText()` transition; when `hideBalance` it blurs/fades to a `•• ••• L` placeholder.
- Sub-line: EUR balance via `money(bank.accounts[1].balance, "EUR")` (positional `[1]` access — see fragility note), blanked when hidden.
- A week sparkline (`weekBars`).
- Tapping the tile opens the Analytics sheet.

### `weekBars` (and the Cards equivalent `cardBars`)
- Takes up to 7 outflow magnitudes: `transactions.filter { amount < 0 }.prefix(7).map { abs }`.
- Pads to 7 with a deterministic pseudo-pattern: `while v.count < 7 { v.append(Double((v.count * 137 % 380) + 140)) }` — commented `// ponytail: pad to 7 for the sparkline`. So the sparkline is partly synthetic filler when fewer than 7 outflows exist. (`CardsView.cardBars` uses the same idea with multiplier `151` and modulus `360`, offset `120`.)
- `weekNet` = sum of the first 8 negative amounts (`prefix(8)`), shown as `−{money(weekNet)}` on the spend tile.

### Move-money console
An `AppCard` with four tiles:

| Tile | Icon | Action |
|---|---|---|
| Add | `plus` | `homeSheet = .add` → `AmountSheet(.add)` (`.medium`) |
| Send | `paperplane.fill` | `sel = 2` (jump to Pay tab) |
| Request | `arrow.down.left` | `sel = 2` (jump to Pay tab) |
| Exchange | `arrow.left.arrow.right` | `homeSheet = .exchange` → `ExchangeView` |

Send and Request on Home do **not** open an amount sheet — they switch to the Pay tab, where the user picks a contact first.

### Recent activity
A capped list of `bank.transactions.prefix(5)` via `txnRow`, with a "See all / Shiko të gjitha" link opening `TxnHistorySheet`. Inflows render in `Brand.good` with `+`, outflows in `Brand.text` with `-` (using `money(t.amount, t.currency)` which already strips the sign).

### `HomeView.HSheet` routes
`enum HSheet { case add, profile, grow, history, analytics, exchange, search }` → `AmountSheet(.add)`, `ProfileSheet`, `GrowView`, `TxnHistorySheet`, `AnalyticsView`, `ExchangeView`, `SearchSheet`.

---

## Supporting Read-Only Views

### `TxnHistorySheet` (`AppViews.swift`)
Full ledger. `NavigationStack` titled "All activity / Aktiviteti", listing **all** `bank.transactions` (not capped) as the same row layout as Home, with hairline separators. "Done / U krye" toolbar dismiss. Read-only — no filtering, search, or detail drill-down.

### `SearchSheet` (`Flows.swift`)
Global search over transactions + contacts. Bound to `@State q`. With empty `q`, both result sets are empty. Otherwise:
- `people` = contacts matching name or tag (case-insensitive).
- `txns` = transactions matching merchant or category (case-insensitive).
Renders "People / Njerëz" and "Transactions / Transaksione" sections; if `q` is non-empty and both are empty, shows "No results / Asnjë rezultat". People rows are **not** tappable here (no navigation), unlike in `PayView`.

### `AnalyticsView` (`Flows.swift`)
Spending analytics, opened from the Home balance/spend tiles. Read-only.
- **This month** card: `flowStat` "Money in" (`monthIncome`, green) and "Money out" (`monthSpend`, red), plus a "Net flow" row = `monthIncome - monthSpend`, with two proportional bars.
- **Where it goes**: iterates `bank.categories` (the fixed `SpendCat` list below) with per-category bars normalized to `maxCat`.
- **Top merchants**: derived live from transactions — sums `abs(amount)` per merchant for outflows, sorts desc, takes top 4.
- **Insight**: a static Riz tip string about eating-out budgeting (hard-coded copy, not computed).

`categories` (`SpendCat`, fixed seed — these power Analytics' "Where it goes" but are **not** derived from `transactions`):

| id | name | icon | amount | color (hex) |
|---|---|---|---|---|
| c1 | Eating out | `fork.knife` | `6400` | `0xFF6F47` |
| c2 | Groceries | `cart.fill` | `5200` | `0x2FE3B6` |
| c3 | Entertainment | `film.fill` | `3100` | `0x8B5CFF` |
| c4 | Transport | `bus.fill` | `1800` | `0x46A8FF` |

`SpendCat` is `Identifiable` but **not** `Codable` (it holds a SwiftUI `Color`), which is why it is excluded from the persisted snapshot. Its `amount`s are static and do not change as the user transacts; only the "Top merchants" block reflects live transaction data.

---

## Cross-Cutting States & Edge Cases

- **Negative balances allowed**: `send`, `payRequest`, `addMoney`(only adds), `fundGoal`, and the unguarded paths can drive ALL below zero. Only `ExchangeView` and `BankTransferView` gate on balance at the view layer; `AmountSheet`-driven sends/requests/funds do not.
- **`hideBalance`** is global and persisted; it masks the Home balance tile and the Pay header wallet pill (`•••`). It does not mask transaction amounts or the gold money bubbles.
- **No real dates**: every generated `Txn.day` is `"Today"`; `monthIncome`/`monthSpend` are running totals over the full array, so "this month" figures grow without bound as the user transacts.
- **Demo/screenshot mode**: any `RYZE_*` env var skips `loadState()`, giving deterministic seed data for captures; `RYZE_TAB` and `RYZE_THREAD` deep-link a tab/thread.
- **Mock everywhere**: there is no backend; `request`/split requests can never be paid by a real counterparty, Scan & Pay does nothing, and `transferOut`/IBAN transfers go nowhere. All "money movement" is a local ledger simulation.

## Flagged TODOs / Placeholders / Stubs

- `Bank.swift:3` — explicit comment: banking is "behind a mock service; real BFF/microservices slot in later."
- `Bank.swift:102` — `fxRate = 98.5` flagged "(prototype rate)"; no live FX.
- `Bank.swift` — `saveState()` defined but never invoked in these files; persistence appears not to be triggered from this domain. Possible missing call / TODO.
- `payRequest` records no `Txn` and lacks a `fromMe`/incoming guard.
- `ScanPayView` — non-functional stub; "Camera isn't available in the simulator" disclaimer; `ryze://pay/<code>` deep link is generated but never handled.
- `HomeView.weekBars` / `CardsView.cardBars` — sparkline data is padded with synthetic pseudo-random filler when fewer than 7 outflows exist (`// ponytail: pad to 7`).
- `AnalyticsView` "Where it goes" uses the **static** `categories` seed amounts, not live transaction sums; the "Insight" copy is hard-coded, not computed.
- `accounts[1]` positional EUR access in the Home balance tile — fragile assumption about array order.
- `Contact.onRyze` exists but is never toggled or used to gate behavior.
- `ComingSoonSheet` (`Flows.swift`) is a generic placeholder ("on the Ryze prototype roadmap, coming soon") for unbuilt destinations — not wired to any money-movement entry point in these files, but present as the fallback pattern for stubbed features.

# Cards & Card Studio

## Overview

The Cards tab is the third tab in `MainTabView` (tab tag `1`, label `T("Cards", "Kartat")`, SF Symbol `creditcard.fill`). It is implemented by the `CardsView` view in `AppViews.swift`. The tab surfaces the user's primary physical/debit card, an optional virtual card, card controls (freeze, biometric detail reveal, Apple Pay provisioning, spending limit), per-feature toggles, a spend/limit summary, and entry points into Card Studio personalisation and physical-card ordering.

All card state lives on the single `BankModel` (`ObservableObject`) in `Bank.swift`, injected as an `@EnvironmentObject`. Card visuals are rendered by the shared `CardFace` view (`Flows.swift`). The Cards screen reads `game.name` (cardholder name) from the injected `GameModel`.

Everything in this domain is a **local prototype**: there is no card-network integration, no real PAN, and no Apple Wallet provisioning. The revealed PAN, expiry, and CVV are **hard-coded constants** (see [Biometric reveal gate](#biometric-reveal-gate-panexpirycvv)). Persistence is local only (`SecureStore`, encrypted store keyed `"bank"`).

---

## Data model

### `PaymentCard` (`Bank.swift`)

Both the physical and virtual cards are instances of one struct.

| Field | Type | Meaning |
|---|---|---|
| `last4` | `String` | Last four digits shown on the card face and in lists. |
| `frozen` | `Bool` | Freeze state; when `true` the card face shows a frost overlay. |
| `online` | `Bool` | "Online payments" feature toggle. |
| `contactless` | `Bool` | "Contactless" feature toggle. |
| `atm` | `Bool` | "ATM withdrawals" feature toggle. |

`PaymentCard` is `Codable`. It has no `id`; it is held directly on `BankModel`.

### Card-related fields on `BankModel`

| Property | Type | Initial value | Notes |
|---|---|---|---|
| `card` | `PaymentCard` | `last4: "4827"`, `frozen: false`, `online: true`, `contactless: true`, `atm: true` | The primary (physical/debit) card. Always present. |
| `revealed` | `Bool` | `false` (or `true` if env `RYZE_REVEAL` set) | Whether the primary card's PAN/expiry/CVV are shown. |
| `virtualCard` | `PaymentCard?` | `nil` (or a card with `last4: "8842"`, `contactless: false`, `atm: false` if env `RYZE_VCARD` set) | Optional second card. |
| `virtualRevealed` | `Bool` | `false` (or `true` if env `RYZE_REVEAL` set) | Whether the virtual card's details are shown. |
| `cardLimit` | `Double` | `50000` | Monthly spending limit (ALL). |
| `cardStyle` | `CardStyle` | `.gold` | Selected card colour/style (see Card Studio). |
| `cardText` | `String` | `""` | Custom print text on the card front. |

Derived:

| Property | Type | Definition |
|---|---|---|
| `cardSpent` | `Double` | `monthSpend` — sum of `abs(amount)` over all transactions with `amount < 0`. Card "spend this month" reuses the global month-spend figure; it is not card-scoped. |

> **Note / placeholder:** `cardSpent` is an alias of total monthly outflow, not card-specific spend. There is no per-card transaction attribution in the prototype.

### `CardStyle`

The enum drives card colours and ink. It is **defined outside the three files read** (referenced in `Bank.swift`, `AppViews.swift`, `Flows.swift` but declared elsewhere in the project). The following members are exercised by the Cards domain and can be relied on:

| Member / property | Used in | Purpose |
|---|---|---|
| `.gold` | default `cardStyle`; primary card face | Default style; the gold/yellow card. |
| `.midnight` | virtual card face (`style: .midnight`) | Style applied to the virtual card. |
| `CardStyle.allCases` | `CardStudioSheet` colour picker | Conforms to `CaseIterable`. |
| `s.colors` (`[Color]`) | `CardFace` gradient, Card Studio swatches | Gradient stops for the card fill. |
| `s.ink` (`Color`) | `CardFace` text colour | Foreground/ink colour for text on the card. |
| `s.swatch` (`Color`) | `CardFace` shadow | Tint of the card's coloured shadow. |
| `s.title` (`String`) | Card Studio labels | Human-readable style name. |
| `id` | `ForEach` in pickers | `Identifiable`. |

> The full set of `CardStyle` cases (beyond `.gold` and `.midnight`) is not in the files read; the colour picker enumerates `CardStyle.allCases`, so every defined case appears as a swatch.

### Persistence

`BankModel.Snapshot` (private `Codable`) persists card state via `SecureStore.save(_, "bank")` on `saveState()` and restores on `loadState()`:

- Persisted card fields: `card`, `virtualCard`, `cardStyle`, `cardText`, `cardLimit`.
- **Not persisted:** `revealed` and `virtualRevealed` (reveal state is always reset on relaunch — the biometric gate must be re-passed).
- `loadState()` performs a one-time migration from cleartext `UserDefaults` key `ryze_bank_v1` into `SecureStore`.

---

## Screens & components

### `CardsView` (the Cards tab)

Rendered inside a `ScreenScroll`. Top to bottom:

1. **Title row** — `Text(T("Cards", "Kartat"))` at 34pt bold.
2. **Primary card face** — `CardFace(last4: bank.card.last4, frozen: bank.card.frozen, revealed: bank.revealed, name: game.name, style: bank.cardStyle, customText: bank.cardText)`. Wrapped in `.redactWhileCapturing()` (hidden during screen capture). Tapping it calls `toggleReveal()`.
3. **Control strip** — one `AppCard` with four `ctrlTile`s separated by `ctrlDivider`:
   - **Freeze / Unfreeze** (`snowflake`): label toggles `T("Freeze","Ngrije")` ⇄ `T("Unfreeze","Shkrije")`; `active: bank.card.frozen`; action `bank.toggleFreeze()`.
   - **Details / Hide** (`eye` / `eye.slash`): label `T("Details","Detajet")` ⇄ `T("Hide","Fshih")`; `active: bank.revealed`; action `toggleReveal()`.
   - **Apple Pay** (`creditcard.fill`): opens `ApplePaySheet` (`cardFlow = .applePay`).
   - **Limits** (`slider.horizontal.3`): opens `CardLimitSheet` (`cardFlow = .limit`).
   - An active tile renders with a yellow (`Brand.yellow`) background and black icon; inactive tiles use `Brand.elev3`.
4. **Spend + limit bento row** (two `AppCard`s, height 132):
   - **Spent this month** (`T("Spent this month","Këtë muaj")`): a yellow `cardSparkline(cardBars)` plus `money(bank.cardSpent)`.
   - **Monthly limit** (`T("Monthly limit","Limiti mujor")`): `money(bank.cardLimit)`, a `ProgressBar(value: min(1, cardSpent/cardLimit))`, and `"<pct>% used"`. The whole tile is a button that opens `CardLimitSheet`.
5. **Card controls** section (`eyebrow T("Card controls","Kontrollet e kartës")`) — one `AppCard` with three `toggleRow`s bound directly to the card struct:
   - `T("Online payments","Pagesa online")` (`globe`) ↔ `$bank.card.online`
   - `T("Contactless","Pa kontakt")` (`wave.3.right`) ↔ `$bank.card.contactless`
   - `T("ATM withdrawals","Tërheqje ATM")` (`banknote`) ↔ `$bank.card.atm`
   - Toggles are tinted `Brand.yellow`; they mutate the card struct directly with no confirmation.
6. **Virtual card** section (`eyebrow T("Virtual card","Kartë virtuale")`) — see [Virtual card](#virtual-card).
7. **Manage** section (`eyebrow T("Manage","Menaxho")`) — two row buttons:
   - **Order a physical card** (`creditcard.and.123`): subtitle `T("Free delivery in 5-7 days","Dërgesë falas brenda 5-7 ditëve")`; opens `OrderCardSheet` (`cardFlow = .order`).
   - **Personalise your card** (`paintbrush.fill`, `Brand.violet`): subtitle `T("Colours and your own text","Ngjyra dhe teksti yt")`; opens `CardStudioSheet` (`cardFlow = .studio`).

#### `CardFlow` enum (sheet router)

```
enum CardFlow: Int, Identifiable { case order, applePay, limit, studio }
```

| Case | Presents |
|---|---|
| `.order` | `OrderCardSheet` |
| `.studio` | `CardStudioSheet` |
| `.applePay` | `ApplePaySheet` |
| `.limit` | `CardLimitSheet` |

Presented via `.sheet(item: $cardFlow)`.

#### `cardBars`

Sparkline source: last 7 negative-amount transaction magnitudes, padded to 7 with the deterministic filler `Double((v.count * 151 % 360) + 120)` when fewer than 7 spends exist (the comment in the sibling `HomeView` flags this as a "ponytail" pad). `cardSparkline` renders fixed-height (28pt) yellow capsules; unlike Home's sparkline it has **no** rise-in animation.

### `CardFace` (`Flows.swift`)

Reusable card visual. Parameters:

| Param | Type | Default | Role |
|---|---|---|---|
| `last4` | `String` | — | Trailing 4 digits. |
| `frozen` | `Bool` | `false` | Shows frost overlay when `true`. |
| `revealed` | `Bool` | `false` | Switches masked ↔ full PAN/expiry/CVV. |
| `name` | `String` | `"RYZE"` | Cardholder name (uppercased). |
| `style` | `CardStyle` | `.gold` | Colour/ink/swatch. |
| `label` | `String` | `"Debit · Premium"` | Top-right tag; virtual card passes `T("Virtual","Virtuale")`. |
| `customText` | `String` | `""` | Custom print text; rendered uppercased, single line, only when non-empty. |

Fixed visual facts:
- Card height **208pt**, corner radius 24, white 16%-opacity stroke, coloured shadow tinted by `style.swatch`.
- Header: `Image("RaiffeisenLogo")` (34×34) top-left; `label` top-right.
- Chip + `wave.3.right` contactless glyph row.
- Network mark: when not revealed the bottom-right shows `"VISA"`; when revealed it shows expiry + CVV.
- Frozen overlay: black 50% scrim with `snowflake` glyph and `T("Frozen","Ngrirë")`.

> **Hard-coded reveal values (placeholder):** When `revealed == true`, `CardFace` renders the PAN as `"4827  2156  9043  \(last4)"` and the expiry/CVV as `"09/29  ·  412"`. These constants are identical for the physical and virtual cards (only `last4` differs), so the "revealed" details are mock, not derived from the card model. The masked state shows `"••••  ••••  ••••  \(last4)"` and `"VISA"`.

---

## Biometric reveal gate (PAN/expiry/CVV)

Revealing full card details is step-up authenticated; hiding is not.

`CardsView.toggleReveal()`:
- If `bank.revealed` is already `true`: animate it to `false` immediately (no auth).
- If `false`: run `Task { if await AppLockModel.confirm(T("Reveal your card details","Shfaq detajet e kartës")) { bank.revealed = true } }`. Only on a successful `AppLockModel.confirm` does `revealed` flip to `true` (animated `.smooth(duration: 0.3)`).

`toggleVirtualReveal()` is identical against `bank.virtualRevealed`, using the same prompt string.

Behavioural facts and edge cases:
- The reveal gate is invoked from **two** places per card: tapping the card face (`onTapGesture`) and the **Details/Hide** control tile (primary card only). The virtual card's reveal is triggered only by tapping its face.
- `AppLockModel.confirm(...)` performs the Face ID / passcode challenge (defined outside the read files). On failure or cancel, `revealed`/`virtualRevealed` stay `false`.
- Reveal flags are **not persisted** (absent from `Snapshot`), so every relaunch starts masked and re-requires authentication.
- Demo/screenshot bypass: env var `RYZE_REVEAL` sets both `revealed = true` and `virtualRevealed = true` at init, skipping the gate (screenshot hook). The card face is still wrapped in `.redactWhileCapturing()` so the visible details are redacted during OS screen capture.
- Revealing does not consume XP/points and triggers no `realAction`.

---

## Freeze toggle

Two independent freeze states.

| | Primary card | Virtual card |
|---|---|---|
| State | `bank.card.frozen` | `bank.virtualCard?.frozen` |
| Toggle method | `toggleFreeze()` → `card.frozen.toggle()` | `toggleVirtualFreeze()` → `virtualCard?.frozen.toggle()` |
| UI trigger | Freeze/Unfreeze `ctrlTile` in control strip | `PillButton` (icon `snowflake`, style `.soft`) under the virtual card |
| Label | `T("Freeze","Ngrije")` ⇄ `T("Unfreeze","Shkrije")` | same labels |
| Visual effect | `CardFace.frozen` frost overlay; control tile shows `active` (yellow) | `CardFace.frozen` frost overlay |

Freezing/unfreezing is instant, awards no XP/points, requires no confirmation or auth, and persists via `Snapshot.card` / `virtualCard`.

---

## Spending limits

`CardLimitSheet` (`Flows.swift`), title `T("Card limit","Limiti i kartës")`, opened from the **Limits** control tile or the **Monthly limit** bento tile.

Contents:
- **Summary card**: `T("Monthly spending limit","Limiti mujor i shpenzimeve")`, current `money(bank.cardLimit)` (numeric-text transition), `ProgressBar(value: min(1, cardSpent/cardLimit))`, and `"<money(cardSpent)> spent so far"`.
- **Quick set** grid (`T("Quick set","Vendos shpejt")`): four preset buttons `presets: [25000, 50000, 100000, 200000]`. The currently-selected preset (`bank.cardLimit == p`) renders with a gold fill + black text; tapping sets `bank.cardLimit = p` (animated `.snappy`).
- **Nudge buttons**: `PillButton "− 5,000"` → `bank.cardLimit = max(5000, bank.cardLimit - 5000)` (floor 5,000); `PillButton "+ 5,000"` → `bank.cardLimit += 5000` (no upper cap).
- **Save**: `PrimaryButton(T("Save limit","Ruaj limitin"))` simply dismisses; `cardLimit` is already mutated live on the model, so "Save" is purely a dismiss action.

Edge cases / facts:
- Lower bound 5,000 (via the `−` nudge only; presets and `+` ignore it). No upper bound on `+`.
- The limit is informational against `cardSpent`; nothing in the code blocks a payment when the limit is exceeded. Limit is a display/personalisation value, not an enforced control.
- `cardLimit` persists in `Snapshot`.

---

## Virtual card

Section header `T("Virtual card","Kartë virtuale")`. Two states:

### When `bank.virtualCard == nil` (no virtual card)

A button row inside an `AppCard`:
- Icon `plus.rectangle.on.rectangle` (`Brand.violet`).
- Title `T("Create a virtual card","Krijo kartë virtuale")`.
- Subtitle `T("Safer online shopping, freeze anytime","Më e sigurt online, ngrije kurdo")`.
- Action: `bank.createVirtualCard()` (animated).

`createVirtualCard()`:
```
virtualCard = PaymentCard(last4: String(format: "%04d", Int.random(in: 1000...9999)),
                          frozen: false, online: true, contactless: false, atm: false)
game?.realAction("Virtual card created", missionId: nil, xp: 20, coins: 10)
```
- `last4` is a **random** 4-digit string; `contactless` and `atm` default off; `online` on.
- Awards **+20 XP, +10 coins** via `realAction` (no mission attached, `missionId: nil`). Copy string `"Virtual card created"` is not localised.

### When a virtual card exists

- `CardFace(last4: v.last4, frozen: v.frozen, revealed: bank.virtualRevealed, name: game.name, style: .midnight, label: T("Virtual","Virtuale"))`, `.redactWhileCapturing()`, tap → `toggleVirtualReveal()`. Style is forced to `.midnight` regardless of `bank.cardStyle` (Card Studio does not affect the virtual card).
- Two `PillButton`s (style `.soft`):
  - **Freeze/Unfreeze** (`snowflake`) → `bank.toggleVirtualFreeze()`.
  - **Delete** (`trash`) → `bank.deleteVirtualCard()` (animated).

`deleteVirtualCard()` sets `virtualCard = nil` and `virtualRevealed = false`. No confirmation dialog, no XP/points. The virtual card has **no** dedicated control strip (no online/contactless/ATM toggles surfaced in the UI even though the struct carries those fields), no Apple Pay, no limit, and no Card Studio entry. It persists via `Snapshot.virtualCard`.

> **Note:** The virtual-card path is the only place `online/contactless/atm` differ from the primary card's defaults, and those flags are never shown or editable for the virtual card in the Cards UI.

---

## Card Studio (personalisation)

`CardStudioSheet` (`Flows.swift`), title `T("Personalise card","Personalizo kartën")`, opened from **Personalise your card** in the Manage section (`cardFlow = .studio`).

Local working state, seeded from the model on appear:
```
@State private var style: CardStyle = .gold
@State private var text: String = ""
...
.onAppear { style = bank.cardStyle; text = bank.cardText }
```

Contents:
1. **Live preview**: `CardFace(last4: bank.card.last4, name: game.name, style: style, customText: text)` — updates as colour/text change.
2. **Colour** (`eyebrow T("Colour","Ngjyra")`): a horizontal row over `CardStyle.allCases`. Each option is a gradient-filled circle (`s.colors`, 44×44) plus `s.title`. The selected style gets a thicker `Brand.text` ring (2.5pt vs 1pt) and emphasised label; tap sets `style = s` (animated `.snappy`).
3. **Your text** (`eyebrow T("Your text","Teksti yt")`): a `RyzeField` labelled `T("Printed on the card front","Shkruar në pjesën e përparme të kartës")`, placeholder `T("e.g. DREAM BIG","p.sh. ËNDËRRO LART")`. The binding setter clamps input: `text = String($0.prefix(16))` — **hard 16-character cap**. Helper line `T("Up to 16 characters.","Deri në 16 shenja.")`.
4. **Apply**: `PrimaryButton(T("Apply to my card","Apliko te karta ime"))`:
   ```
   bank.cardStyle = style; bank.cardText = text
   game.realAction(T("Card personalised","Karta u personalizua"), missionId: nil, xp: 10, coins: 5)
   dismiss()
   ```

Facts / edge cases:
- Apply awards **+10 XP, +5 coins** (no mission). Closing without Apply discards changes (the `@State` is local; model is only written on Apply).
- The custom text appears on the card front only when non-empty (`CardFace` guards `!customText.isEmpty`); it is rendered uppercased, single-line, with letter spacing.
- Card Studio affects only the **primary** `card` (via `cardStyle`/`cardText`); the virtual card is always `.midnight` and shows no custom text.
- Both `cardStyle` and `cardText` persist in `Snapshot`.
- The cardholder name (`game.name`) is not editable from Card Studio.

---

## Other card flows

### `OrderCardSheet` — Order a physical card (`Flows.swift`)

Title `T("Order card","Porosit kartë")`. Two phases controlled by local `@State private var ordered = false`.

Pre-order:
- `CardFace` preview using `bank.card.last4`, `bank.cardStyle`, `bank.cardText`.
- `T("Deliver to","Dërgo te")` + a non-interactive `Map` (`.allowsHitTesting(false)`) centred on a fixed coordinate (41.31735, 19.81755 — Tiranë) with a `Marker` `T("Your address","Adresa jote")`.
- `RyzeField` `T("Delivery address","Adresa e dërgesës")`, pre-filled `"Rruga Myslym Shyri 14, Tiranë"`.
- Estimated-delivery card: `T("5-7 business days · free","5-7 ditë pune · falas")`.
- `PrimaryButton(T("Order card","Porosit kartën"))`: animates `ordered = true` and calls `game.realAction(T("Physical card ordered","Karta u porosit"), missionId: nil, xp: 0, coins: 0)` — **0 XP, 0 coins**.

Post-order: success state (`checkmark.circle.fill`), `T("Your card is on its way!","Karta jote është në rrugë!")`, free-delivery copy, and `PrimaryButton(T("Done","U krye"))` to dismiss.

> **Placeholder:** Ordering does nothing beyond the local success screen — no card record is created or replaced, no shipment is initiated. The address field and map are decorative.

### `ApplePaySheet` — Add to Apple Wallet (`Flows.swift`)

Title `"Apple Pay"`. Local `@State private var added = false`.

Pre-add:
- "Pay" wordmark (`applelogo` + "Pay").
- `CardFace` preview (`bank.card.last4`, `bank.cardStyle`, `bank.cardText`).
- Detail card with `walletRow`s: `T("Card","Karta")` → `"Ryze Debit  ••\(bank.card.last4)"`; `T("Device","Pajisja")` → `"iPhone"`; `T("Use for","Përdor për")` → `T("Contactless & in-app","Pa kontakt & në app")`.
- Disclaimer: `T("Prototype, no real card is provisioned to Apple Wallet.","Prototip, asnjë kartë reale nuk shtohet në Apple Wallet.")`.
- Black **Add to Apple Wallet** button: animates `added = true` and calls `game.realAction(T("Added to Apple Wallet",...), missionId: nil, xp: 0, coins: 0)` — **0 XP, 0 coins**.

Post-add: success state, `T("Added to Apple Wallet","U shtua në Apple Wallet")`, Face-ID usage copy, `PrimaryButton(T("Done","U krye"))`.

> **Placeholder (stated in-app):** No real card is provisioned; the sheet is a visual prototype only. Apple Pay applies only to the primary card.

---

## Card state summary

| Concern | States | Where shown |
|---|---|---|
| Existence | Primary card always exists; virtual card `nil` / present | Cards tab |
| Freeze (primary) | `frozen` true/false | Card face frost + control tile `active` |
| Freeze (virtual) | `frozen` true/false | Virtual card face frost |
| Reveal (primary) | masked / revealed (`bank.revealed`) | Card face digits + Details/Hide tile |
| Reveal (virtual) | masked / revealed (`bank.virtualRevealed`) | Virtual card face digits |
| Feature toggles (primary) | `online`, `contactless`, `atm` each on/off | Card controls section |
| Spend vs limit | `cardSpent` vs `cardLimit`, capped at 100% in UI | Bento tiles + CardLimitSheet (not enforced) |
| Style/text (primary) | `cardStyle` (default `.gold`), `cardText` (≤16 chars, default empty) | Card face + Card Studio |
| Order status | local `ordered` flag in `OrderCardSheet` only | Order sheet (ephemeral) |
| Apple Pay | local `added` flag in `ApplePaySheet` only | Apple Pay sheet (ephemeral) |

## XP / points awarded in the Cards domain

| Action | Method | XP | Coins | Mission | Copy (localised?) |
|---|---|---|---|---|---|
| Create virtual card | `createVirtualCard()` | 20 | 10 | `nil` | `"Virtual card created"` (not localised) |
| Personalise card (Apply) | Card Studio Apply | 10 | 5 | `nil` | `T("Card personalised","Karta u personalizua")` |
| Order physical card | `OrderCardSheet` | 0 | 0 | `nil` | `T("Physical card ordered","Karta u porosit")` |
| Add to Apple Wallet | `ApplePaySheet` | 0 | 0 | `nil` | `T("Added to Apple Wallet",...)` |
| Freeze / unfreeze (either card) | `toggleFreeze()` / `toggleVirtualFreeze()` | 0 | 0 | — | — |
| Reveal / hide details | `toggleReveal()` / `toggleVirtualReveal()` | 0 | 0 | — | — |
| Change limit | `CardLimitSheet` | 0 | 0 | — | — |
| Delete virtual card | `deleteVirtualCard()` | 0 | 0 | — | — |

None of the Cards-domain `realAction` calls reference a mission (`missionId: nil`), so card actions never advance gamified missions.

## Flagged placeholders / TODOs

- **Mock PAN/expiry/CVV**: revealed values are the hard-coded `"4827 2156 9043 <last4>"` and `"09/29 · 412"` in `CardFace`; identical across physical and virtual cards.
- **`cardSpent` is not card-scoped**: it equals total monthly outflow (`monthSpend`), not card-attributed spend.
- **Spending limit is not enforced**: purely a display/personalisation value; nothing blocks transactions over `cardLimit`.
- **Order card** and **Apple Pay** are explicitly prototypes (the Apple Pay disclaimer states no real provisioning); they create no real records and yield 0 XP/coins.
- **Virtual card** `online/contactless/atm` flags exist in the model but are not surfaced or editable in the virtual-card UI.
- **`CardStyle`** full case list is defined outside the three files read; the colour picker shows `CardStyle.allCases`.
- **Env hooks** `RYZE_REVEAL` (force reveal) and `RYZE_VCARD` (seed a virtual card) exist for demo/screenshot capture and bypass normal flows.

Relevant source files (absolute paths):
- `/Users/eleviacom/raiffaiesen/ryze-ios/Ryze/Bank.swift`
- `/Users/eleviacom/raiffaiesen/ryze-ios/Ryze/AppViews.swift`
- `/Users/eleviacom/raiffaiesen/ryze-ios/Ryze/Flows.swift`

# Grow — Savings, Round-ups & Analytics

## Overview

The **Grow** area (internally named `GrowView`, surfaced to the user as the screen titled **"Savings"** / **"Kursime"**) is Ryze's savings-and-money-growth surface. It bundles three concerns:

1. **Savings goals** — user-created targets (`Goal`) the user funds incrementally, with a per-goal **round-up** toggle.
2. **Round-ups on spending** — a per-goal flag that *declares* spare-change auto-saving; see the explicit stub note in §6.
3. **Spending analytics** — the `AnalyticsView` chart screen plus the Home-screen this-week-spend and savings tiles.

Grow has no dedicated tab. It is reached from **Home** via the savings-goal bento tile (`HomeView.HSheet.grow`), which presents `GrowView` as a sheet. Analytics is reached from the Home top bar chart button and from tapping the balance/spend tiles. All money in this domain is mock data held in `BankModel` (`Bank.swift`), persisted locally via `SecureStore` — there is no backend. The file comment states: *"Banking domain (behind a mock service; real BFF/microservices slot in later)"* (`Bank.swift:3`).

Currency formatting uses `money(_:_:)` (`Bank.swift:13`): EUR renders as `€<n>` with 2 fraction digits; everything else renders as `<n> L` (Albanian Lek) with 0 fraction digits.

---

## 1. Data Model

### 1.1 `Goal` (`Bank.swift:10`)

A savings goal. `Identifiable, Codable`.

| Field | Type | Mutability | Meaning |
|---|---|---|---|
| `id` | `String` | `let` | Stable identifier. Seed goals use slugs (`"phone"`, `"travel"`); user-created goals use `UUID().uuidString`. |
| `name` | `String` | `let` | Display name. |
| `icon` | `String` | `let` | SF Symbol name shown in the ring and rows. |
| `target` | `Double` | `let` | Target amount (ALL). Never edited after creation. |
| `saved` | `Double` | `var` | Amount saved so far (ALL). Increased by `fundGoal`. |
| `roundup` | `Bool` | `var` | Whether round-ups are declared on for this goal. |

**Seed goals** (`Bank.swift:57`–`60`):

| id | name | icon | target | saved | roundup | progress |
|---|---|---|---|---|---|---|
| `phone` | New phone | `iphone` | 60000 | 18500 | `true` | ~30.8% |
| `travel` | Interrail trip | `airplane` | 120000 | 24000 | `false` | 20% |

### 1.2 `SpendCat` (`Bank.swift:11`)

A spending category for analytics. `Identifiable` only (not `Codable`, not persisted — it is a constant).

| Field | Type | Meaning |
|---|---|---|
| `id` | `String` | Identifier (`"c1"`…`"c4"`). |
| `name` | `String` | Category label. |
| `icon` | `String` | SF Symbol. |
| `amount` | `Double` | Spend in this category (ALL). |
| `color` | `Color` | Bar/icon tint. |

**Categories** are a hard-coded constant `let categories` (`Bank.swift:61`–`66`) — they are **static mock data**, not derived from `transactions`:

| id | name | icon | amount | color (hex) |
|---|---|---|---|---|
| `c1` | Eating out | `fork.knife` | 6400 | `0xFF6F47` |
| `c2` | Groceries | `cart.fill` | 5200 | `0x2FE3B6` |
| `c3` | Entertainment | `film.fill` | 3100 | `0x8B5CFF` |
| `c4` | Transport | `bus.fill` | 1800 | `0x46A8FF` |

### 1.3 `Txn` (`Bank.swift:5`)

Transactions feed the analytics flow/merchant aggregates and the Home spend sparkline.

| Field | Type | Meaning |
|---|---|---|
| `id` | `UUID` | Auto-assigned. |
| `merchant` | `String` | Merchant/counterparty name. |
| `category` | `String` | Free-text category label. |
| `icon` | `String` | SF Symbol. |
| `amount` | `Double` | Signed; `> 0` income, `< 0` spend. |
| `currency` | `String` | `"ALL"` on all seeds. |
| `day` | `String` | Human label (`"Today"`, `"Yesterday"`, `"Mon"`). Not a real date. |

Seed transactions are listed at `Bank.swift:31`–`39`. Note `category` strings on transactions (e.g. `"Eating out"`, `"Groceries"`, `"Entertainment"`) overlap with `SpendCat.name` values but are **never joined** — the category breakdown chart uses only the static `categories` constant.

### 1.4 Derived `BankModel` values used by Grow/Analytics

| Property | Definition | Used by |
|---|---|---|
| `savedTotal` | `goals.reduce(0) { $0 + $1.saved }` (`Bank.swift:69`) | Grow "TOTAL SAVED" hero. |
| `totalALL` | balance of the `ALL` account (`Bank.swift:68`) | Home balance, fund affordability is *not* enforced against it (see §4.3). |
| `monthIncome` | sum of all `amount > 0` transactions (`Bank.swift:103`) | Analytics "Money in". |
| `monthSpend` | sum of `abs(amount)` over `amount < 0` transactions (`Bank.swift:104`) | Analytics "Money out", net flow, card spend. |
| `cardSpent` | `monthSpend` (`Bank.swift:137`) | Card spend tiles. |

---

## 2. Screen Map

| Screen / sheet | Type | Title (EN / SQ) | Entry point |
|---|---|---|---|
| `GrowView` | `NavigationStack` in a sheet | Savings / Kursime (large) | Home savings-goal tile → `HSheet.grow` |
| `GoalDetailView` | pushed view (`navigationDestination`) | goal name, fallback Goal / Synim (inline) | tap a goal row in `GrowView` |
| `AddGoalSheet` | sheet | New goal / Synim i ri (inline) | "New savings goal" button in `GrowView` |
| `AmountSheet(mode: .fund)` | `.medium` detent sheet | Add to goal / Shto te synimi | "Add money" in `GoalDetailView`, or `GrowSheet.fund` |
| `ExchangeView` | sheet | Exchange / Këmbe (inline) | "Convert currency" in `GrowView` |
| `AnalyticsView` | `NavigationStack` in a sheet | Analytics / Analitika (inline) | Home chart button / balance tile / spend tile |

Home-screen Grow surfaces (within `HomeView`): the **savings-goal tile** (`goalTile`), the **this-week-spend tile** (`spendTile`), and the **balance tile** sparkline.

---

## 3. GrowView (Savings hub)

Source: `AppViews.swift:531`–`577`. Presented as a sheet from Home. Wrapped in its own `NavigationStack`; navigation title **"Savings" / "Kursime"** with `.large` display mode. Background bar tinted `Brand.bg`.

### 3.1 Layout (top to bottom)

1. **TOTAL SAVED hero** — a gold `FeaturedCard`:
   - Eyebrow `TOTAL SAVED` / `TOTAL I KURSYER`.
   - `money(bank.savedTotal)` at 40pt bold, with `.numericText()` content transition animated on `savedTotal` change (snappy).
   - Subtitle `Across <n> goals` / `Në <n> synime` where `<n>` is `bank.goals.count`.
   - Seed total: 18500 + 24000 = **42,500 L** across 2 goals.

2. **"New savings goal" row** (`AppCard` button) — icon `plus`, title `New savings goal` / `Synim i ri kursimi`, subtitle `Save toward something you want` / `Kurse për diçka që dëshiron`, chevron. Opens `GrowSheet.newGoal` → `AddGoalSheet`.

3. **"Your goals" eyebrow** — rendered only `if !bank.goals.isEmpty`.

4. **Goal rows** — `ForEach(bank.goals)` each a `NavigationLink(value: g.id)` wrapping `goalRow(g)`, pushing `GoalDetailView(goalId:)`.

5. **"Convert currency" row** (`AppCard` button) — mint icon `arrow.left.arrow.right`, title `Convert currency` / `Këmbe valutë`, subtitle `Move between ALL and EUR` / `Lëviz mes ALL dhe EUR`. Opens `GrowSheet.exchange` → `ExchangeView`. (Documented here as part of the Grow screen; FX conversion mechanics covered briefly in §7.)

### 3.2 `goalRow(_:)` (`AppViews.swift:565`)

Per-goal card:
- `Ring(v: g.saved / g.target, size: 54)` overlaid with the goal's SF Symbol icon (yellow). `Ring` (`Flows.swift`/`AppViews.swift:35`) clamps the trim to `max(0.02, min(1, v))`, so a 0%-saved goal still shows a sliver and an over-target goal caps at full.
- Name (16pt semibold).
- `<saved> of <target>` / `<saved> nga <target>`.
- **Round-ups badge**, shown only `if g.roundup`: icon `arrow.triangle.2.circlepath` + `Round-ups on` / `Rrumbullakimi aktiv`, colored `Brand.good`.
- Right column: integer percent `Int(g.saved / g.target * 100)%` (15pt bold) and a chevron.

### 3.3 Sheets owned by `GrowView` (`GrowSheet` enum, `AppViews.swift:534`)

| Case | id | Presents | Detent |
|---|---|---|---|
| `.fund(String)` | `"fund-<gid>"` | `AmountSheet(mode: .fund, goalName:)` → `bank.fundGoal(gid, amt)` | `.medium` |
| `.exchange` | `"exchange"` | `ExchangeView()` | default |
| `.newGoal` | `"new"` | `AddGoalSheet()` | default |

Note: `.fund` is defined in the enum and wired in the sheet switch, but **no control in `GrowView`'s body invokes `growSheet = .fund(...)`**. In practice funding is reached via `GoalDetailView` (which presents its own fund sheet). The `.fund` case here is effectively dead/reserve wiring — flag as unused.

### 3.4 States

- **No goals**: `savedTotal` shows `0 L`, "Across 0 goals", the "Your goals" eyebrow and all goal rows are omitted. The "New savings goal" and "Convert currency" rows always render.
- **Goals present**: as above.

---

## 4. GoalDetailView (vault screen)

Source: `AppViews.swift:358`–`386`. Pushed onto `GrowView`'s nav stack. Takes a `goalId: String`; resolves the live goal each render via `goal: Goal? { bank.goals.first { $0.id == goalId } }`.

### 4.1 Layout when goal exists (`AppViews.swift:367`–`377`)

1. **Progress ring** — `Ring(v: g.saved / g.target, size: 150)` with centered overlay: integer percent `Int(g.saved / g.target * 100)%` (34pt rounded bold) and the goal icon (22pt yellow).
2. **Goal name** (22pt bold).
3. `<saved> of <target>` / `<saved> nga <target>` (15pt mute).
4. **Remaining / reached line**:
   - If `g.saved < g.target`: `<target − saved> to go` / `<...> mbeten` (yellow).
   - Else: a `checkmark.seal.fill` (`Brand.good`) + `Goal reached!` / `Synimi u arrit!`.
5. **"Add money" primary button** (`Add money` / `Shto para`) — sets `showFund = true`.
6. **Round-ups card** — icon `arrow.triangle.2.circlepath` (size 40), title `Round-ups` / `Rrumbullakimet`, subtitle `Save spare change automatically` / `Kurse kusurin automatikisht`, trailing `Toggle` bound via `Binding(get: { goal?.roundup ?? false }, set: { bank.setRoundup(goalId, $0) })`, tinted `Brand.yellow`. Toggling calls `setRoundup` (§6).
7. **"Delete goal" row** — `trash.fill` (`Brand.danger`) + `Delete goal` / `Fshi synimin`. Calls `bank.deleteGoal(goalId)` then `dismiss()`.

### 4.2 Fund sheet presentation (`AppViews.swift:384`)

`.sheet(isPresented: $showFund)` presents:
```
AmountSheet(mode: .fund, goalName: goal?.name) { amt, _ in bank.fundGoal(goalId, amt) }
  .presentationDetents([.medium])
```
On confirm, `fundGoal` runs (§4.3) and the sheet dismisses; the ring, percent, and remaining line re-render from the mutated `saved`.

### 4.3 `fundGoal(_:_:)` (`Bank.swift:96`–`101`)

```
guard let gi = goals.firstIndex(where: { $0.id == id }) else { return }
goals[gi].saved += amount
if let i = allIndex() { accounts[i].balance -= amount }
game?.realAction("Saved \(money(amount)) toward \(goals[gi].name)", missionId: "m-goal", xp: 50, coins: 25)
```

Behavior and edge cases:
- Adds `amount` to the goal's `saved` and **subtracts the same amount from the ALL account balance**.
- **No funds check.** `AmountSheet` only requires `amount > 0` (`AppViews.swift:99`); there is no comparison to `totalALL`. Funding more than the balance drives the ALL balance negative.
- **No target clamp.** `saved` can exceed `target`; the detail ring and rows clamp visually (via `Ring` and `min(1, …)` in tiles) but the stored value and "Goal reached!" branch reflect the over-fund.
- **Reward:** every funding fires mission `m-goal`, **+50 XP / +25 coins** via `game.realAction`, producing a toast.

### 4.4 Goal-closed state (`AppViews.swift:378`–`380`)

If the goal no longer exists (deleted while the detail view is on screen, or an unknown id), the body renders a single `AppCard`: `This goal was closed.` / `Ky synim u mbyll.` The navigation title falls back to `Goal` / `Synim`.

---

## 5. AddGoalSheet (new savings goal)

Source: `AppViews.swift:389`–`420`. Sheet with `NavigationStack`, inline title **"New goal" / "Synim i ri"**, top-leading `xmark` dismiss button.

### 5.1 Fields & state

| State | Initial | Purpose |
|---|---|---|
| `name` | `""` | Goal name. |
| `target` | `""` | Target amount string; `tgt = Double(target) ?? 0`. |
| `icon` | `"target"` | Selected SF Symbol. |
| `roundup` | `true` | Round-up default ON. |

`icons` palette (`AppViews.swift:397`): `target`, `iphone`, `airplane`, `car.fill`, `house.fill`, `gift.fill`, `graduationcap.fill`, `gamecontroller.fill`, `camera.fill`, `heart.fill`, `bag.fill`, `laptopcomputer`.

### 5.2 Layout

1. **Goal name** field (`RyzeField`) — placeholder `New phone, trip to Italy...` / `Telefon i ri, udhëtim...`.
2. **Target amount** card — `Target amount` / `Shuma e synuar`, a numeric-pad `TextField("0")` (36pt rounded) with trailing `L`.
3. **"Pick an icon" eyebrow** + a 6-column `LazyVGrid` of icon buttons (46×46). Selected icon fills gold with black glyph; others use `Brand.surface` with hairline border.
4. **Round-up card** — icon `arrow.triangle.2.circlepath`, title `Round up spare change` / `Rrumbullakos kusurin`, subtitle `Auto-save change from card spending` / `Kurse automatikisht kusurin nga karta`, trailing `Toggle` bound to `roundup`, tinted yellow.
5. **"Create goal" primary button** — `Create goal` / `Krijo synimin`.

### 5.3 Validation & creation

- Enabled state: `ok = !name.trimmingCharacters(in:.whitespaces).isEmpty && tgt > 0` (`AppViews.swift:399`). Blank/whitespace name or non-positive target disables creation.
- On tap: `bank.addGoal(name: <trimmed name>, target: tgt, icon: icon, roundup: roundup)` then `dismiss()`.

### 5.4 `addGoal(...)` (`Bank.swift:125`–`128`)

```
goals.append(Goal(id: UUID().uuidString, name: name, icon: icon, target: target, saved: 0, roundup: roundup))
game?.realAction("Started goal: \(name)", missionId: "m-goal", xp: 50, coins: 20)
```
- New goal starts at `saved: 0`. Appended to the **end** of `goals`.
- **Reward:** mission `m-goal`, **+50 XP / +20 coins** (note: a different coin value, 20, than the +25 of `fundGoal`).

---

## 6. Round-ups (spare-change auto-save)

Round-ups are surfaced in three places: the `AddGoalSheet` toggle (`roundup` default ON), the `GoalDetailView` round-ups card toggle, and the `goalRow` "Round-ups on" badge.

State is the single `Goal.roundup: Bool`. The only mutator is:

```
func setRoundup(_ id: String, _ on: Bool) {
    if let i = goals.firstIndex(where: { $0.id == id }) { goals[i].roundup = on }
}   // Bank.swift:129
```

**Critical accuracy note — round-ups are a stub.** There is **no spare-change computation anywhere in these files.** No code path inspects a spending `Txn` and routes the rounded-up remainder into a goal; nothing calls `fundGoal` automatically. Spending (`send`, `transferOut`, card spend) does not trigger any round-up. The toggle only persists the boolean and renders the "Round-ups on" badge. The copy ("Save spare change automatically", "Auto-save change from card spending") describes intended behavior that is **not implemented** — treat as a placeholder/declared-intent flag.

---

## 7. ExchangeView (Convert currency)

Reachable from `GrowView`'s "Convert currency" row (and elsewhere). Source: `Flows.swift:73`–`118`. Inline title **"Exchange" / "Këmbe"**. Included here because it is part of the Grow screen; full spec belongs to the money-movement domain.

- Direction toggle `toEUR` (default `true`), flipped by a gold circular `arrow.up.arrow.down` button (snappy).
- `fxRate = 98.5` ALL per 1 EUR (`Bank.swift:102`), labeled a "prototype rate". Displayed as `1 EUR = 98.5 L`.
- From/To rows (`exchangeRow`): the **From** row has a decimal-pad input; the **To** row shows the computed `converted` (`amt / fxRate` to EUR, `amt * fxRate` to ALL) with a numeric content transition.
- Validity `ok = amt > 0 && amt <= srcBalance`. CTA reads `Exchange` / `Këmbe`, switching to `Not enough funds` / `Fonde të pamjaftueshme` when `amt > srcBalance`.
- On confirm: `bank.exchange(toEUR:amount:)` (`Bank.swift:105`–`119`) debits the source account, credits the destination, inserts an `Exchange` `Txn`, and fires `game.realAction` with `missionId: nil`, **+15 XP / +5 coins**.

---

## 8. AnalyticsView (spending analytics)

Source: `Flows.swift:10`–`70`. Presented as a sheet (`NavigationStack`), inline title **"Analytics" / "Analitika"**, top-trailing `Done` / `U krye` button. Entered from Home's top-bar chart button, the balance tile tap, and the spend tile tap (all set `homeSheet = .analytics`).

### 8.1 Computed inputs

| Var | Definition |
|---|---|
| `maxCat` | `bank.categories.map(\.amount).max() ?? 1` — scales the category bars. |
| `net` | `bank.monthIncome - bank.monthSpend`. |
| `topMerchants` | Aggregates all `amount < 0` transactions by `merchant`, summing `abs(amount)`, carries each merchant's icon, sorts descending by total, takes the top **4**. (`Flows.swift:16`–`23`) |

### 8.2 Sections (top to bottom)

1. **"This month" card** (`AppCard`, eyebrow `This month` / `Këtë muaj`):
   - Two `flowStat` tiles side by side: **Money in** / **Hyrje** = `monthIncome` (`Brand.good`, icon `arrow.down.left`) and **Money out** / **Dalje** = `monthSpend` (`Brand.danger`, icon `arrow.up.right`). Each value is 20pt rounded bold, shrinks to 0.6 scale on overflow.
   - **Net flow** / **Fluksi neto** row: signed value `+`/`−` + `money(net)`, colored `Brand.good` if `net >= 0` else `Brand.text`.
   - **Two-bar comparison chart** in a `GeometryReader`: an income `Capsule` (`Brand.good`) and a spend `Capsule` (`Brand.danger` at 0.85 opacity), each width = `gx.width * (value / max(income, spend, 1))`, min width 6, height 8.

   With seed data: `monthIncome` = 45000 + 5000 = **50,000 L**; `monthSpend` = 549+250+1000+1840+700 = **4,339 L**; `net` = **+45,661 L**.

2. **"Where it goes" category breakdown** (eyebrow `Where it goes` / `Ku shkojnë paratë`): a `ForEach(bank.categories)` of rows, each with the category icon (its `color`), name, `money(amount)`, and a horizontal progress capsule of width `gx.width * (amount / maxCat)` filled in the category color. **Driven entirely by the static `categories` constant** (see §1.2) — not by live transactions.

3. **"Top merchants"** (eyebrow `Top merchants` / `Tregtarët kryesorë`): up to 4 `topMerchants` rows, each `IconTile(system: m.icon)` + merchant name + `money(m.total)`, hairline dividers between. This section *is* derived from live `transactions`.

   Seed top-4 (spend, descending): Conad 1,840 · Drin Hoxha 1,000 · Kinema Millennium 700 · Spotify 549. (Mulliri Vjetër 250 is excluded by the top-4 cap.)

4. **"Insight" card** (eyebrow `Insight` / `Këshillë`): a `sparkles` tile, label **"Riz"** (`Brand.yellow`), and a **hard-coded** insight string: *"Eating out is your biggest category this month. A weekly cap of 4,000 L would save about 2,400 L."* / *"Ushqimi jashtë është kategoria më e madhe këtë muaj. Një limit javor prej 4,000 L do të kursente rreth 2,400 L."* This is static copy — it does **not** recompute from data (flag as canned/placeholder insight).

### 8.3 States / edge cases

- If no negative transactions exist, `topMerchants` is empty and the section renders an empty card; `monthSpend`/category bars fall back to `max(...,1)` to avoid divide-by-zero.
- The category breakdown is unaffected by any user spending because it reads the constant `categories`.

---

## 9. Home-screen Grow tiles

Source: `HomeView`, `AppViews.swift:128`–`277`.

### 9.1 Savings-goal tile (`goalTile`, `AppViews.swift:235`)

- Bound to `nearestGoal = bank.goals.min { ($0.saved/$0.target) > ($1.saved/$1.target) }` (`AppViews.swift:137`) — i.e. the goal with the **lowest** completion ratio (the `min` selects the smallest "is-greater" ordering, yielding the least-progressed goal). With seed data this is "Interrail trip" (20% < 30.8%).
- Renders only `if let g = nearestGoal`. Shows `Ring(v: g.saved/g.target, size: 38)` + icon, the goal name (1 line), and `<percent>% · <saved>`.
- Tapping the tile opens `HSheet.grow` → `GrowView` (not the goal detail).

### 9.2 This-week-spend tile (`spendTile`, `AppViews.swift:247`)

- Header `This week` / `Këtë javë` + a `chart.bar.fill` glyph.
- A **sparkline** of `weekBars`, then `−<money(weekNet)>`.
- `weekNet = bank.transactions.filter { $0.amount < 0 }.prefix(8).reduce(0){ $0 + $1.amount }` (`AppViews.swift:138`) — a **negative** sum of up to the first 8 spend transactions; displayed with a leading `−` so the value reads as a spend figure. Seed: −(549+250+1000+1840+700) = **−4,339 L** shown as `−4,339 L`.
- Tapping opens `HSheet.analytics` → `AnalyticsView`.

### 9.3 Sparkline (`sparkline`, `AppViews.swift:256`)

Shared bar-chart helper used by the balance tile and spend tile.
- Input `weekBars` (`AppViews.swift:139`): up to 7 absolute spend amounts; **if fewer than 7 exist it pads with a deterministic pseudo-value** `Double((v.count * 137 % 380) + 140)`. The code comment labels this *"ponytail: pad to 7 for the sparkline."* These padded bars are **synthetic filler**, not real spend.
- Bars scale as `height * pow(v/mx, 0.55)`, with an on-appear rise animation (`sparkUp` flips false→true, per-bar staggered spring `0.05 * index` delay).

(The Cards tab has an analogous `cardBars`/`cardSparkline` with a different pad multiplier `151 % 360 + 120`; same synthetic-padding caveat — `AppViews.swift:441`, `523`.)

---

## 10. Persistence

`BankModel` persists a `Snapshot` (`Bank.swift:139`–`168`) via `SecureStore.save(_, "bank")`, encoding **`goals`** among other fields. `categories` is **not** persisted (it is a constant). On `loadState`, goals are restored only `if !s.goals.isEmpty`; a one-time migration moves a legacy `ryze_bank_v1` blob out of cleartext `UserDefaults` into `SecureStore`. When any `RYZE_*` env var is present, state is **not** loaded (demo/screenshot mode). `saveState` is defined here but is invoked by app lifecycle code outside these three files.

---

## 11. Reward summary (Grow actions)

| Action | Method | Mission | XP | Coins |
|---|---|---|---|---|
| Create goal | `addGoal` | `m-goal` | 50 | 20 |
| Fund goal | `fundGoal` | `m-goal` | 50 | 25 |
| Convert currency | `exchange` | none (`nil`) | 15 | 5 |

Deleting a goal (`deleteGoal`) and toggling round-ups (`setRoundup`) award nothing and fire no mission.

---

## 12. Flagged stubs / placeholders / dead wiring

- **Round-ups are non-functional** — `setRoundup` only stores a boolean; no spare-change logic exists, nothing auto-funds goals from spending (§6).
- **Category breakdown is static mock data** — the "Where it goes" chart reads the constant `categories`, never the user's actual transactions (§1.2, §8.2).
- **Analytics "Riz" insight is hard-coded copy** — fixed "4,000 L / 2,400 L" text, not computed (§8.2).
- **Sparklines use synthetic padding** — fewer than 7 real spend rows are padded with deterministic fake bars (§9.3).
- **`GrowSheet.fund` is unused wiring** — defined and switched but never triggered from `GrowView`'s body (§3.3).
- **No funds/target guards on funding** — `fundGoal` can push the ALL balance negative and `saved` past `target` (§4.3).
- **`day` is a label, not a date** — analytics/"this month"/"this week" framing is nominal; there is no real time filtering (all seed `Txn`s are summed regardless of `day`).
- **`exchange` is described as a "prototype rate"** in code; no live FX (§7).

Relevant source files: `/Users/eleviacom/raiffaiesen/ryze-ios/Ryze/Bank.swift`, `/Users/eleviacom/raiffaiesen/ryze-ios/Ryze/Flows.swift`, `/Users/eleviacom/raiffaiesen/ryze-ios/Ryze/AppViews.swift`.

# Gamification — Play · Invite · Belong

## Overview

Ryze's gamification engine is a single observable model, `GameModel` (`ObservableObject`, defined in `ryze-ios/Ryze/Game.swift`), that holds all play, invite, and belong state for the signed-in user. It is the authoritative source of XP, RyzePoints (`coins`), level, tier, streak, missions, badges, the squad goal, and referral state. The UI surfaces it primarily through the **Rewards** tab (`RewardsHub`, `Sections.swift`) plus the **Home** tab `levelTile` and the **Profile** sheet (`Sections.swift`), with shared row/toast components in `AppViews.swift`.

The Rewards tab self-describes as the "gamified season, Play · Invite · Belong" hub. Section comments in `RewardsHub` explicitly tag each block by pillar:

| Pillar | Mechanics (per code comments / placement) |
| --- | --- |
| **Play** | Daily streak / check-in, quests (missions), level/tier progression |
| **Invite** | Invite & earn (referral code), squad add-member action |
| **Belong** | Squad goal, badges, tier perks |

> Note on naming: in-code the spendable currency field is `coins`, but every user-facing string calls it **RyzePoints** / "points" / "pikë" (the mission rows are the one exception — `MissionRowView` labels mission rewards "coins"/"monedha"). This chapter treats `coins` = RyzePoints. XP is a separate, non-spendable progression number (`xp`).

---

## Data model

### `GameModel` published state

| Field | Type | Initial value | Meaning |
| --- | --- | --- | --- |
| `onboarded` | `Bool` | `false` | Onboarding complete (gates main app) |
| `kycVerified` | `Bool` | `false` | Identity verification done |
| `name` | `String` | `"Friend"` | Display name |
| `xp` | `Int` | `0` | Lifetime XP; drives level/tier |
| `coins` | `Int` | `120` | RyzePoints balance (spendable) |
| `streak` | `Int` | `0` | Consecutive daily check-in count |
| `lastCheckIn` | `String?` | `nil` | Last check-in date (`yyyy-MM-dd`) |
| `savedTotal` | `Int` | `0` | Cumulative save progress (drives `b-saver` badge) |
| `invites` | `Int` | `0` | Successful referrals count |
| `redeemed` | `Set<String>` | `[]` | Reward IDs already redeemed |
| `missions` | `[Mission]` | `seedMissions` | Active quests |
| `badges` | `[Badge]` | `seedBadges` | Badge set |
| `squad` | `Squad` | `seedSquad` | Squad goal state |
| `aiMission` | `Mission?` | `nil` | Single AI-generated mission slot |
| `toast` | `Toast?` | `nil` | Transient reward banner |
| `avatarData` | `Data?` | `nil` | Profile photo |
| `plan` | `String` | `"spark"` | Plan tier id (see Plans chapter) |
| `celebrate` | `Int` | `0` | Monotonic counter triggering confetti + haptics |
| `referralCode` | `let String` | `"RYZE-\(Int.random(in: 1000...9999))"` | Per-session referral code |

`referralCode` is generated once at init via `Int.random(in: 1000...9999)`; it is **not** persisted in `Snapshot`, so it changes on each cold launch. This is a prototype simplification.

### `Mission`

```swift
struct Mission: Identifiable, Codable {
    let id, title, desc, icon: String
    let xp, coins: Int; let category: String
    var progress: Int; let target: Int; var claimed: Bool; var aiGenerated: Bool = false
}
```

| Field | Type | Role |
| --- | --- | --- |
| `id` | `String` | Stable key (e.g. `"ob-verify"`, `"ai"`) |
| `title` / `desc` | `String` | Copy shown in `MissionRowView` |
| `icon` | `String` | SF Symbol; overridden to `"sparkles"` when `aiGenerated` |
| `xp` | `Int` | Flat XP on claim |
| `coins` | `Int` | Base RyzePoints (multiplied for `daily`) |
| `category` | `String` | One of `starter`, `daily`, `weekly`, `social` |
| `progress` / `target` | `Int` | Completion counter |
| `claimed` | `Bool` | Reward taken |
| `aiGenerated` | `Bool` | Marks the AI quest |

### `Reward`, `Badge`, `LeaderRow`, `SquadMember`, `Squad`, `Toast`, `Tier`, `LevelInfo`

| Type | Fields |
| --- | --- |
| `Reward` | `id, title, brand, icon: String`; `cost: Int`; `tierMin: Int = 0` |
| `Badge` | `id, title, icon, desc: String`; `earned: Bool` (Codable) |
| `LeaderRow` | `id, name: String`; `xp: Int`; `you: Bool = false` |
| `SquadMember` | `id, name: String`; `contributed: Int` (Codable) |
| `Squad` | `name, goalTitle: String`; `goal: Int`; `progress: Int`; `rewardCoins: Int`; `members: [SquadMember]` (Codable) |
| `Toast` | `label: String`; `xp, coins: Int` (Equatable) |
| `Tier` | `name: String`; `minLevel: Int`; `color: Color`; `perk: String` |
| `LevelInfo` | `level, intoLevel, needed: Int`; `progress: Double` |

### Persistence

State is serialized to a private `Snapshot` struct and stored encrypted via `SecureStore.save(_, "game")` in `saveState()`. `loadState()` performs a one-time migration off cleartext `UserDefaults` key `ryze_game_v1` into `SecureStore`, then deletes the legacy key. **`referralCode`, `aiMission`, `toast`, and `celebrate` are not in `Snapshot`** and do not persist.

Environment overrides (demo/screenshot harness): if any env key starts with `RYZE_`, `loadState()` is skipped. `RYZE_HOME` seeds a demo user (`name = "Klevi"`, `xp = 320`, `coins = 480`, `streak = 4`, `kycVerified = true`, `onboarded = true`, and `ob-verify` marked claimed). `RYZE_PLAN` overrides the plan id.

---

## Play

### XP, levels, and the level curve

XP is earned and never spent. The per-level XP requirement is:

```swift
func xpForLevel(_ l: Int) -> Int { 80 + l * 60 }
```

`levelInfo(xp)` walks levels, subtracting each level's requirement until the remainder is insufficient, returning the current `level`, XP `intoLevel`, XP `needed` for the current level, and fractional `progress`.

| Level | XP needed for this level | Cumulative XP to reach next level |
| --- | --- | --- |
| 1 | 140 | 140 |
| 2 | 200 | 340 |
| 3 | 260 | 600 |
| 4 | 320 | 920 |
| 5 | 380 | 1,300 |
| 10 | 680 | — |
| 20 | 1,280 | — |

Level 1 starts at 0 XP. Formula: level *L* requires `80 + L*60` XP; cumulative XP to *complete* level *L* is the running sum.

The Rewards "Your season" hero and the Home `levelTile` both render `game.li.level`, a `ProgressBar(value: game.li.progress)`, and the caption `"\(needed - intoLevel) XP to Level \(level+1)"` (Home: "XP to level up").

### Tiers

Tiers are level bands defined by the `TIERS` array. `tierForLevel(level)` returns the highest tier whose `minLevel ≤ level`.

| Index | Tier | `minLevel` | Color | Perk (`perk` string) |
| --- | --- | --- | --- | --- |
| 0 | **Rookie** | 1 | `0x9BA1AD` grey | "1% cashback on card spend" |
| 1 | **Saver** | 5 | `0x34E2B0` mint | "2% cashback + free savings goals" |
| 2 | **Pro** | 10 | `0x4DA3FF` blue | "3% cashback + premium rewards" |
| 3 | **Elite** | 20 | `Brand.yellow` | "5% cashback + Helsinki perks" |

`tierIndex` gates tier-locked rewards (`Reward.tierMin`). The Rewards hero renders a `tierTrack` — a four-node rail with a filled/checkmarked node per passed tier and a ring on the current tier — plus a `tierPill` next to the level. The Profile mini-stats show `game.tier.name` as "Tier".

> The "Helsinki perks" / "Pro" perk strings are static copy; tier perks are descriptive only and not enforced anywhere in code (no cashback engine exists). Cashback is cosmetic.

### Daily streak and the multiplier

`dailyCheckIn()`:
1. If `lastCheckIn == today()` (date `yyyy-MM-dd`), returns immediately (one check-in per day).
2. Otherwise increments `streak`, sets `lastCheckIn = today()`.
3. Computes `mult = streakMultiplier(streak)`.
4. Grants `xp += Int(30 * mult)` and `coins += Int(10 * mult)`.
5. Marks mission `m-checkin` as `progress = 1, claimed = true`.
6. Calls `evalBadges()` then `fire("Day \(streak) streak!", xpG, cG)`.

The multiplier is:

```swift
func streakMultiplier(_ s: Int) -> Double { min(2, 1 + Double(s) * 0.1) }
```

| Streak | Multiplier | Check-in XP (`30×`) | Check-in points (`10×`) |
| --- | --- | --- | --- |
| 1 | 1.1 | 33 | 11 |
| 2 | 1.2 | 36 | 12 |
| 3 | 1.3 | 39 | 13 |
| 5 | 1.5 | 45 | 15 |
| 7 | 1.7 | 51 | 17 |
| 10 | 2.0 | 60 | 20 |
| 11+ | 2.0 (capped) | 60 | 20 |

The multiplier caps at **2.0** (reached at streak 10) and also applies to **`daily`-category mission claims** (see below). There is no streak-decay/reset logic — missing a day does not reset `streak`; it simply doesn't increment until the next distinct calendar day. This is a prototype simplification.

**Streak UI (Rewards block "2"):** an `AppCard` with a `flame.fill` tile showing "`\(streak)`-day streak". If `lastCheckIn == today`, it shows "Checked in today · back tomorrow" and a green `checkmark.seal.fill`; otherwise "Check in daily to grow your multiplier" and a "Check in" `PillButton` calling `game.dailyCheckIn()`.

### Missions / Quests

Eight seed missions (`seedMissions`). The Rewards "Quests · earn points" block shows the first 3 unclaimed (`game.missions.filter { !$0.claimed }.prefix(3)`); "See all" opens `EarnSheet` (defined elsewhere). Each renders via `MissionRowView`.

| `id` | Title | `category` | XP | coins | target | Tied real action |
| --- | --- | --- | --- | --- | --- | --- |
| `ob-verify` | Verify your identity | starter | 120 | 50 | 1 | Account opening (`completeAccount`) |
| `m-topup` | Add your first money | starter | 80 | 30 | 1 | Top-up |
| `m-transfer` | Make your first transfer | starter | 120 | 50 | 1 | Send money |
| `m-split` | Split a bill | starter | 90 | 40 | 1 | Split bill |
| `m-goal` | Start a savings goal | starter | 90 | 30 | 1 | Create savings goal |
| `m-checkin` | Daily check-in | daily | 30 | 10 | 1 | Daily check-in |
| `m-roundup` | Round-up 5 days | weekly | 130 | 50 | 5 | Round-up saving (5×) |
| `s-invite` | Invite a friend | social | 200 | 100 | 1 | Referral |

`desc` strings: `ob-verify` "Open your account", `m-topup` "Top up your account", `m-transfer` "Send money to a friend", `m-split` "Share a cost with friends", `m-goal` "Save toward something", `m-checkin` "Keep your streak alive", `m-roundup` "Save your spare change", `s-invite` "You both earn 200 coins".

**Mission row behavior (`MissionRowView`, `AppViews.swift`):**

| State | Right control |
| --- | --- |
| `claimed` | "Done" + `checkmark.seal.fill` |
| `progress ≥ target` (not claimed) | "Claim" `PillButton` → `game.claim(id)` |
| `progress < target` | If `target > 1`: "+1" soft button → `game.progress(id, by: 1)`. If `target == 1`: "Start" soft button → `game.progress(id, by: target)` (completes it). |

When `target > 1` and not claimed, the row shows a `Bar` and "`progress`/`target`". The icon is `sparkles` when `aiGenerated`, else `m.icon`. Reward labels render "+\(xp) XP" (green) and "+\(coins) coins" (yellow).

**Claiming (`claim(id)`):**
1. Resolves the mission from `missions` or the `aiMission` slot.
2. Guards: must exist, not already `claimed`, and `progress ≥ target`.
3. Multiplier: `mult = category == "daily" ? streakMultiplier(streak) : 1`.
4. Awards `xp += mission.xp` (flat) and `coins += Int(mission.coins * mult)`.
5. Marks claimed (in `missions` and/or `aiMission`).
6. `evalBadges()`, then `fire(mission.title, mission.xp, c)`.

Only the **coins** portion is multiplied, and only for `daily` missions; XP is always flat.

**Progressing (`progress(id, by: 1)`):** clamps `progress` to `target`. Special case: progressing `w-save` adds `by` to `savedTotal` — but **no mission with id `w-save` exists in `seedMissions`**, so this branch is currently dead. `savedTotal` is otherwise only advanced via `m-roundup`-style flows and the `b-saver` badge depends on it; flag as a likely mismatch / leftover (the savings mission id is `m-goal`/`m-roundup`, not `w-save`).

**Mapping missions to real money actions (`realAction` / `completeAccount`):** real banking operations call into the model to satisfy missions:

- `completeAccount(name:)` — sets `name`, marks `ob-verify` complete+claimed, `xp += 120`, `coins += 50`, `kycVerified = true`, `evalBadges()`, toasts "Account opened!", animates `onboarded = true`.
- `realAction(label, missionId:, xp:, coins:)` — generic hook: adds flat `xp`/`coins`, and if a `missionId` is supplied and that mission isn't claimed, advances its `progress` by 1 and auto-marks `claimed` when `progress ≥ target`; then `evalBadges()` + toast. This is how top-ups/transfers/splits/goals (defined in the banking layer) award their starter missions.

### AI-generated quest (`generateAi`)

A single `aiMission` slot, populated by a deterministic rule chain (not an actual LLM call — it is a local heuristic; flag as a mock "AI" generator):

```
if aiMission != nil: return        // only one at a time
if streak < 3      → "Start a 3-day streak"        xp 60,  coins 25, category daily,  icon sparkles
else if invites < 3 → "Invite one more friend"     xp 120, coins 60, category social
else               → "Save your way to level N+1"  xp 90,  coins 35, category daily
```

All three use `id = "ai"`, `target = 1`, `progress = 0`, `aiGenerated = true`. The third variant interpolates `li.level + 1` into the title and reads "Move €10 into a goal". `claim`/`progress` both special-case the `aiMission` slot. (`generateAi()` is defined and reachable but not invoked from any view in these three files — flag as a wired-but-unsurfaced mechanic in this slice.)

---

## Invite

### Referral code & invite-to-earn

The referral code (`RYZE-NNNN`) appears in two places in `RewardsHub`:

1. **"Invite & earn" block (Belong/Invite):** an `AppCard` with a pink `gift.fill` tile, the `referralCode`, the line "You both get 200 points", and a `ShareLink` sharing the string: `"Join me on Ryze, use code \(referralCode) and we both get 200 points."`
2. **Profile sheet "Rewards & sharing":** a `ShareLink` row "Invite friends" / "Earn 2,000 points or more" with the same share string.

> Inconsistency to flag: the share line and "Invite & earn" card say **200 points**, the Profile invite row advertises **"2,000 points or more"**, the `s-invite` mission grants **100 coins**, and `simulateReferral()` actually grants **200 XP + 100 coins**. These figures are not unified.

### `simulateReferral()` (the "friend joined" event)

Triggered by the squad **add-member ("+")** button (see Belong). One call:
1. `invites += 1`
2. `squad.progress = min(squad.goal, squad.progress + 1)`
3. Increments the "You" member's `contributed` (note: seed member is named `"You"`, matching this lookup).
4. Forces `s-invite` mission to `progress = target` (claimable).
5. `xp += 200`, `coins += 100`.
6. `evalBadges()`, toast "Friend joined Ryze!" (+200 XP, +100 points).

This is the only path that increments `invites`, and it is a simulated/demo event (no real invite acceptance). Flag as a mock.

### QR identity / pay code

The Profile avatar's `@handle` and the `QRSheet` render a QR encoding `ryze://pay/\(referralCode)`, labeled "Scan to pay me or add me on Ryze". This doubles the referral code as a pay/add handle. The QR is generated locally via Core Image (`qrImage`, correction level "M"); it is display-only.

---

## Belong

### Squad goal

A single shared `Squad` (`seedSquad`):

| Field | Seed value |
| --- | --- |
| `name` | "Tirana Crew" |
| `goalTitle` | "Invite 10 friends together" |
| `goal` | 10 |
| `progress` | 4 |
| `rewardCoins` | 500 |
| `members` | You (contributed 1), Elsa (2), Drin (1) |

**Squad UI (Rewards block "6"):** name + goal title, a `progress/goal` counter in yellow, a `ProgressBar(value: progress / max(1, goal))`, an overlapping row of member `Avatar`s, and a circular "+" button calling `game.simulateReferral()` — i.e., adding a squad member is modeled as a referral. The `rewardCoins` (500) is stored but **never paid out** in code (no logic reads it); flag as a defined-but-unwired reward. Squad completion only feeds the `b-squad` badge.

### Badges

Six seed badges (`seedBadges`), evaluated by `evalBadges()` (called after every claim, check-in, referral, account completion). Badges are sticky: once `earned`, never cleared.

| `id` | Title | Icon | Description | Earn condition (`evalBadges`) |
| --- | --- | --- | --- | --- |
| `b-first-invite` | Connector | `person.2.fill` | "Invited your first friend" | `invites >= 1` |
| `b-streak7` | On Fire | `flame.fill` | "7-day streak" | `streak >= 7` |
| `b-level10` | Pro | `trophy.fill` | "Reached level 10" | `level >= 10` |
| `b-onboard` | All Set | `checkmark.seal.fill` | "Finished onboarding" | `ob-verify` claimed |
| `b-squad` | Team Player | `person.3.fill` | "Completed a squad goal" | `squad.progress >= squad.goal` |
| `b-saver` | Stacker | `banknote.fill` | "Saved €100 total" | `savedTotal >= 100` |

`level` here is `li.level` (derived from XP). Badges award no XP or points — they are status only.

**Badge UI (Rewards block "8"):** a 2-column `LazyVGrid`. Earned badges show the colored icon in a yellow-tinted circle at full opacity; unearned show a `lock.fill` glyph, faint coloring, and `0.55` opacity. Each cell shows `title` and `desc`.

### Tier perks as belonging

The tier system (Play section) doubles as the belonging ladder: the `tierTrack` rail visualizes Rookie→Saver→Pro→Elite progression, and tier-locked rewards (`tierMin > tierIndex`) display a lock with the required `TIERS[tierMin].name` on the coupon. The single redeemable in-tab perk that is itself a reward is `r-cashback` ("+1% cashback boost", `tierMin: 1`). Perk enforcement is cosmetic (see Tiers note).

---

## How RyzePoints are earned (summary)

Redemption/spending is covered in the Points Store chapter; the **earning** surfaces in this domain are:

| Source | XP | Points (coins) | Method |
| --- | --- | --- | --- |
| Daily check-in | `30×mult` | `10×mult` | `dailyCheckIn()` |
| Claim `daily` mission | flat `xp` | `coins×streakMult` | `claim()` |
| Claim non-`daily` mission | flat `xp` | flat `coins` | `claim()` |
| Account opening (`ob-verify`) | 120 | 50 | `completeAccount()` |
| Real banking action | param `xp` | param `coins` | `realAction()` |
| Referral / squad add | 200 | 100 | `simulateReferral()` |
| Plan change | 0 | 0 | `setPlan()` (toast only) |

Starting balance is `coins = 120`, `xp = 0`. Redeeming a reward subtracts `r.cost` from `coins` and is the only negative-points path (`redeem()`), surfaced as a negative `Toast.coins`.

---

## Feedback system (toasts + celebration)

Every reward event calls `fire(label, xp, coins)`, which sets a `Toast` and increments `celebrate`. After 2.2s the toast self-clears (only if `celebrate` hasn't advanced again). `MainTabView` renders:
- `CelebrationOverlay(trigger: game.celebrate)` (confetti),
- `ToastBanner(toast:)` sliding from the top — showing the label, "+\(xp) XP" in green when `xp > 0`, and the points delta (yellow when positive, muted when negative) when `coins != 0`,
- `.sensoryFeedback(.success, trigger: game.celebrate)` for haptics.

`notify(label)` is a thin wrapper calling `fire(label, 0, 0)` used for non-reward notices (e.g. screenshot detection); it still triggers the celebration counter and haptic.

---

## States & edge cases

- **Double check-in same day:** blocked by the `lastCheckIn == today()` guard; "Check in" button is replaced by a "Checked in today" state in the UI.
- **Claiming an incomplete mission:** `claim()` guard (`progress >= target`) prevents it; the UI only shows "Claim" once complete.
- **Double claim:** blocked by the `!mission.claimed` guard.
- **Redeem when broke / already owned:** `redeem()` guards `coins >= r.cost` and `!redeemed.contains(id)`; coupon UI shows "Owned"/disabled state accordingly.
- **Streak multiplier ceiling:** hard-capped at 2.0 via `min(2, …)`.
- **AI mission singleton:** `generateAi()` no-ops if `aiMission != nil`; only one AI quest can exist.
- **Env-driven demo state:** any `RYZE_`-prefixed env var disables persistence load; `RYZE_HOME` injects a fully-progressed demo user.
- **`resetDemo()`** (Profile "Log out"): zeroes XP, restores `coins=120`, clears streak/saves/invites/redeemed, re-seeds missions/badges/squad, clears `aiMission`, sets `onboarded=false`, and wipes both `SecureStore` and legacy `UserDefaults` keys for `game` and `bank`.

---

## Flagged placeholders / inconsistencies

- **`w-save` dead branch** in `progress()` — no such mission id exists in seeds; `savedTotal` accrual via that path never fires.
- **`generateAi()` not surfaced** in these three files (defined, reachable, but no view triggers it in this slice).
- **`squad.rewardCoins` (500) unwired** — stored, never paid.
- **Referral reward figures inconsistent**: 200 points (share/card) vs "2,000 points or more" (Profile row) vs 100 coins (`s-invite`) vs 200 XP + 100 coins (`simulateReferral`).
- **`referralCode` not persisted** — regenerates each cold launch.
- **Tier perks cosmetic** — cashback %/"Helsinki perks" strings are descriptive; no enforcement engine.
- **"AI" quest is a local heuristic**, not a model call.
- **`simulateReferral` is a demo event** — no real invite-acceptance pipeline.

# Rewards Store & Redemption

## Overview

The Rewards Store & Redemption domain is Ryze's points-spending economy: a catalogue of partner coupons that users buy with **RyzePoints** (the `coins` currency on `GameModel`), the in-app redemption flow that deducts points and marks an item owned, and the redeemed-coupon presentation screen that issues an activation code plus a scannable QR. The domain is implemented across two files: the data model and spend/redeem logic live in `Game.swift`; every screen, ticket, sheet, and the QR / sensitive-clipboard helpers live in `Sections.swift`.

The store surfaces in three places:
1. **`RewardsHub`** — the gamified season tab, which embeds an inline horizontal category filter and a short preview list of coupon tickets under a "Redeem at stores" header.
2. **`RewardsStoreSheet`** — the full store sheet reached via "See all". (Referenced as the `.redeem` route's destination; not defined in either source file — see [Out of Scope / External References](#out-of-scope--external-references).)
3. **`CouponRedeemedSheet`** — the post-redemption result screen with the QR code and activation code.

All point values, prices, partners, and copy below are taken verbatim from the code.

---

## Data Model

### `Reward`

Defined in `Game.swift`. A plain (non-`Codable`) `Identifiable` struct describing one redeemable catalogue item.

| Field | Type | Default | Meaning |
|---|---|---|---|
| `id` | `String` | — | Stable identifier, e.g. `"r-spotify"`. Used for ownership tracking, QR payload, color/category lookup. |
| `title` | `String` | — | Display title, e.g. `"1 month Spotify"`. |
| `brand` | `String` | — | Partner name shown as subtitle, e.g. `"Spotify"`. |
| `icon` | `String` | — | SF Symbol name for the ticket stub / result hero. |
| `cost` | `Int` | — | Price in RyzePoints. |
| `tierMin` | `Int` | `0` | Minimum tier **index** required to redeem (index into `TIERS`). `0` = available to everyone. |

The currency spent is `GameModel.coins` (an `@Published var coins: Int`, seeded at `120`). Throughout the UI this is labelled "points" / "pikë" / "RyzePoints"; there is no separate points type — `coins` is the points balance.

### The catalogue — `GameModel.rewards`

A `static let` array of ten `Reward` items. This is the complete, exact catalogue:

| # | `id` | `title` | `brand` | `icon` | `cost` (pts) | `tierMin` | Category (derived) |
|---|---|---|---|---|---|---|---|
| 1 | `r-spotify` | 1 month Spotify | Spotify | `music.note` | 300 | 0 | Streaming |
| 2 | `r-coffee` | €5 coffee voucher | Mulliri Vjetër | `cup.and.saucer` | 150 | 0 | Food |
| 3 | `r-cinema` | Cinema ticket | Kinema Millennium | `film` | 250 | 0 | Streaming |
| 4 | `r-cashback` | +1% cashback boost | Ryze | `bolt.fill` | 400 | 1 | Mobile |
| 5 | `r-data` | 5GB mobile data | ONE | `antenna.radiowaves.left.and.right` | 200 | 0 | Mobile |
| 6 | `r-merch` | Ryze hoodie | Ryze | `tshirt` | 800 | 2 | Shopping |
| 7 | `r-glovo` | 20% off Glovo | Glovo | `bag.fill` | 200 | 0 | Food |
| 8 | `r-kfc` | Free KFC box | KFC | `takeoutbag.and.cup.and.straw.fill` | 350 | 0 | Food |
| 9 | `r-game` | 1 month Game Pass | Xbox | `gamecontroller.fill` | 500 | 1 | Streaming |
| 10 | `r-fashion` | 15% off Pull&Bear | Pull&Bear | `tshirt.fill` | 250 | 0 | Shopping |

Notes faithful to code:
- Only `r-cashback` (tierMin 1), `r-merch` (tierMin 2), and `r-game` (tierMin 1) are tier-locked. All other seven items have `tierMin: 0`.
- `+1% cashback boost` and `Ryze hoodie` are first-party rewards (`brand: "Ryze"`), not external partners.
- Prices range from 150 (coffee) to 800 (hoodie) points.

### Ownership / redemption state

| State | Storage | Type | Notes |
|---|---|---|---|
| Points balance | `GameModel.coins` | `Int` | Decremented on redeem; persisted. |
| Redeemed set | `GameModel.redeemed` | `Set<String>` | Set of redeemed `Reward.id`s. Persisted in the `Snapshot`. An item, once redeemed, can never be redeemed again (see `redeem`). |
| Celebration counter | `GameModel.celebrate` | `Int` | Incremented by `fire(...)`; drives confetti / bounce animations. |
| Toast | `GameModel.toast` | `Toast?` | Transient banner with label + xp + coins delta. |

Both `coins` and `redeemed` are part of the persisted `Snapshot` (encoded to `SecureStore` under key `"game"`), so redemptions survive app restarts.

---

## Category Derivation & Color

Rewards are not tagged with a category field; category is computed from `id` by two free functions in `Sections.swift`.

### `rewardCategory(_ id: String) -> String`

| Returned category | Reward ids |
|---|---|
| `"Food"` | `r-coffee`, `r-kfc`, `r-glovo` |
| `"Streaming"` | `r-spotify`, `r-cinema`, `r-game` |
| `"Shopping"` | `r-merch`, `r-fashion` |
| `"Mobile"` | `r-data`, `r-cashback` |
| `"Food"` (default) | any unrecognised id |

This function also decides the redeemed-sheet copy: `inStore == (rewardCategory(reward.id) == "Food")` in `CouponRedeemedSheet`. So **Food** rewards present as a counter QR, everything else as a checkout code.

### `rewardColor(_ id:)` and `RewardsHub.perkColor(_ id:)`

Two identical color maps exist (one global `rewardColor`, one method `perkColor` inside `RewardsHub`). Both map id → `Brand` color:

| id | Color |
|---|---|
| `r-spotify` | `Brand.good` |
| `r-coffee` | `Brand.coral` |
| `r-cinema` | `Brand.violet` |
| `r-cashback` | `Brand.yellow` |
| `r-data` | `Brand.sky` |
| `r-merch` | `Brand.pink` |
| `r-glovo` | `Brand.yellow` |
| `r-kfc` | `Brand.coral` |
| `r-game` | `Brand.violet` |
| `r-fashion` | `Brand.pink` |
| (default) | `Brand.yellow` |

`RewardsHub.couponTicket(_:)` uses `perkColor`; `CouponRedeemedSheet` uses the global `rewardColor`. The maps are duplicated but equal.

---

## Screens & Views

### 1. `RewardsHub` — store entry point

The Rewards tab. Relevant store sub-section is the block labelled **"5) Perks marketplace"**.

**Earn-rate banner** — an `AppCard` reading `"<planLabel> · earn as you spend"` ("fito teksa shpenzon"), with subtitle `currentPlan?.earn ?? "1x RyzePoints · 1 point per 200 L spent"`. This communicates how points are *earned* (1 point per 200 ALL spent at base plan); it is informational only.

**Section header** — `Eyebrow` "Redeem at stores" / "Përdor në dyqane", plus a `seeAll { route = .redeem }` chevron button opening the full store sheet.

**Category filter** — a horizontal `ScrollView` of pill buttons built from `cats`:

| Category | SF Symbol | Active color |
|---|---|---|
| Food | `fork.knife` | `Brand.coral` |
| Streaming | `play.tv.fill` | `Brand.good` |
| Shopping | `bag.fill` | `Brand.pink` |
| Mobile | `antenna.radiowaves.left.and.right` | `Brand.sky` |

Tapping a pill toggles `selCat` (tap the active pill again to clear it, `withAnimation(.snappy)`). The selected category can be pre-set at launch from the `RYZE_CAT` environment variable (demo/screenshot hook).

**Coupon list** — driven by:
```
ForEach(selCat == nil ? Array(GameModel.rewards.prefix(4))
                      : GameModel.rewards.filter { rewardCategory($0.id) == selCat }) { r in couponTicket(r) }
```
- No category selected → first **4** rewards (`r-spotify`, `r-coffee`, `r-cinema`, `r-cashback`).
- Category selected → all rewards whose derived category matches.

Each row is a `CouponTicket` produced by `couponTicket(_:)`, which precomputes:
- `owned = game.redeemed.contains(r.id)`
- `locked = r.tierMin > game.tierIndex`
- `afford = game.coins >= r.cost`
- `tierName = TIERS[r.tierMin].name`
- on redeem tap → `route = .coupon(r.id)` (opens `CouponRedeemedSheet`, **not** an immediate spend).

There is also an unused alternative renderer `perkCard(_:)` in `RewardsHub` that renders the same data as an `AppCard` row with a `PillButton(title: "\(r.cost)")` whose action calls `game.redeem(r.id)` directly (immediate spend, no result sheet). `perkCard` is **dead code** in the current layout — the hub uses `couponTicket`. Flag: two divergent redemption entry points exist; the live one routes through the QR sheet, the dead one spends inline.

### 2. `CouponTicket` — the perforated coupon row

A self-contained view in `Sections.swift` styled as a perforated ticket (a dashed tear line and two notch circles at `stubW = 82`), deliberately *not* a Revolut gradient card (per code comment).

Inputs: `r: Reward`, `color`, `owned`, `locked`, `afford`, `tierName`, `redeem: () -> Void`.

Left stub: gradient fill of `color`, the reward's SF Symbol in white.
Body: `title` (1 line), `brand`, and a points line `"<cost> pts"` ("pikë") with a `star.circle.fill` icon.

Trailing control is exactly one of three mutually-exclusive states:

| Condition | Trailing UI | Interactive |
|---|---|---|
| `owned` | `checkmark.seal.fill` (green) + "Owned" / "E zotëruar" | No |
| `locked` (not owned) | `lock.fill` + `tierName` label | No |
| else | "Redeem" / "Shkëmbe" pill button | Yes, but `.disabled(!afford)` |

The Redeem pill is yellow (`Brand.yellow`) and black text when affordable; greyed (`Brand.elev3` / `Brand.faint`) and disabled when `!afford`. Tapping it invokes the `redeem` closure (in the hub, that opens the coupon sheet). Precedence: owned > locked > redeem — an owned item never shows lock or redeem even if also tier-locked.

### 3. `CouponRedeemedSheet` — redemption result (QR + code)

Presented from `RewardsHub` via the `.coupon(rid)` route after looking the reward up by id (`GameModel.rewards.first(where:)`). Receives `reward: Reward`.

State: `code` (the generated activation code), `copied` (clipboard feedback flag).
Derived: `inStore = rewardCategory(reward.id) == "Food"`.

Layout (top to bottom):
1. Close button (`xmark`) top-right.
2. Hero icon tile — `reward.icon` on a vertical gradient of `rewardColor(reward.id)`, 74×74, corner radius 20.
3. `reward.title` (bold 22) and `reward.brand` (muted).
4. **QR code** generated from payload `"ryze://redeem/\(reward.id)/\(code)"`, 196×196, white background, gold (`Brand.gold`) 2px border, nearest-neighbour interpolation (`.interpolation(.none)`).
5. **Activation code pill** — monospaced, letter-spaced (`tracking(2)`) `code`, with a copy affordance. Tapping copies via `Clip.copySensitive(code)` and flips `copied` to show a green checkmark instead of the doc icon.
6. Instructional caption, conditional on `inStore`:
   - Food → "Show this QR at the counter to claim your reward." / "Trego këtë QR në arkë për të marrë shpërblimin."
   - Others → "Enter this code at checkout to redeem." / "Vendose këtë kod në arkë për ta përdorur."
7. `PrimaryButton` "Done" / "U krye" → dismiss.

**`onAppear` logic (the actual spend):**
```
if code.isEmpty {
    code = Self.gen()
    if !game.redeemed.contains(reward.id) { game.redeem(reward.id) }
}
```
So the points deduction happens when this sheet first appears, guarded so a re-render does not regenerate the code or double-spend. If the item is already in `redeemed`, the sheet still shows a freshly generated code but does not deduct again.

**`CouponRedeemedSheet.gen()`** — activation code generator:
- Alphabet: `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (Crockford-style: no `I`, `O`, `0`, `1`).
- Format: `"RYZE-XXXX-XXXX"` (two random 4-char groups).
- Generated client-side, random, **not validated against any backend** — it is a mock/demo code.

---

## Spend / Redemption Logic (`GameModel`)

### `redeem(_ id: String)`

```
func redeem(_ id: String) {
    guard let r = GameModel.rewards.first(where: { $0.id == id }),
          coins >= r.cost,
          !redeemed.contains(id) else { return }
    coins -= r.cost
    redeemed.insert(id)
    fire("Redeemed \(r.title)", 0, -r.cost)
}
```

Guards (all must pass or it is a no-op):
1. The id resolves to a real `Reward`.
2. `coins >= r.cost` — sufficient balance.
3. `!redeemed.contains(id)` — not already owned.

On success: deducts `r.cost` from `coins`, inserts the id into `redeemed`, and fires a celebration toast `"Redeemed <title>"` with `xp: 0` and `coins: -r.cost` (negative, indicating a spend).

Note: `redeem` does **not** itself check `tierMin`. Tier-locking is enforced only at the UI layer (`CouponTicket` shows a lock and no redeem button when `locked`). The hub never routes to the coupon sheet for a locked item because the lock state replaces the redeem control.

### `fire(...)` — celebration / confetti trigger

```
private func fire(_ label: String, _ xpG: Int, _ coinsG: Int) {
    toast = Toast(label: label, xp: xpG, coins: coinsG)
    celebrate += 1
    let snap = celebrate
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
        if self.celebrate == snap { self.toast = nil }
    }
}
```
- Sets a `Toast` (consumed elsewhere in the app for the banner overlay).
- Increments `celebrate` — the value that drives the confetti/bounce. In `RewardsHub`, the season-hero points star uses `.symbolEffect(.bounce, value: game.celebrate)`, and the `coins` count uses `.contentTransition(.numericText())` + `.animation(.snappy, value: game.coins)` so the balance animates down on redeem.
- The toast auto-dismisses after **2.2 s** unless superseded by a newer `fire` (tracked by `snap`).

The actual confetti overlay view is not in these two files; `celebrate`/`toast` are the signals it observes. (See [Out of Scope](#out-of-scope--external-references).)

---

## QR Generation

`qrImage(_ string: String) -> UIImage?` in `Sections.swift`:
- Uses Core Image `CIFilter.qrCodeGenerator()`.
- `correctionLevel = "M"` (medium error correction).
- Scales the output by 10× (`CGAffineTransform(scaleX: 10, y: 10)`) before rasterising to a `UIImage`.
- Returns `nil` on failure; callers wrap rendering in `if let img = qrImage(...)`.

Two distinct QR payload schemes use this helper:

| Caller | Payload | Purpose |
|---|---|---|
| `CouponRedeemedSheet` | `ryze://redeem/<reward.id>/<code>` | Scanned at the counter / used as the coupon proof. |
| `QRSheet` (profile) | `ryze://pay/<referralCode>` | "Scan to pay me or add me on Ryze" — adjacent feature, not part of the store. |

Both are app-scheme deep links rendered visually only; nothing in these files parses or validates an incoming `ryze://` scan. The redemption QR is therefore a **presentational mock**.

---

## Auto-Expiring Sensitive Clipboard

Codes (and the account IBAN) are copied via `Clip.copySensitive(...)`, used in:
- `CouponRedeemedSheet` — copying the activation `code`.
- `ProfileDetailView` (`.account`) — copying the IBAN.

`Clip` / `copySensitive` is **not defined in either of these two files**. From its call sites and name it is the sensitive-clipboard helper that writes a value with auto-expiry / non-persistence (the standard iOS pattern is `UIPasteboard` items flagged `.expirationDate` and `localOnly`/no universal-clipboard). Its actual implementation, including the exact expiry duration, lives elsewhere in the codebase and must be confirmed there — flagged here as **referenced but external**. The product intent in this domain: a redeemed activation code placed on the clipboard is treated as sensitive and clears itself rather than lingering.

---

## User Flows

### Flow A — Redeem an affordable, unlocked reward (happy path)
1. User opens the Rewards tab (`RewardsHub`).
2. (Optional) Filters by category pill; list updates to matching rewards.
3. On a `CouponTicket` where `!owned && !locked && afford`, taps **Redeem**.
4. `route = .coupon(r.id)` → `CouponRedeemedSheet` presents.
5. `onAppear`: `code = gen()`; since not yet in `redeemed`, `game.redeem(id)` runs → `coins -= cost`, id added to `redeemed`, `fire("Redeemed <title>", 0, -cost)` → toast + `celebrate++` → season-hero star bounces and the balance counts down.
6. Sheet shows the partner hero, the `ryze://redeem/...` QR, the `RYZE-XXXX-XXXX` code, and counter-vs-checkout instructions per category.
7. User may tap the code to copy it (`copySensitive`, green check feedback).
8. User taps **Done** to dismiss. The reward now renders as **Owned** in the ticket list.

### Flow B — Insufficient points
- `afford = coins >= cost` is false → the Redeem pill is greyed and `.disabled(true)`. Tapping does nothing; no sheet, no spend.
- Defensive double-guard: even if a redeem were triggered, `redeem(...)` returns early because `coins < r.cost`.

### Flow C — Tier-locked reward
- `locked = r.tierMin > game.tierIndex` is true → the ticket shows `lock.fill` + the required tier's name (`TIERS[r.tierMin].name`, e.g. "Saver" for tierMin 1, "Pro" for tierMin 2). No Redeem control is rendered, so the user cannot open the coupon sheet for it.

### Flow D — Already owned
- `owned = redeemed.contains(r.id)` → ticket shows the green `checkmark.seal.fill` + "Owned". No redeem control. If the coupon sheet were somehow reached, `redeem` no-ops on the `!redeemed.contains` guard, but a fresh display code is still generated.

### Flow E — Browsing without redeeming
- The "See all" chevron opens `RewardsStoreSheet` (full catalogue). Category pills filter inline within the hub.

---

## States & Edge Cases (summary)

| Case | Behavior |
|---|---|
| Balance exactly equals cost | `afford` true (`>=`); redeem allowed; balance goes to 0. |
| Re-presenting the coupon sheet for an owned item | No second deduction (`!redeemed.contains`), but a new random code is shown — codes are not persisted, so a re-opened reward yields a different display code each time. Flag: codes are not stored anywhere. |
| Tier-locked but affordable | Still locked; UI hides redeem. `redeem` has no tier guard, so the gate is UI-only. |
| Unknown reward id passed to `redeem` | Guard fails, no-op. |
| QR generation failure | `qrImage` returns nil; the `if let` simply omits the QR image (code pill still shown). |
| Toast superseded | A newer `fire` bumps `celebrate`; the older 2.2 s timer sees a changed `snap` and does not clear the new toast. |
| `RYZE_CAT` env set | Hub launches with that category pre-filtered (demo hook). |

---

## Out of Scope / External References

The following are referenced by this domain but **not defined in `Sections.swift` or `Game.swift`**; they are stubs/externals to confirm elsewhere:

- **`RewardsStoreSheet`** — the full "See all" store sheet (the `.redeem` route destination). Not present in these files; its catalogue/layout must be read from its own source. The hub only renders a 4-item preview + inline filter.
- **`Clip` / `Clip.copySensitive(_:)`** — the auto-expiring sensitive-clipboard helper. Referenced; implementation and exact expiry external.
- **Confetti/toast overlay view** — consumes `GameModel.toast` and `GameModel.celebrate`; the visual overlay itself is defined outside these files.
- **`SecureStore`** — encrypted persistence backing `coins`/`redeemed` (via `Snapshot`). Referenced in `Game.swift`, implemented elsewhere.
- **`Brand.*` colors, `AppCard`, `FeaturedCard`, `IconTile`, `PrimaryButton`, `PillButton`, `PressStyle`, `Eyebrow`, `T(_:_:)` localization** — shared design-system primitives, defined elsewhere.
- **`perkCard(_:)`** — present in `RewardsHub` but unused (dead code); it is the only path that calls `game.redeem` directly with no result sheet.

No partner integrations, payment rails, or backend redemption endpoints exist in these files: the entire store is a self-contained, client-side mock. Activation codes and QR payloads are generated locally and are not validated. RyzePoints (`coins`) is the sole currency, persisted with the rest of the game state.

# Riz — AI Money Coach

## Overview

Riz is the in-app AI money assistant for Ryze. It is presented to the user as a chat-based "money copilot" that explains the app, the user's own finances, RyzePoints, and plans. Riz has two response paths: a **live backend path** (`RizService` → Ollama Cloud, optionally fronted by a Cloudflare Worker proxy) and a **built-in offline fallback** (`Riz.reply`) that runs entirely on-device with no network or API key. A hard input-safety guard (`Riz.guardInput`) runs ahead of both paths. Model replies are rendered as native interactive cards (prose, bar charts, progress bars, stat chips, tables) by `RizRichText`.

Riz appears in two surfaces:

1. **Assistant tab** (`AssistantView`) — the full-screen primary experience.
2. **"Ask Riz" sheet** (`RizSheet`, reached from the profile **Help** screen) — referenced via `DetailSheet.riz` but its own implementation file is not in scope for this chapter (see [§9](#9-ask-riz-sheet-out-of-scope-note)).

The feature is explicitly framed in code comments as a prototype: "It is a prototype: point to in-app actions, do not claim to move real money."

---

## 1. Data model

### `RizMessage` (Riz.swift)

A single chat turn.

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | Auto-assigned; conforms to `Identifiable`. |
| `fromUser` | `Bool` | `true` = user bubble, `false` = Riz bubble. |
| `text` | `String` | Raw message text (may contain markdown / `ryze-*` fenced blocks for Riz turns). |

`RizMessage` conforms to `Identifiable, Equatable`.

### `RizBlock` (RizRichText.swift)

The parsed unit a Riz reply is broken into for rendering. Enum cases:

| Case | Associated value | Rendered as |
|---|---|---|
| `text(String)` | prose (supports bold, bullets, headings) | `textBlock` |
| `chart([(String, Double)])` | label/value pairs | horizontal bar chart |
| `progress([(String, Double, Double)])` | (title, saved, total) | progress bars |
| `stats([(String, String)])` | (label, value) pairs | stat chips row |
| `table([[String]])` | rows of cells | bordered table |

### `RizConfig` (RizService.swift)

| Static field | Value (as committed) | Notes |
|---|---|---|
| `endpoint` | `"https://ollama.com/api/chat"` | **Direct mode** is the committed default (not the Worker). |
| `model` | `"gpt-oss:120b"` | Ollama Cloud model. |
| `apiKey` | `RizSecret.ollamaKey` | Reads an embedded key. |
| `isConfigured` | computed: `!endpoint.isEmpty` | Determines whether the live path is attempted at all. |

> **Flag — embedded secret.** `RizSecret.ollamaKey` (`Ryze/RizSecret.swift`) hardcodes a literal Ollama Cloud key (`"d846acdcdeac4a339ab548ef14625cc1.gXfQ11ca7LBxTRBjmvEDgydC"`) directly in the app binary. The `riz-proxy/README.md` and `RizService` comments label this **"Direct mode (no Worker, demo only)"** / "embedded in the app — demo only." The Worker-fronted mode (key off-device) exists in design but the committed config does **not** use it.

---

## 2. Assistant tab (`AssistantView`)

The main Riz experience. State:

| `@State` / property | Initial value | Purpose |
|---|---|---|
| `msgs: [RizMessage]` | `[]`, **unless** env var `RYZE_RIZ` is set, in which case seeded with a demo Q&A pair (see below) | Conversation history. |
| `input: String` | `""` | Composer text. |
| `typing: Bool` | `false` | Drives the typing-dots indicator. |
| `didAsk: Bool` | `false` | One-shot guard for the `RYZE_ASK` auto-send. |
| `lang` (`@AppStorage "ryze_lang"`) | `"en"` | Language toggle (en/sq), drives the `T(...)` copy and the reply-language context line. |

Injected environment objects: `game: GameModel`, `bank: BankModel`.

### Demo seed (`RYZE_RIZ`)
When the process env contains `RYZE_RIZ`, `msgs` is pre-populated with a hardcoded screenshot demo conversation:
- User: `"How am I spending this month?"`
- Riz: `"You've spent 16,500 L this month, mostly on eating out (6,400 L). That's ~20% more than last week. Want me to set a weekly cap so you stay on track?"`

This is a **static mock string** for screenshots, not generated.

### 2.1 Header bar
- `RizOrb(size: 42, glow: false)` (see [§7](#7-rizorb--visual-identity)).
- Title `"Riz"` (bold, 18pt) and a status line: green dot (`Brand.good`) + `T("Online · money copilot", "Online · kopilot parash")`.
- Trailing **new-chat** button (`square.and.pencil`) — shown only when `!msgs.isEmpty`; clears `msgs` to `[]` with animation.
- A 1pt hairline divider beneath the header.

### 2.2 Empty state (`msgs.isEmpty && !typing`)
Centered welcome:
- `RizOrb(size: 72, glow: true)` (pulsing).
- Heading `T("Hi \(game.name), I'm Riz", "Ç'kemi \(game.name), unë jam Riz")` — personalized with the user's name.
- Subhead `T("Your money copilot. Ask about spending, points or plans.", "Kopiloti yt i parave. Pyet për shpenzime, pikë ose plane.")`.
- **Suggested prompt cards** (`caps`), rendered via `capCard` (see [§4](#4-suggested-prompts-caps)).
- A privacy footnote: lock icon + `T("Private · encrypted in transit, only minimal data is shared", "Privat · e enkriptuar gjatë transferimit, ndahen vetëm të dhëna minimale")`.

### 2.3 Conversation state (`else`)
- A `ScrollViewReader`-wrapped `ScrollView` lists `msgs` via `bubble(_:)`.
- When `typing`, a trailing row shows `RizOrb(size: 28)` + `TypingDots()` in a bubble, tagged `.id("typing")`.
- Auto-scroll: `onChange(of: msgs.count)` scrolls to `msgs.last?.id`; `onChange(of: typing)` scrolls to `"typing"` when typing starts. Both animate with `.easeOut`.

### 2.4 Composer (always visible)
- `TextField` bound to `$input` with placeholder `T("Ask Riz anything...", "Pyet Riz çdo gjë...")`.
- Send button: up-arrow on `Brand.gold` circle (48×48), dimmed to `opacity 0.5` while `input` (trimmed) is empty; calls `send(input)`.

### 2.5 Auto-ask on appear (`RYZE_ASK`)
On `.onAppear`, if env var `RYZE_ASK` is present and `!didAsk`, sets `didAsk = true` and calls `send(q)` — used to drive scripted/screenshot flows.

---

## 3. Ask flow (`send` and reply resolution)

`send(_ t: String)` in `AssistantView`:

1. Trim `t` → `q`; **guard**: if empty, return (no-op).
2. Clear `input`.
3. Append a user `RizMessage(fromUser: true, text: q)` (animated `.snappy`).
4. Set `typing = true`.
5. Snapshot `history = msgs` and `ctx = rizContext()` (see [§5](#5-user-context-injection-rizcontext)).
6. In a `Task`: `let live = await RizService.reply(history: history, context: ctx)`.
7. Back on `MainActor`: set `typing = false`; compute `reply = live ?? Riz.reply(stepWhy: nil, text: q)`; append `RizMessage(fromUser: false, text: reply)` (animated).

So the offline `Riz.reply` is used as the fallback whenever the live service returns `nil` (not configured, bad URL, network/HTTP error, or unparseable body).

### 3.1 Live path — `RizService.reply(history:context:)`
Async, returns `String?`.

1. **Guard**: `RizConfig.isConfigured` and a valid `URL`; otherwise return `nil`.
2. Build `URLRequest` (POST, `timeoutInterval: 45`, `Content-Type: application/json`).
3. If `apiKey` non-empty, set `Authorization: Bearer <apiKey>`. (In Worker mode the key is empty and the Worker injects it.)
4. Build messages: a leading `system` message = `systemPrompt(context:)`, then the **last 16** turns of `history` (`history.suffix(16)`), each mapped to `role: "user"/"assistant"`.
5. Body: `{"model": RizConfig.model, "messages": [...], "stream": false, "options": {"temperature": 0.6}}`.
6. Send via `URLSession.shared.data(for:)`.
7. Accept only HTTP `200..<300`; otherwise return `nil`.
8. Parse JSON, trying response shapes in order:
   - `j["message"]["content"]` (Ollama chat shape) → `clean(c)`
   - `j["choices"][0]["message"]["content"]` (OpenAI-style) → `clean(c)`
   - `j["reply"]` → `clean(c)`
   - `j["content"]` → `clean(c)`
   - else `nil`.
9. Any thrown error → `nil` (silent fallback to offline).

#### `clean(_:)`
Trims whitespace/newlines and normalizes typography while **preserving** markdown so `RizRichText` can render it:
- `—` → `, ` · `–` → `-` · `…` → `...` · `--` → `, `.
Markdown control chars (`* - |`) and the ` ```ryze-* ` fences are intentionally kept.

### 3.2 System prompt / persona (`systemPrompt(context:)`)
The persona injected as the `system` message. Verbatim key directives:

- Identity: *"You are Riz, the in-app money assistant for Ryze, a youth banking app by Raiffeisen Bank Albania (ages 18-25)."*
- **STYLE (strict):** very short (1-2 sentences max + at most one visual block); never long paragraphs or stacked charts; warm, upbeat, young; a tasteful emoji is fine; plain commas/hyphens (no long dashes or `--`); **reply only in the language given by "Reply language" in USER CONTEXT** (Albanian = standard Albanian), including text inside visual blocks; money formats `"1,500 L"` and `"€312"`.
- **VISUALS:** one block only when it helps; spend breakdown/comparison → ` ```ryze-chart ` (`Label: number`); goal/budget progress → ` ```ryze-progress ` (`Title: saved/total`); 2-3 headline figures → ` ```ryze-stats ` (`Label: value`); plan comparison → a small markdown table.
- **KNOWLEDGE:** *"RyzePoints (1 pt per 200 L x plan: Spark 1x, Lift 2x, Surge 4x, Apex 5x), plans, streaks, quests, squads, savings round-ups, fee-free FX, virtual/physical cards."*
- **RULES:** use only figures in USER CONTEXT, never invent; stay on money/Ryze; never ask for passwords, PINs, OTP or card numbers; it's a prototype — point to in-app actions, don't claim to move real money.
- Closes with `USER CONTEXT:\n\(context)`.

> **Note — plan multipliers consistency.** The system-prompt KNOWLEDGE line lists Spark 1x, Lift 2x, Surge 4x, Apex 5x. These match the real `PLANS` data in `Plans.swift` (Spark `1x`, Lift `2x`, Surge `4x`, Apex `5x`; prices 0 / 290 / 690 / 1,490 L/month).

### 3.3 Offline fallback — `Riz.reply(stepWhy:text:)`
Pure on-device function. Order of evaluation:

1. Run `guardInput(text)`; if it returns a string, return it (safety always wins).
2. Lowercase `text`. Keyword branches (substring match):
   - contains `safe`/`secure`/`trust`/`privacy`/`protect` → returns the supervised-by-Bank-of-Albania / ASD deposit insurance / Law No. 124/2024 safety statement.
   - contains `how long`/`time`/`quick` → *"It takes a few minutes. Nothing is submitted until the final step, so take your time."*
3. If `stepWhy` is non-nil → return it (contextual step explanation; passed as `nil` from `AssistantView`).
4. Default → *"I'm here to explain any step, ask me what something means or why it's needed."*

> The offline replies are **English-only canned strings** and do not localize to Albanian, unlike the live path. The `safe`/`how long` branches are onboarding-oriented (the `stepWhy` parameter and "nothing is submitted until the final step" copy indicate origin in an onboarding flow); in the Assistant tab `stepWhy` is always `nil`.

---

## 4. Suggested prompts (`caps`)

Four tappable cards in the empty state. Tapping one calls `send(prompt)`. Each is `(SF Symbol, title, prompt)`:

| Icon | Title (en / sq) | Prompt sent (en / sq) |
|---|---|---|
| `chart.pie.fill` | My spending / Shpenzimet e mia | How am I spending this month? / Si po shpenzoj këtë muaj? |
| `star.circle.fill` | RyzePoints / RyzePikë | How do RyzePoints work? / Si funksionojnë RyzePikët? |
| `crown.fill` | Best plan for me / Plani më i mirë | Which plan fits me best? / Cili plan më përshtatet? |
| `lock.shield.fill` | Is my money safe? / A janë të sigurta? | Is my money safe with Ryze? / A janë të sigurta paratë me Ryze? |

`capCard` renders each as an `IconTile` (38) + title + the prompt as a one-line subtitle + a trailing `arrow.up.right`, on `AppCardBG()`, with `PressStyle()`.

---

## 5. User-context injection (`rizContext`)

Real data fed to the live model. `rizContext()` returns a multi-line string built from `game` (`GameModel`) and `bank` (`BankModel`):

| Line | Source |
|---|---|
| `Reply language: English` / `Albanian (Shqip)` | `T(...)` (driven by `ryze_lang`) |
| `Name: <name>` | `game.name` |
| `Plan: <planLabel> (earn rate <earn>)` | `game.planLabel`, `PLANS.first { $0.id == game.plan }?.earn` (default `"1x"`) |
| `Level <n>, tier <tier>, RyzePoints <coins>, streak <n> days` | `game.li.level`, `game.tier.name`, `game.coins`, `game.streak` |
| `Balance: <ALL> main + <EUR>` | `money(bank.totalALL)`, `money(bank.accounts[1].balance, "EUR")` |
| `This month: income <…>, spent <…>` | `bank.monthIncome`, `bank.monthSpend` |
| `Spending by category: <name amount, …>` | `bank.categories` mapped to `"<name> <money(amount)>"` |
| `Savings goals: <name pct% (saved of target), …>` | `bank.goals` mapped to `"<name> <pct>% (<saved> of <target>)"` |

This context is what the system prompt commands the model to use exclusively ("Use only the figures in USER CONTEXT, never invent"). The offline fallback (`Riz.reply`) does **not** receive or use this context — it only sees the raw question text.

The privacy footnote ("only minimal data is shared") reflects that this aggregate financial summary — not transaction-level data — is what leaves the device.

---

## 6. Input-safety guardrails (`Riz.guardInput`)

`guardInput(_ t: String) -> String?` runs **before any reply** in both the offline path (inside `Riz.reply`) and conceptually as the persona's hard rules in the live path. It lowercases the input and returns a canned refusal (or `nil` to allow):

| Trigger (case-insensitive substring/regex on the input) | Returned response |
|---|---|
| Regex `\b\d{4,8}\b` (a 4–8 digit run) **or** contains `otp` / `pin` / `password` / `cvv` / `code` | *"Don't share codes, PINs or passwords with anyone, including me. Just enter the code on the screen above. (Hard rule, for your safety.)"* |
| contains `fraud` / `stolen` / `blocked` / `complain` | *"That's one for a real person on the Raiffeisen team. Want me to point you to in-app support?"* |
| contains `should i` / `which account` / `recommend` / `invest` | *"I can explain how the options work, but what's right for your money is your call, I can't advise on that. Want me to connect you with a Raiffeisen specialist?"* |
| none of the above | `nil` (no block; normal reply proceeds) |

Notes / edge cases:
- The first rule fires on **any** 4–8 digit number, so a user typing an amount like `1500` is intercepted with the codes/PIN refusal — a false positive by design (safety-first).
- These guard strings are English-only and not localized.
- The guard is only enforced programmatically on the **offline** path. On the **live** path, the equivalent constraint is delegated to the model via the system prompt's RULES ("Never ask for passwords, PINs, OTP or card numbers"); there is no client-side filter on text sent to or returned from the live service.

---

## 7. RizOrb — visual identity

`RizOrb(size:glow:)` is Riz's avatar/brand mark (not an abstract orb): it renders the `"RaiffeisenLogo"` image asset in a rounded-square (`cornerRadius size*0.28`), with a white hairline border and a yellow radial-glow background. When `glow == true`, it pulses (`scaleEffect` 0.92↔1.06, 1.8s ease-in-out, repeats forever) and casts a yellow shadow. Used at sizes 72 (empty-state hero), 42 (header), and 28 (message rows / typing indicator).

`TypingDots`: three `Brand.mute` dots that scale/fade in sequence (0.5s, staggered 0.15s) — the "Riz is typing" affordance shown while awaiting a reply.

---

## 8. Rich-text rendering (`RizRichText`)

A SwiftUI `View` that parses a Riz reply string into `[RizBlock]` (via `rizParse`) and renders each block natively. Bar/chip colors cycle through `palette = [Brand.coral, mint, violet, sky, pink, yellow]`.

### 8.1 Parser (`rizParse`)
Walks the text line by line, buffering prose and flushing it as `.text` blocks when a structured block begins:

- **Fenced block** (line starts with ` ``` `): the fence "kind" is the text after the backticks, lowercased. Body = lines until the closing ` ``` `. Dispatch:
  - kind contains `chart` → `.chart(rizPairs(body))`
  - kind contains `progress` → `.progress(rizProgress(body))`
  - kind contains `stat` → `.stats(rizStats(body))`
  - any other kind → body is treated as plain prose (flushed as `.text`). So unknown/standard code fences degrade gracefully to text.
- **Table** (line starts with `|`): consecutive `|…|` lines collected → `.table(rizTable(rows))`.
- Otherwise: appended to the prose buffer.

Helpers:
- `rizNum(_:)`: extracts a `Double` by keeping only digits and `.` (so `"1,500 L"` → `1500`).
- `rizPairs`: splits each line on the first `:` into (label, number).
- `rizProgress`: splits RHS on `/` → `(title, saved, total)`; if no `/`, treats RHS as a percentage out of `100`.
- `rizStats`: also splits a line on `|` so multiple stats can share one line; each `:`-split into (label, value-string).
- `rizTable`: splits rows on `|`, trims empty leading/trailing cells, and **drops markdown separator rows** (cells made only of `-`/`:`).

### 8.2 Block renderers

| Block | Rendering |
|---|---|
| **text** | Line-by-line. Lines starting `- ` / `* ` / `• ` become bullets (yellow `•` + inline markdown). Lines starting `#` become a 16pt bold heading. Blank lines become 2pt spacers. All other lines render via `md(...)`, which parses **inline markdown** (`AttributedString(markdown:options: .inlineOnlyPreservingWhitespace)`) so `**bold**` etc. work; falls back to plain `Text` if parsing fails. |
| **chart** | Horizontal bars. Each row: label (≤80pt, scales down), a `Capsule` bar whose width is `value/max` of the column (min 8pt) filled with the cycling palette color, and the value formatted via `money(...)`. Wrapped in a bordered `Brand.bg` card (radius 14). |
| **progress** | Per item: title (inline markdown) + a yellow `Int(value/total*100)%` label, a `ProgressBar`, and — only when `total != 100` (i.e. real amounts, not a bare percentage) — a `"<money(saved)> of <money(total)>"` caption. Bordered card (radius 14). Division guards with `max(1, total)`. |
| **stats** | A horizontal row of chips, each: value (16pt bold) over label (11pt muted), each chip `Brand.bg` bordered (radius 12), equal width. |
| **table** | Rows stacked; row 0 is bold (header). Cells render inline markdown, equal width, separated by 1pt hairlines. Bordered card (radius 12). |

The renderer therefore assumes Riz's `ryze-chart`/`ryze-progress`/`ryze-stats` fences and markdown tables exactly as instructed by the system prompt — i.e. the prompt's VISUALS contract and this parser are the two halves of the same protocol. Values are always re-formatted on the client via `money(...)`, so the model only needs to emit raw numbers.

---

## 9. Ask Riz sheet (out-of-scope note)

The profile **Help** screen (`case .help` in the profile detail view) includes an `actionStub(T("Ask Riz", "Pyet Riz"), "sparkles")` row that presents `DetailSheet.riz`, rendered as `RizSheet(stepWhy: nil, seed: false)` at `.large` detent. `RizSheet` is referenced here but defined elsewhere (not in the files in scope); from the call site it accepts a `stepWhy: String?` (passed `nil`) and a `seed: Bool` (passed `false`), consistent with the `Riz.reply(stepWhy:...)` offline contract. Its internal UI is not specified by these files.

---

## 10. riz-proxy (Cloudflare Worker)

`riz-proxy/README.md` documents a thin Cloudflare Worker whose purpose is to "keep the Ollama Cloud key off the device and forward Riz chat requests."

- **Deploy:** `npm i -g wrangler`, then in `riz-proxy/`: `wrangler secret put OLLAMA_API_KEY` (paste the Ollama Cloud key), `wrangler deploy` → prints `https://riz-proxy.<you>.workers.dev`.
- **Worker mode config** (recommended): in `RizService.swift` set `endpoint = "https://riz-proxy.<you>.workers.dev"`, `model = "gpt-oss:120b"`, `apiKey = ""` (empty — the Worker injects the key). Because `RizService` only sets the `Authorization` header when `apiKey` is non-empty, an empty key correctly lets the Worker supply it.
- **Direct mode** (the committed default, labeled "demo only"): `endpoint = "https://ollama.com/api/chat"`, `apiKey = "<your Ollama Cloud key>"` embedded in the app.

> **Flag — README vs. committed code drift.** The README shows the *intended* config as Worker-mode with an empty `apiKey`. The committed `RizService.swift` uses **direct mode** with a real embedded key (`RizSecret.ollamaKey`). The Worker is provided as deployable infrastructure but is **not** what the shipped app points at. The Worker's own source (e.g. a `worker.js`/`wrangler.toml`) is not in the files in scope — only its README — so the request transformation it performs is documented only at the level of "forwards Riz chat requests."

---

## 11. States & edge cases summary

| Situation | Behavior |
|---|---|
| Empty composer / whitespace-only send | No-op (early `guard`). |
| `msgs` empty, not typing | Empty-state hero + 4 suggested cards + privacy note. |
| Awaiting reply | `typing = true`; typing-dots bubble; composer still usable. |
| Live service returns a reply | Rendered via `RizRichText` (cards/markdown). |
| Live service unavailable (`isConfigured == false`, bad URL, non-2xx, network error, unparseable JSON) | Silently falls back to offline `Riz.reply`. |
| Offline reply with sensitive input | Guard refusal returned (codes/PIN, fraud/support, or advice-disclaimer). |
| Numeric input 4–8 digits offline | Intercepted by the codes/PIN guard (intentional over-block). |
| Long history | Live path sends only the **last 16** turns to the model; full history stays on-screen. |
| New-chat button | Clears `msgs` to `[]`, returns to empty state. |
| `RYZE_RIZ` env set | Seeds a static demo Q&A pair. |
| `RYZE_ASK` env set | Auto-sends that question once on appear. |
| Language = Albanian | Live replies (and visual-block text) come back in Albanian per the `Reply language` context line; UI chrome localizes via `T(...)`; **offline fallback and guard strings remain English-only**. |

---

## 12. Flagged placeholders / prototype markers

- **Prototype framing** (system prompt + `Riz.swift` header comment): Riz must "point to in-app actions, do not claim to move real money."
- **Embedded API key** (`RizSecret.ollamaKey`) — committed in plaintext; both the README and code comments mark direct mode as "demo only."
- **README/code drift** — README prescribes Worker mode (`apiKey = ""`); shipped code uses direct mode with a real key.
- **Demo seed strings** (`RYZE_RIZ`) — the spending answer (`16,500 L` / `6,400 L` / `~20%`) is a hardcoded screenshot mock, not computed from `BankModel`.
- **Offline fallback is onboarding-shaped** — `Riz.reply` carries a `stepWhy` parameter and "nothing is submitted until the final step" copy; in the Assistant tab `stepWhy` is always `nil`, so it falls through to generic English canned answers.
- **`RizSheet`** — referenced from Help but not defined in the in-scope files.

Relevant files: `/Users/eleviacom/raiffaiesen/ryze-ios/Ryze/Riz.swift`, `/Users/eleviacom/raiffaiesen/ryze-ios/Ryze/RizService.swift`, `/Users/eleviacom/raiffaiesen/ryze-ios/Ryze/RizRichText.swift`, `/Users/eleviacom/raiffaiesen/ryze-ios/Ryze/RizSecret.swift`, `/Users/eleviacom/raiffaiesen/ryze-ios/Ryze/Sections.swift`, `/Users/eleviacom/raiffaiesen/ryze-ios/Ryze/Plans.swift`, `/Users/eleviacom/raiffaiesen/ryze-ios/riz-proxy/README.md`.

# Plans & Membership Tiers

## Overview

`Plans.swift` defines Ryze's four youth membership tiers and the **Upgrade plan** screen (`PlansView`). The file declares two data types (`PlanBenefit`, `PlanTier`), a computed array `PLANS` of four tiers, and the SwiftUI sheet that lets a user browse, compare, and switch plans. All plan data is hardcoded in `PLANS` — there is no network/backend fetch; plans are static client-side content. Switching a plan calls `game.setPlan(tier.id)` on the shared `GameModel` and dismisses the sheet. All user-facing copy is bilingual via the `T(en, sq)` localization helper keyed on the `ryze_lang` AppStorage value ("en" default).

### Data model

#### `PlanBenefit`

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | Auto-generated; `Identifiable` conformance |
| `icon` | `String` | SF Symbol name |
| `text` | `String` | Bilingual benefit copy via `T(en, sq)` |

#### `PlanTier`

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | Stable plan key (`"spark"`, `"lift"`, `"surge"`, `"apex"`); matches `game.plan` |
| `name` | `String` | Display name (not localized) |
| `price` | `String` | Bilingual price string via `T` |
| `tagline` | `String` | Bilingual one-line description via `T` |
| `earn` | `String` | Bilingual RyzePoints earn-rate summary via `T` |
| `image` | `String` | Asset-catalog image name for the hero banner |
| `featured` | `Bool` | When `true`, renders a "MOST POPULAR" badge |
| `benefits` | `[PlanBenefit]` | Primary benefits (always shown) |
| `extra` | `[PlanBenefit]` | Secondary benefits (shown only when expanded) |
| `allCount` | `Int` (computed) | `benefits.count + extra.count` |

Note: `name`, `id`, `image`, and `featured` are not localized. Only `price`, `tagline`, `earn`, and each benefit's `text` are bilingual.

### The four tiers

Tier order in `PLANS` (left-to-right in the picker) is fixed: **Spark → Lift → Surge → Apex**. Prices ascend; the default-selected and `featured` tier is **Surge** (index 2).

#### Per-tier core attributes

| Attribute | Spark | Lift | Surge | Apex |
|---|---|---|---|---|
| `id` | `spark` | `lift` | `surge` | `apex` |
| `name` | Spark | Lift | Surge | Apex |
| `price` (EN) | 0 L/month | 290 L/month | 690 L/month | 1,490 L/month |
| `price` (SQ) | 0 L/muaj | 290 L/muaj | 690 L/muaj | 1,490 L/muaj |
| `earn` rate | 1x RyzePoints (1 pt / 200 L) | 2x RyzePoints (2 pt / 200 L) | 4x RyzePoints (4 pt / 200 L) | 5x RyzePoints (5 pt / 200 L) |
| `image` | `plan_free` | `plan_plus` | `plan_pro` | `plan_metal` |
| `featured` | false | false | **true** | false |
| `benefits` count | 6 | 6 | 6 | 6 |
| `extra` count | 2 | 2 | 2 | 2 |
| `allCount` | 8 | 8 | 8 | 8 |

Taglines (EN):
- **Spark** — "Start your rise. Zero cost, zero catch."
- **Lift** — "Made for students. Discounts where you actually spend."
- **Surge** — "Hit your stride. The all-rounder most Ryzers pick."
- **Apex** — "Go all in. Built for travel, Erasmus and big plans."

#### Spark (`spark`) — 0 L/month

Benefits (always shown):

| Icon | Benefit (EN) |
|---|---|
| `creditcard` | Free virtual card + your first physical Ryze card |
| `banknote` | 20,000 L fee-free ATM withdrawals every month |
| `paperplane` | Instant Ryze-to-Ryze transfers + one-tap bill splits |
| `star.circle` | Earn 1x RyzePoints (1 point per 200 L) |
| `target` | Savings goals with automatic round-ups |
| `flame` | Daily streak + starter quests to level up |

Extra (expanded only):

| Icon | Benefit (EN) |
|---|---|
| `sparkles` | Riz AI money coach for budgets and tips |
| `lock.shield` | Card freeze, limits and real-time alerts |

#### Lift (`lift`) — 290 L/month

Benefits:

| Icon | Benefit (EN) |
|---|---|
| `graduationcap.fill` | Student coupons: Glovo, cinema tickets and local cafés |
| `star.circle.fill` | Earn 2x RyzePoints on everything you buy |
| `banknote` | 50,000 L fee-free ATM withdrawals / month |
| `antenna.radiowaves.left.and.right` | 1 GB mobile data / month (Vodafone, ONE, ALBtelecom) |
| `paintpalette.fill` | 2 exclusive card skins to flex your style |
| `bolt.heart.fill` | Round-up Boost. Savings grow 2x faster |

Extra:

| Icon | Benefit (EN) |
|---|---|
| `shield.lefthalf.filled` | Streak Shield: skip a day without losing your streak |
| `headphones` | Priority in-app support when you need a human |

#### Surge (`surge`) — 690 L/month — featured ("MOST POPULAR")

Benefits:

| Icon | Benefit (EN) |
|---|---|
| `square.grid.2x2.fill` | 3 subscriptions on us: Spotify, Glovo Prime, YouTube and more |
| `star.circle.fill` | Earn 4x RyzePoints + double points on weekend nights out |
| `arrow.uturn.backward.circle.fill` | Cashback at partner brands (groceries, gyms, bookstores) |
| `airplane` | No-fee FX abroad up to 200,000 L / month, perfect for trips |
| `simcard.fill` | 3 GB mobile data / month on any Albanian network |
| `person.2.fill` | Squad Mode: shared goals and money challenges with friends |

Extra:

| Icon | Benefit (EN) |
|---|---|
| `ticket.fill` | Monthly RyzePoints drop + early access to ticket releases |
| `shield.lefthalf.filled` | Purchase protection up to 150,000 L |

#### Apex (`apex`) — 1,490 L/month

Benefits:

| Icon | Benefit (EN) |
|---|---|
| `globe` | Unlimited fee-free FX + cheap international transfers, made for Erasmus |
| `star.circle.fill` | Earn the max 5x RyzePoints on every purchase |
| `square.grid.2x2.fill` | 6 subscriptions included + highest partner cashback |
| `creditcard.fill` | Standout Apex card (metallic finish) + up to 3 physical cards |
| `simcard.fill` | 8 GB mobile data / month + roaming data for travel |
| `bolt.fill` | Quest Boost and Level Boost: rank up twice as fast |

Extra:

| Icon | Benefit (EN) |
|---|---|
| `bell.badge.fill` | Concierge for tickets, trips and last-minute student deals |
| `shield.lefthalf.filled` | Travel and purchase cover for your trips abroad |

### Plan comparison (feature x tier)

All values are exactly as written in code. "—" means the feature is not listed for that tier (it is not present in that tier's benefit copy; there is no logic that strips features).

| Feature | Spark (0 L) | Lift (290 L) | Surge (690 L) | Apex (1,490 L) |
|---|---|---|---|---|
| RyzePoints earn multiplier | 1x (1 pt / 200 L) | 2x (2 pt / 200 L) | 4x (4 pt / 200 L) + double on weekend nights out | 5x (5 pt / 200 L) — "the max" |
| Cards | Free virtual + first physical Ryze card | (inherits, not restated) | — | Apex metallic card + up to 3 physical cards |
| Fee-free ATM withdrawals | 20,000 L / month | 50,000 L / month | — | — |
| Transfers / splits | Ryze-to-Ryze + bill splits | — | — | — |
| Savings | Goals + automatic round-ups | Round-up Boost (2x faster) | — | — |
| Streaks / quests | Daily streak + starter quests | Streak Shield (skip a day) | — | Quest Boost + Level Boost (2x faster rank-up) |
| Riz AI coach | Riz AI money coach | — | — | — |
| Card controls | Freeze, limits, real-time alerts | — | — | — |
| Student coupons | — | Glovo, cinema tickets, local cafés | — | — |
| Mobile data | — | 1 GB / month (Vodafone, ONE, ALBtelecom) | 3 GB / month (any Albanian network) | 8 GB / month + roaming |
| Card skins | — | 2 exclusive skins | — | (metallic Apex finish) |
| Support | — | Priority in-app support | — | Concierge (tickets, trips, last-minute deals) |
| Subscriptions on us | — | — | 3 (Spotify, Glovo Prime, YouTube and more) | 6 included |
| Cashback | — | — | Partner brands (groceries, gyms, bookstores) | Highest partner cashback |
| Foreign exchange (FX) | — | — | No-fee FX abroad up to 200,000 L / month | Unlimited fee-free FX + cheap international transfers |
| Social/group | — | — | Squad Mode (shared goals + challenges) | — |
| RyzePoints drops | — | — | Monthly drop + early ticket access | — |
| Purchase/travel protection | — | — | Purchase protection up to 150,000 L | Travel + purchase cover for trips abroad |

Note on inheritance: tiers do **not** programmatically inherit lower-tier benefits — each tier's benefit list is independent and self-contained as authored. The copy implies a progression (e.g. Surge/Apex do not re-list a "first physical card") but there is no code that merges or stacks benefit lists across tiers.

### Screen: `PlansView` (Upgrade plan sheet)

`PlansView` is a full-screen view over `Brand.bg`. Dependencies: `@Environment(\.dismiss)`, `@EnvironmentObject var game: GameModel`, `@AppStorage("ryze_lang")`.

#### State

| State var | Type | Initial | Purpose |
|---|---|---|---|
| `sel` | `Int` | `2` | Index of the selected tier in `PLANS` (default Surge) |
| `expanded` | `Bool` | `false` | Whether `extra` benefits are shown |

Computed:
- `tier` = `PLANS[sel]` — currently selected tier.
- `rows` = `expanded ? tier.benefits + tier.extra : tier.benefits` — benefit rows rendered.
- `isCurrent` = `tier.id == game.plan` — whether the selected tier is the user's active plan.

#### Layout (top to bottom)

1. **Header bar** — a close button (`xmark` in a circular `Brand.surface` chip, 36×36) on the left that calls `dismiss()`; centered title "Upgrade plan" / "Përmirëso planin" (17pt semibold); a clear 36×36 spacer on the right for symmetry.

2. **Horizontal tier picker** — a horizontal `ScrollView` of capsule buttons, one per plan in `PLANS` order. Each capsule shows the plan `name`; if `p.id == game.plan` (the user's current plan), a bold `checkmark` SF Symbol is appended next to the name. The selected capsule (`sel == i`) uses `Brand.text` foreground, `Brand.surface` background, and a `Brand.hairline` capsule stroke; unselected capsules use `Brand.mute` foreground and clear background. Tapping a capsule runs `withAnimation(.snappy) { sel = i; expanded = false }` — selecting a plan also collapses the expanded benefit list.

3. **Scrollable detail** (vertical `ScrollView`):
   - **Hero banner** — `Image(tier.image)` scaled to fill, fixed 168pt height, full width, clipped, with a bottom black gradient overlay (`.clear → black 0.55`). Overlaid at bottom-left: `tier.name` (30pt bold white) and `tier.price` (15pt semibold white at 85% opacity). If `tier.featured`, a gold capsule badge "MOST POPULAR" / "MË I ZGJEDHURI" (10pt bold, black text on `Brand.gold`) appears at bottom-right. The banner is clipped to a 24pt rounded rectangle with a `specularBorder(24)`.
   - **Tagline** — `tier.tagline` in `Brand.mute` (15pt).
   - **Benefit rows** — one row per item in `rows`: the SF Symbol `b.icon` (18pt, `Brand.yellow`, 28pt-wide frame) followed by `b.text` (16pt, `Brand.text`), vertically padded 11pt.
   - **Expand/collapse toggle** — a full-width capsule button on `Brand.surface` using `PressStyle()`. Label: when collapsed, "See all {allCount} benefits" / "Shiko të {allCount} përfitimet"; when expanded, "Show less" / "Më pak". Toggles `expanded` with `.snappy` animation.

4. **Primary action button** (`PrimaryButton`, pinned at bottom) — its title and enabled state depend on the selected tier:
   - If `isCurrent` → title "Your current plan" / "Plani yt aktual", **disabled** (`enabled: !isCurrent`).
   - Else if `tier.id == "spark"` → "Switch to Spark" / "Kalo te Spark".
   - Else → "Join {name}" / "Bashkohu te {name}" (e.g. "Join Surge").
   - Action (only reachable when enabled): `game.setPlan(tier.id); dismiss()`.

#### Lifecycle

`.onAppear` sets `sel = PLANS.firstIndex { $0.id == game.plan } ?? 2` — the sheet opens focused on the user's **current** plan, falling back to index 2 (Surge) if the stored `game.plan` id is not found in `PLANS`.

### User flows

**Browse and compare plans:**
1. Sheet opens; the picker and detail default to the user's current plan (via `.onAppear`), else Surge.
2. User taps any tier capsule → detail re-renders for that tier; the expanded list resets to collapsed.
3. User taps "See all N benefits" → the `extra` rows append below the primary benefits; label switches to "Show less". Tapping again collapses.

**Switch / upgrade plan:**
1. User selects a tier other than their current plan.
2. The bottom button reads "Join {name}" (or "Switch to Spark" for the free tier) and is enabled.
3. Tapping it calls `game.setPlan(tier.id)` then `dismiss()` — the sheet closes immediately; the new plan id is persisted on `GameModel`.

**Viewing the current plan:**
1. The current plan's capsule shows a trailing checkmark.
2. When that tier is selected, the bottom button reads "Your current plan" and is **disabled**; no action fires.

### States & edge cases

- **Current-plan indicator (two cues):** (a) a `checkmark` appended to the current plan's picker capsule (driven by `p.id == game.plan`, independent of selection); (b) the disabled "Your current plan" button when the current plan is the selected tier (`isCurrent`).
- **Default selection vs. current plan:** `sel` is initialized to `2`, but `.onAppear` overrides it to the current plan's index. If `game.plan` does not match any tier id, selection falls back to index 2 (Surge).
- **Expanded state resets on tier change:** selecting any capsule sets `expanded = false`, so each tier always opens collapsed.
- **No purchase/confirmation flow:** switching plans is instantaneous and free in-app — there is no payment sheet, billing, confirmation dialog, proration, or downgrade warning. `setPlan` is applied directly. This is a prototype/demo behavior; the displayed prices (e.g. 690 L/month) are content only and are not charged anywhere in this code.
- **Free-tier copy special-case:** only `spark` gets "Switch to Spark"; all other non-current paid tiers use "Join {name}". There is no distinct "downgrade" wording.
- **Featured badge:** only `surge` renders "MOST POPULAR"; the badge is purely presentational.

### Placeholders / things to flag

- **No backend or real billing.** Plans, prices, and perks are static hardcoded content in `PLANS`; `game.setPlan` only stores a plan id locally. None of the prices are actually charged.
- **Perks are descriptive copy only.** Benefits such as "3 subscriptions on us", cashback, FX limits, mobile-data allowances, concierge, purchase protection, Squad Mode, Streak Shield, Quest/Level Boost, RyzePoints multipliers, and card skins are presented as text in benefit rows; this file contains **no** logic that provisions, enforces, or tracks any of them. Whether the earn multipliers or boosts are wired elsewhere (e.g. in `GameModel`) is out of scope for this file and not verifiable here.
- **Named third-party partners** (Glovo, Glovo Prime, Spotify, YouTube, Vodafone, ONE, ALBtelecom) appear only as benefit copy; there is no integration code here.
- **No TODO/"next"/explicit placeholder comments** exist in `Plans.swift`; the placeholder nature is inferred from the absence of billing/provisioning logic, not from in-code markers.

Source file: `/Users/eleviacom/raiffaiesen/ryze-ios/Ryze/Plans.swift`

# Design System & Navigation

## Overview

The Ryze design system is a Revolut-inspired component and token system stamped with Raiffeisen Banana Yellow as a deliberately scarce accent. All tokens live in `Ryze/Theme.swift` (the `Brand` enum); reusable components in `Ryze/Components.swift` and `Ryze/AppViews.swift`; navigation chrome (`TopBar`, `ProfileSheet`) and several tab roots in `Ryze/Sections.swift`. The canonical written spec is `BRANDING.md`, which this chapter cross-checks against the actual code.

The app targets iOS 17+ SwiftUI and supports two languages (English / Albanian) via the `T(en, sq)` helper, and three appearance modes (System / Light / Dark) via adaptive color tokens.

> Discrepancy flag: `BRANDING.md` documents several components by name — `PillButton`, `QuickAction`, `Avatar`, `Ring`, `StatCard`, `Bar`, `MissionRowView`, `ToastBanner`, `AmountSheet`, `FeaturedCard`, `AppCard`, `RizRichText` — that are **referenced** in the four read files but **defined in `Ryze/AppViews.swift`** (not provided to this chapter). Their signatures below are reconstructed from call sites and `BRANDING.md`; field-level internals of those types are out of scope for the files read. This is flagged inline wherever it occurs.

---

## Color Tokens (`Brand` enum)

Colors are constructed via two `Color` initializers in `Theme.swift`:

- `Color(hex: UInt, alpha: Double = 1)` — single fixed sRGB value.
- `Color(lightHex:darkHex:)` — adaptive; resolves per `UITraitCollection.userInterfaceStyle` (light vs dark), so tokens auto-flip with appearance mode.

### Surface & elevation tokens

| Token | Light hex | Dark hex | Usage (from code + `BRANDING.md`) |
|---|---|---|---|
| `void` | `#000000` | `#000000` (fixed) | Balance/points hero + onboarding canvas only; pure black so flat-black art blends |
| `bg` | `#F4F3EF` | `#151412` | App canvas — warm charcoal, lifted off pure black |
| `elev1` | `#FAFAF6` | `#1E1C19` | Bottom stop of card gradient |
| `elev2` (= `surface`) | `#FFFFFF` | `#272421` | Top of card gradient; chips; fields |
| `elev3` (= `surfacePressed`) | `#ECEAE4` | `#332F2B` | Pressed / highest surface; segmented control idle fill |
| `surface` | alias of `elev2` | | Chips, fields, search bar, OTP cells |
| `surfaceDeep` | `#100F0D` | `#100F0D` (fixed) | Defined; deep surface |
| `surfacePressed` | alias of `elev3` | | Pressed state |

### Brand / accent tokens

| Token | Value | Usage |
|---|---|---|
| `yellow` | `#F8D01F` (Banana Yellow) | The brand stamp: rings, ticks, glyphs, progress, points mark. Scarce. |
| `goldTop` | `#FFE470` | Gold gradient top |
| `goldBot` | `#D4A200` | Gold gradient bottom |
| `goldEdge` | `#FFEFA8` | Specular edge on gold surfaces |
| `gold` | `LinearGradient` stops `#FFE470 @0` → `#F8D01F @0.5` → `#D4A200 @1`, top→bottom | The ONE premium fill per screen |
| `onAccent` | `Color.black` (fixed) | Foreground on gold/yellow |
| `yellowInk` | light `#B8860B` / dark `#F8D01F` | Yellow as foreground on light/white surfaces (Eyebrow tick, some IconTiles) |
| `onText` | light `#FFFFFF` / dark `#000000` | Inverse of `text` — foreground on high-contrast (`Brand.text`) buttons/bubbles |
| `text` | light `#131210` / dark `#FFFFFF` | Primary text |
| `mute` | light `#6A6A66` / dark `#B0B0B0` | Secondary text + idle icons (palette Gray) |
| `faint` | light `#83837C` / dark `#76736D` | Tertiary / captions / disabled |
| `good` | light `#12A86A` / dark `#2FD98A` | Positive amounts, success ticks |
| `danger` | `#FF4D52` (fixed) | Destructive / errors (Log out, etc.) |

### Vibrant accent set (fixed, both modes)

| Token | Hex | Usage |
|---|---|---|
| `violet` | `#8B5CFF` | Cinema/game reward category, IconTiles |
| `mint` | `#2FE3B6` | Card style, accents |
| `pink` | `#FF5C8A` | Merch/fashion reward, Invite IconTile |
| `coral` | `#FF6F47` | Food reward, streak flame |
| `sky` | `#46A8FF` | Mobile/data reward |

`BRANDING.md` defines these strictly as illustrative accents (categories, reward tiles, icon tiles) and forbids them as primary UI chrome (which stays banana + neutral).

### Dynamic UIColor-backed tokens (alpha varies by mode)

These are built from `UIColor { trait in ... }` closures so they carry different opacity in light vs dark:

| Token | Dark | Light | Usage |
|---|---|---|---|
| `shadow1` | black 60% | black 5% | Contact shadow (AppCard) |
| `shadow2` | black 40% | black 8% | Ambient shadow (AppCard) |
| `specularTop` | white 14% | black 7% | Top of specular border gradient |
| `specularBot` | white 3% | black 2% | Bottom of specular border gradient |
| `hairline` | white 9% | black 10% | The ONLY border token in the system |

> Discrepancy flag: `BRANDING.md` states `hairline` is "white 8%" and `mute` is "#B0B0B0"; the code uses **white 9% / black 10%** for `hairline` and the adaptive **`#6A6A66` / `#B0B0B0`** for `mute`. Code is authoritative.

### The gold rule

Per `BRANDING.md` §2 and §10, gold is "scarce ink": at most one gold fill per screen (the primary action or the featured surface); everything else is neutral glass with yellow as a thin accent only. This is enforced by convention, not by code.

---

## Card Personalisation Styles (`CardStyle` enum)

`CardStyle: String, CaseIterable, Identifiable, Codable` — colour themes for physical/virtual/custom payment cards.

| Case | `title` (EN / SQ) | `colors` (gradient stops) | `ink` | `swatch` |
|---|---|---|---|---|
| `gold` | Banana Gold / Ari Banane | `#FFE470`, `#F8D01F`, `#D4A200` | black | `#FFE470` |
| `midnight` | Midnight / Mesnatë | `#3A2E6E`, `#18161F` | white | `#3A2E6E` |
| `coral` | Coral / Koral | `#FF8A5C`, `#D93D2E` | white | `#FF8A5C` |
| `mint` | Mint / Mentë | `#4DE9B6`, `#0F9E76` | black | `#4DE9B6` |

`ink` is black for `gold`/`mint`, white otherwise. `swatch` is the first gradient stop (fallback `Brand.yellow`). `id` is the raw value.

---

## Typography

There is no token struct for type; sizes are inline `.font(.system(size:weight:design:))` calls. `BRANDING.md` §4 declares the global modifier `.fontDesign(.rounded).monospacedDigit()` on `RootView` (rounded + tabular figures so numbers never reflow) — applied at the root level outside the read files.

### Declared scale (`BRANDING.md` §4)

| Role | Size / weight |
|---|---|
| Hero | 46 bold rounded, gradient ink `[white, white 78%]`, `.contentTransition(.numericText())` (odometer roll) |
| Display | 34 bold, tight tracking (~−0.025·size) |
| Title | 22 semibold |
| Headline | 17 semibold |
| Body | 15 medium |
| Label | 13 |
| Caption | 11 |

3-weight discipline: **medium** body, **semibold** interactive/labels, **bold** display; avoid in-betweens.

### `Text.display(_:)` helper (`Theme.swift`)

```swift
func display(_ size: CGFloat = 40) -> Text
```

Applies `.system(size:weight:.bold, design:.default)` with `.tracking(-1)`. Default size 40. Note: this helper uses `design: .default`, not `.rounded`.

### Actual sizes observed in code (representative)

| Context | Size / weight |
|---|---|
| `PrimaryButton` / `GhostButton` title | 17 semibold |
| `RyzeField` label | 12 medium, tracking 0.4, uppercased |
| `RyzeField` input / prefix | 17 |
| `OtpField` cell digit | 22 semibold |
| `Eyebrow` text | 11 semibold, tracking 1.4, uppercased |
| Profile name | 20 bold |
| Profile mini-stat value / label | 17 bold / 11 |
| Nav row title | 16 semibold |
| Season hero "Level N" | 28 bold rounded |
| Points counter | 22 bold rounded, `.contentTransition(.numericText())` |
| Assistant header "Riz" | 18 bold |
| Chat bubble text | 15 |
| Coupon code (redeemed) | 18 bold monospaced, tracking 2 |
| IBAN value | 15 medium monospaced |

---

## Elevation & Materials

Depth is luminance + specular edge + layered shadow, never flat black-on-black.

### `specularBorder(_ radius:)` — `View` extension (`Theme.swift`)

Overlays a `RoundedRectangle(cornerRadius: radius)` stroked with a top-lit `LinearGradient([specularTop, specularBot], .top→.bottom)`, `lineWidth: 1`. The universal "top sheen edge" applied to every card/hero.

### `AppCardBG` (`Sections.swift`)

A standalone background view: `RoundedRectangle(cornerRadius: 24).fill(LinearGradient([elev2, elev1], .top→.bottom)).specularBorder(24)`. Used directly as a `.background()` on tappable cards that aren't wrapped in `AppCard` (e.g. the Log-out row, Assistant capability cards, coupon tickets).

### Recipes (`BRANDING.md` §3)

| Surface | Recipe |
|---|---|
| **AppCard (glass)** | `LinearGradient([elev2, elev1])` + top sheen `[white 6%, clear]` + `.specularBorder(24)` + clip RR(24); shadows contact `black 60% r2 y1` + ambient `black 40% r22 y14` |
| **FeaturedCard (gold)** | `Brand.gold` fill + softLight sheen `[white 30%, clear]` + `goldEdge 50%` stroke + clip(24) + glow `yellow 26% r22 y12` |
| **Void hero** | `Brand.void` fill + top-leading banana `RadialGradient([#F8D01F 13%, clear])` + `.specularBorder(24)` + soft shadow |

> The actual `RewardsHub` season hero (`Sections.swift`) uses `RadialGradient([#F8D01F 16%, clear])` (not 13%) and `.shadow(black 50% r20 y12)`, and forces `.environment(\.colorScheme, .dark)` so the void hero always reads as dark regardless of app appearance.

### Radii & borders

| Element | Radius |
|---|---|
| Tiles / chips | 12–14 |
| Cards / heroes | 24 |
| IconTile | `size * 0.28` (continuous) |
| Pills / buttons | Capsule |
| Sheets | `.presentationCornerRadius(28)` (per `BRANDING.md`) |

Border is always `hairline`. Mixed border opacities are explicitly forbidden (`BRANDING.md` §10).

---

## Component Library

### Defined in `Components.swift`

#### `PrimaryButton(title:enabled:action:)`
Full-width pill, height 54, `Brand.text` fill, `Brand.onText` foreground (inverse), 17 semibold. `PressStyle()`. Disabled state: opacity 0.35 (animated, `.easeOut 0.15`), and the action is gated by `enabled` inside the closure (tap still registers but no-ops). Default `enabled = true`.

#### `GhostButton(title:action:)`
Full-width pill, height 54, transparent fill, `Brand.text` 1pt capsule stroke + `Brand.text` 17 semibold label. `PressStyle()`.

#### `RyzeField(label:text:placeholder:prefix:keyboard:)`
Labeled text field. Uppercased 12-medium `mute` label (tracking 0.4); optional `prefix` text (e.g. currency) at 17; `TextField` with `faint` prompt, autocorrection disabled, height 56, `Brand.surface` background, RR(12) clip. Border switches `hairline → Brand.text` on focus (`@FocusState`). `keyboard` defaults to `.default`.

#### `OtpField(code:)`
6-digit OTP entry. A hidden, near-invisible `TextField` (opacity 0.02, `.numberPad`) captures input; an `onChange` filters to digits and clamps to 6 (`prefix(6)`). A visible `HStack` of 6 cells (46×56, RR(12)) renders each char at 22 semibold; the active cell (`i == code.count`) gets a `Brand.text` 1.5pt stroke, others `hairline`. Tapping the row or appearing focuses the field.

#### `ConsentRowView(consent:checked:onToggle:)`
KYC consent checkbox row. 24×24 RR(7) box filling `Brand.yellow` when checked with a black `checkmark` (13 bold); label at 13, `Brand.text`, multiline. Whole row is a `.plain` button. `consent` is a `ConsentDef` (defined elsewhere) with a `.label` string.

#### `ProgressBar(value:)`
Horizontal track: `hairline` capsule under a `Brand.yellow` capsule of width `max(6, width * value)`. Fixed height 4. Animates `.easeInOut 0.3` on value change. Used in the season hero, squad goal, and elsewhere.

#### `LogoTile(size:)`
Raiffeisen logo (`Image("RaiffeisenLogo")`) scaled-to-fill into a RR(`size*0.28`) tile. Default size 56.

#### `Eyebrow(text:)`
The repeated section-label micro-signature: a 14×2 `Brand.yellowInk` capsule tick followed by uppercased 11-semibold `faint` text, tracking 1.4. Used for every section label across the app.

> Discrepancy flag: `BRANDING.md` §4 describes the Eyebrow tick as `yellow`; the code uses `Brand.yellowInk` (the adaptive gold-on-light token). Code is authoritative.

### Referenced but defined in `AppViews.swift` (out-of-file)

Reconstructed from call sites and `BRANDING.md` §6; treat signatures as approximate where noted:

| Component | Reconstructed signature | Notes |
|---|---|---|
| `AppCard { content }` | trailing-closure container | The glass container; used pervasively |
| `FeaturedCard { content }` | trailing-closure container | The single gold surface |
| `PillButton(title:system:style:enabled:action:)` | small pill | `style` cases `.primary/.dark/.soft` per `BRANDING.md`; call sites use `title`/`enabled`/`action` |
| `QuickAction(icon:label:prominent:action:)` | 52pt circle row item | `prominent:true` = gold+glow |
| `IconTile(system:color:size:)` | tinted SF-symbol tile | `color` optional (defaults observed); RR(`size*0.28`) |
| `Avatar(name:size:imageData:you:)` | initial-in-circle | `imageData` overrides initial with a photo; `you` = yellow |
| `Ring(v:size:)` | yellow circular progress | per `BRANDING.md` |
| `StatCard(value:label:)` | stat tile | per `BRANDING.md` |
| `Bar(v:)` | yellow track fill | per `BRANDING.md` |
| `MissionRowView(m:)` | quest/challenge row | `m` is a `Mission` |
| `ToastBanner(toast:)` | top reward toast | per `BRANDING.md` |
| `AmountSheet(mode:)` | money entry sheet | `mode` cases `.send/.request/.add/.fund` |
| `RizRichText(text:)` | rich-text renderer | renders assistant reply markdown-ish text |
| `ScreenScroll { }` | scroll container | wraps tab roots; vanilla `ScrollView` + ~140 bottom padding |
| `ScreenScroll`/`SearchSheet`/`AnalyticsView`/`PlansView`/`EarnSheet`/`RewardsStoreSheet`/`ComingSoonSheet` | sheets/screens | presented from `RewardsHub` and Profile |

---

## Motion & Animation Patterns

### `PressStyle` (`ButtonStyle`, `Theme.swift`)
Scales the label to **0.95** when pressed, `.spring(response: 0.28, dampingFraction: 0.55)`. Applied to every tappable control (`BRANDING.md` §8: "on every tappable control").

### `PressableCard` / `.pressable(scale:)` (`Theme.swift`)
For tappable cards that are *not* `Button`s (e.g. a card with a nested control). Uses `@GestureState` + a `DragGesture(minimumDistance: 0)` as a `simultaneousGesture` so it never steals the card's own `.onTapGesture` or a child button's tap, and auto-resets on release. Scales to `scale` (default **0.965**) and applies `brightness(-0.035)` while pressed, `.spring(response: 0.34, dampingFraction: 0.62)`. Exposed as `View.pressable(scale:)`.

### `CelebrationOverlay(trigger:)` (`Theme.swift`)
The signature win animation. On `trigger` change, 18 particles (`count = 18`) burst radially outward: even indices are 10×10 circles, odd are 12×7 rounded chips; every third particle is white, the rest `Brand.yellow`. Each animates from `t=0` to `t=1` over `.easeOut 0.9` — offset `cos/sin(angle) * 175 * t` (with a −30 y lift), rotation `t*220°`, opacity `1−t`. `.allowsHitTesting(false)`. Per `BRANDING.md` §7 it is mounted in `MainTabView` and fired by `game.celebrate` on every claim/redeem/check-in/account-opened.

### `RizOrb(size:glow:)` (`Sections.swift`)
The assistant avatar/mark. Raiffeisen logo clipped to RR(`size*0.28`, continuous) with a white-12% stroke, over a radial banana glow (`yellow 42%` when `glow`), and a yellow drop shadow (`35%`, r16 y5 when `glow`). When `glow`, the backing glow pulses scale 0.92↔1.06 forever (`.easeInOut 1.8 repeatForever`). Default size 44, glow on.

### `TypingDots` (`Sections.swift`)
Three 7×7 `Brand.mute` dots that scale 0.5↔1 / fade 0.4↔1 with a per-dot 0.15s staggered `.easeInOut 0.5 repeatForever` — the assistant "is typing" indicator.

### Other declared motion (`BRANDING.md` §8)
- Numbers: `.contentTransition(.numericText())` + `withAnimation(.snappy)`.
- Reveal/hide: blur + crossfade with `.smooth(0.35)` (e.g. balance hide-eye).
- KYC/step changes: slide+fade.
- Icons that react: `.symbolEffect(.bounce, value: trigger)` (e.g. the points star bouncing on `game.celebrate` in the season hero).
- Success haptic fires on celebrate.

---

## Localisation & Appearance Plumbing

### `T(_ en:_ sq:)` (`Theme.swift`)
Returns the Albanian string when the active language is `"sq"`, else English. Language resolves from env var `RYZE_LANG` → `UserDefaults` key `ryze_lang` → default `"en"`. Every user-facing string in the read files is wrapped in `T(...)` (those that aren't — e.g. "Email", "klevi@ryze.al", IBAN, statement months — are English/data-only literals, flagged as mock data below).

### Appearance & language persistence
- `@AppStorage("ryze_lang")` — language, toggled by the Settings segmented control.
- `@AppStorage("ryze_appearance")` — `"system" | "light" | "dark"`, default `"dark"`, toggled by the Appearance segmented control. (Applied at root, outside the read files.)
- `@AppStorage("ryze_app_lock")` — Face ID / passcode app lock toggle, default `false`.

---

## Navigation & Information Architecture

### 5-tab structure

Per `BRANDING.md` §9, the app is a 5-tab bar (the `MainTabView`/tab definitions live outside the read files; the tab tint is `Brand.yellow`). Each tab uses a filled SF Symbol for active, outline for idle:

| # | Tab | SF Symbol | Root view (where known) |
|---|---|---|---|
| 1 | Home | `house.fill` | Bento dashboard (defined in `AppViews.swift`) |
| 2 | Cards | `creditcard.fill` | Cards screen (out-of-file) |
| 3 | Pay | `paperplane.fill` | Pay screen (out-of-file) |
| 4 | Assistant | `sparkles` | `AssistantView` (`Sections.swift`) |
| 5 | Rewards | `gift.fill` | `RewardsHub` (`Sections.swift`) |

> Of the five roots, only **Assistant** (`AssistantView`) and **Rewards** (`RewardsHub`) are defined in the read files. Home (the bento dashboard), Cards, and Pay are defined in `AppViews.swift` and are documented from `BRANDING.md` only (below).

### Bento Home dashboard (`BRANDING.md` §7 — out-of-file layout)

The Home tab is explicitly NOT a Revolut "balance-banner → circle-row → linear-feed" stack. Declared layout:

1. **Hero row** — a void **balance tile** beside the single gold **level/points tile**, equal height.
2. **Move-money console** — square `IconTile` actions inside ONE `AppCard` with hairline dividers (never a floating circle row).
3. **Goal + this-week-spend** tile pair.
4. **Bounded activity card** — capped at ~5 rows with a "See all" → `TxnHistorySheet`.

Supporting signature elements: the points glyph `star.circle.fill` in yellow; a mini **sparkline** = `HStack` of `Capsule`s range-compressed via `pow(v/max, 0.55)` so one large value doesn't dominate. `BRANDING.md` §10 forbids floating circle-action rows on Home.

---

## `TopBar` (`Sections.swift`)

The persistent header on tab roots that use it (confirmed: `RewardsHub`). Layout is an `HStack(spacing: 12)`:

| Element | Behaviour |
|---|---|
| Avatar (40pt) | `Button` → `onProfile()`; shows `imageData` photo or initials |
| Search bar | Capsule, 40 tall, `magnifyingglass` + localized "Search"/"Kërko" placeholder, `Brand.surface` fill + `hairline` stroke; `Button` → `onSearch()` |
| Analytics button | 40pt circle, `chart.bar.fill`, `Brand.surface`; `Button` → `onAnalytics()` |

Signature: `TopBar(name:imageData:onProfile:onAnalytics:onSearch:)` — `imageData`, `onAnalytics`, `onSearch` have empty/nil defaults.

---

## Profile / Settings (`ProfileSheet` + `ProfileDetailView`)

Opened from the `TopBar` avatar. A `NavigationStack` over `Brand.bg`, presented as a sheet.

### `ProfileSheet` (`Sections.swift`)

Toolbar: leading `xmark` (dismiss); trailing gold **Upgrade** pill (`sparkles` + "Upgrade"/"Përmirëso") → opens `PlansView`. Nav bar background `Brand.bg`.

Scroll content (top to bottom):

1. **Identity card** (`AppCard`)
   - `PhotosPicker` avatar (48pt) inside a 60pt gold ring with a `camera.circle.fill` badge; selecting a photo loads `Data` into `game.avatarData` (via `loadTransferable`).
   - Name (`game.name`, 20 bold); handle button `@{name.lowercased()}` + `qrcode` glyph → opens `QRSheet`.
   - Three mini-stats with vertical dividers: **Level** (`game.li.level`), **Points** (`game.coins`), **Tier** (`game.tier.name`).
2. **Plan featured card** (`FeaturedCard`, black ink) — `game.planLabel` + "See your plan benefits" + `star.circle.fill`; → `PlansView` (`showPlans`).
3. **Account** section (`Eyebrow`) — `AppCard` with rows: `.personal`, `.account`, `.security` (each a `NavigationLink(value:)`).
4. **Rewards & sharing** section — `AppCard`:
   - `ShareLink` "Invite friends" / "Fto miqtë", subtitle "Earn 2,000 points or more" / "Fito 2,000 pikë ose më shumë", `gift.fill` pink IconTile. Share text: `"Join me on Ryze, use code {referralCode} and we both get 200 points."`
   - `.inbox` nav row with a yellow **badge "3"**.

   > Copy inconsistency (in code): the Invite-friends subtitle says "Earn **2,000** points or more", while the share message and the Rewards-hub invite card both say "we both get **200** points". Both literals are as written in the source.
5. **More** section — `AppCard` rows: `.documents`, `.settings`, `.help`.
6. **Log out** — red `rectangle.portrait.and.arrow.right` IconTile + "Log out"/"Dil"; calls `game.resetDemo()` then dismisses. (Demo reset — flagged as prototype behaviour.)
7. Footer: "Ryze · prototype for Raiffeisen Bank Albania" (localized) — confirms prototype status.

Sheets presented from here: `PlansView` (`showPlans`), `QRSheet` (`showQR`). `navigationDestination(for: ProfileDetail.self)` pushes `ProfileDetailView`.

### `ProfileDetail` enum (`Sections.swift`)

`enum ProfileDetail: String, Identifiable, Hashable` — drives both nav rows and pushed detail screens.

| Case | EN title | SQ title (`pdTitle`) | `icon` |
|---|---|---|---|
| `personal` | Personal info | Të dhënat personale | `person.text.rectangle.fill` |
| `account` | Account details | Detajet e llogarisë | `building.columns.fill` |
| `security` | Security & privacy | Siguria & privatësia | `lock.shield.fill` |
| `documents` | Documents | Dokumentet | `doc.text.fill` |
| `settings` | Settings | Cilësimet | `gearshape.fill` |
| `help` | Help | Ndihmë | `questionmark.circle.fill` |
| `inbox` | Inbox | Mesazhet | `bell.badge.fill` |

> Note: the enum's own `.title` computed property returns English-only strings; navigation/display use the localized `pdTitle(_:)` free function instead. Both exist in the file.

### `ProfileDetailView` (`Sections.swift`)

Pushed screen per `ProfileDetail`. Scroll over `Brand.bg`, inline nav title = `pdTitle(detail)`. Has an internal `DetailSheet` enum (`coming(String)`, `info(String, String)`, `riz`) presented via `.sheet(item:)`.

| Detail | Contents (all data is mock/hard-coded) |
|---|---|
| `.personal` | `infoCard` rows: Full name = `game.name`; **Email `klevi@ryze.al`**, **Phone `+355 69 123 4567`**, **DOB `14/03/2004`**, **Nationality `Albania`** — hard-coded mock |
| `.account` | IBAN **`AL47 2026 1100 4827`** (mock) with mask/reveal eye + copy (`Clip.copySensitive`); Account `{name} · Personal`; Currency `ALL · EUR`; Opened `Today`; Status `Active` |
| `.security` | "Sign in" group: **App lock (Face ID / passcode)** toggle (`ryze_app_lock`); "Change passcode" → ComingSoon stub. "Privacy" group: **Hide balance** toggle (`bank.hideBalance`); "Trusted devices" → stub |
| `.documents` | Statements: **"June 2026", "May 2026", "April 2026"** — each a `doc()` row whose download opens a ComingSoon "… statement" stub |
| `.settings` | **Appearance** segmented control (System/Light/Dark → `ryze_appearance`); **Language** segmented (English/Shqip → `ryze_lang`); Notifications toggle (local `@State notif`, default true); "About Ryze" → `InfoTextSheet(Legal.disclaimer)`; "Terms & privacy" → `InfoTextSheet(Legal.infoNotice)` |
| `.help` | FAQs (stub), Contact support (stub), **Ask Riz** → opens `RizSheet` |
| `.inbox` | 3 mock notifications: "Account opened" (now), "Security / New sign-in" (1h), "Rewards / 50 points this week" (2d) |

#### Reusable row helpers (in `ProfileDetailView`)

| Helper | Purpose |
|---|---|
| `infoCard(_:)` / `infoRow(_:_:)` | label-left / value-right rows in an `AppCard` |
| `toggleRow(_:_:_:)` | IconTile + label + `Toggle` tinted `Brand.yellow` |
| `stub(_:_:)` | row → `DetailSheet.coming` (ComingSoon) |
| `actionStub(_:_:_:)` | row → custom action |
| `doc(_:)` | statement row with `arrow.down.circle` → ComingSoon stub |
| `msg(_:_:_:)` | inbox notification row |
| `segRow(_:_:)` (extension) | segmented control; selected segment gets `Brand.gold` fill + black text, idle `Brand.elev3` |
| `maskIBAN(_:)` | masks to `XXXX •••• •••• XXXX` |
| `dv()` / `rowDivider()` | hairline divider inset 52pt (clears the 38pt IconTile) |

> Stubs flagged: "Change passcode", "Trusted devices", FAQs, Contact support, all statement downloads → all open a `ComingSoonSheet` placeholder. The Notifications toggle is local `@State` only (not persisted).

---

## Assistant Tab (`AssistantView`, `Sections.swift`)

Full-screen chat copilot "Riz". `ZStack` over `Brand.bg`.

**Header:** `RizOrb(42, glow:false)` + "Riz" (18 bold) + a green `good` status dot + "Online · money copilot" / "Online · kopilot parash"; trailing `square.and.pencil` (clear conversation) shown only when `msgs` non-empty. Hairline divider under header.

**Empty state** (`msgs` empty, not typing): centered glowing `RizOrb(72)`, greeting "Hi {name}, I'm Riz" / "Ç'kemi {name}, unë jam Riz", subtitle, then 4 capability cards (`capCard`), then a privacy line ("Private · encrypted in transit, only minimal data is shared" / SQ) with a `lock.fill`.

**Capability cards (`caps`):**

| Icon | Title (EN / SQ) | Tapped prompt (EN) |
|---|---|---|
| `chart.pie.fill` | My spending / Shpenzimet e mia | How am I spending this month? |
| `star.circle.fill` | RyzePoints / RyzePikë | How do RyzePoints work? |
| `crown.fill` | Best plan for me / Plani më i mirë | Which plan fits me best? |
| `lock.shield.fill` | Is my money safe? / A janë të sigurta? | Is my money safe with Ryze? |

**Conversation state:** user bubbles right-aligned (`Brand.text` fill, `onText` ink, RR20); assistant bubbles left-aligned with `RizOrb(28)`, `Brand.elev2` fill + hairline stroke, rendered via `RizRichText`. A `TypingDots` row shows while awaiting reply. `ScrollViewReader` auto-scrolls to the last message / typing indicator.

**Input bar:** capsule `TextField` ("Ask Riz anything…" / "Pyet Riz çdo gjë…") + a gold circular send button (`arrow.up`, 48pt, dimmed to 0.5 opacity when input is empty/whitespace).

**Send flow (`send`):** trims input; appends the user message (`.snappy`); sets `typing = true`; builds `rizContext()` and calls `await RizService.reply(history:context:)`. On return, falls back to local `Riz.reply(...)` if the live service returns nil, then appends the assistant message. `RizService`/`Riz` are defined elsewhere — the live LLM call is real-code but its backend is out-of-file.

**`rizContext()`** assembles a plain-text profile for the model: reply language, name, plan + earn rate (from `PLANS`), level/tier/points/streak, balance (`bank.totalALL` + EUR account), this-month income/spend, spending-by-category, and savings-goals with percentages.

**Env-var test hooks (flagged as test seams, not user features):**
- `RYZE_RIZ` (set) → seeds a sample spending Q&A conversation.
- `RYZE_ASK` → auto-sends that question on appear (once, via `didAsk`).

---

## Rewards Tab (`RewardsHub`, `Sections.swift`)

`ScreenScroll` with the `TopBar`. Routes via an `RRoute` enum sheet: `.profile`, `.plans`, `.earn`, `.redeem`, `.analytics`, `.search`, `.coming(String)`, `.coupon(String)`.

Section order (numbered as in code comments):

1. **Season hero** (void surface, forced dark) — Eyebrow "Your season"; "Level {li.level}" (28 bold, white gradient) + `tierPill`; right side points counter (`star.circle.fill` bouncing on `game.celebrate`, count with `.numericText()`); `tierTrack` (TIERS progress dots — filled yellow ≤ current, checkmark for completed, ring on current); `ProgressBar(game.li.progress)` + "{needed − intoLevel} XP to Level {level+1}".
2. **Streak / daily check-in** (`AppCard`) — `flame.fill` coral IconTile; "{streak}-day streak"; if `lastCheckIn == today` shows a `good` seal + "Checked in today", else a "Check in"/"Regjistrohu" `PillButton` → `game.dailyCheckIn()`.
3. **Perks marketplace intro** (`AppCard`) — `star.circle.fill` `yellowInk` tile; "{planLabel} · earn as you spend"; subtitle = `currentPlan?.earn ?? "1x RyzePoints · 1 point per 200 L spent"`.
4. **Redeem at stores** — "See all" → `.redeem`; horizontal category chips (Food/Streaming/Shopping/Mobile, colored coral/good/pink/sky) that filter; a list of `CouponTicket`s (first 4 of `GameModel.rewards`, or filtered by `selCat`).
5. **Plan upsell** — if a `nextPlan` exists, a gold `FeaturedCard` "Upgrade to Ryze {n.name}"; else a neutral `AppCard` "You're on {planLabel} · Top tier".
6. **Quests** — "See all" → `.earn`; first 3 unclaimed `game.missions` as `MissionRowView`.
7. **Your squad** (`AppCard`) — squad name/goal title, `progress/goal`, `ProgressBar`, member `Avatar`s overlapping (−8 spacing) + a `plus` button → `game.simulateReferral()`.
8. **Invite & earn** (`AppCard`) — `gift.fill` pink tile, `game.referralCode`, "You both get 200 points", `ShareLink`.
9. **Badges** — 2-column `LazyVGrid` of `game.badges`; earned badges show their icon in yellow, unearned show `lock.fill` and 0.55 opacity.

Local helpers: `tierPill(_:)`, `tierTrack`, `seeAll(_:)`, `couponTicket(_:)` (computes owned/locked/afford and `perkColor`), `perkColor(_:)`, `perkCard(_:)` (an alternative list-style perk card not used in the main flow).

> Env hook (flagged): `RYZE_CAT` pre-selects a reward category; `RYZE_SHEET == "plans"` auto-opens `PlansView` on appear.

---

## Reward Visual Mapping (free functions, `Sections.swift`)

| Function | Behaviour |
|---|---|
| `rewardCategory(_ id:)` | maps reward IDs → category string. `r-coffee/r-kfc/r-glovo`→Food; `r-spotify/r-cinema/r-game`→Streaming; `r-merch/r-fashion`→Shopping; `r-data/r-cashback`→Mobile; default→Food |
| `rewardColor(_ id:)` / `perkColor(_ id:)` | maps reward IDs → accent color (e.g. `r-spotify`→good, `r-coffee`→coral, `r-cinema`→violet, `r-cashback`→yellow, `r-data`→sky, `r-merch`→pink, `r-glovo`→yellow, `r-kfc`→coral, `r-game`→violet, `r-fashion`→pink); default `Brand.yellow`. (Defined twice — once free, once as a `RewardsHub` method — with identical mappings.) |

These confirm the closed reward set: `r-coffee, r-kfc, r-glovo, r-spotify, r-cinema, r-game, r-merch, r-fashion, r-data, r-cashback`.

---

## Coupon & QR Components (`Sections.swift`)

### `CouponTicket`
A perforated ticket (deliberately NOT a Revolut gradient brand card). 96 tall: left 82pt colored stub with the reward `icon`; right area with title, brand, "`{cost} pts`". Trailing state: **Owned** (`checkmark.seal.fill` good) / **locked** (`lock.fill` + tier name when `r.tierMin > tierIndex`) / **Redeem** button (yellow when affordable, disabled `Brand.elev3` when not). The perforation is a dashed vertical `Path` plus two `Brand.bg`-filled notch circles at the stub seam.

### `CouponRedeemedSheet(reward:)`
Redemption result. Generates a local code `RYZE-XXXX-XXXX` (`gen()`, alphabet excludes ambiguous chars) and, on appear, calls `game.redeem(reward.id)` if not already redeemed. Shows the reward icon (gradient tile), title/brand, a QR encoding `ryze://redeem/{id}/{code}` (white card, gold border), the code in a copyable pill (`Clip.copySensitive`, swaps to a `checkmark` when copied), and an instruction that varies by category: Food rewards → "Show this QR at the counter…", others → "Enter this code at checkout…". `PrimaryButton` "Done"/"U krye" dismisses.

### `QRSheet`
"Your Ryze code" — a QR encoding `ryze://pay/{referralCode}` (230pt, white card, gold border) with "@{name} · {referralCode}" beneath. Used as the personal pay/add code.

### `qrImage(_:)`
`CIFilter.qrCodeGenerator()` with correction level `"M"`, scaled ×10, rendered nearest-neighbour (`.interpolation(.none)`). Shared by both QR sheets.

### `InfoTextSheet(title:text:)`
Generic scrollable legal/info reader (`NavigationStack`, inline title, "Done" toolbar). Used for "About Ryze" (`Legal.disclaimer`) and "Terms & privacy" (`Legal.infoNotice`).

---

## Prototype / Mock / Placeholder Inventory (flags)

- App self-identifies as a **prototype** ("Ryze · prototype for Raiffeisen Bank Albania").
- **Hard-coded personal data:** Email `klevi@ryze.al`, Phone `+355 69 123 4567`, DOB `14/03/2004`, Nationality `Albania`, IBAN `AL47 2026 1100 4827`, statement months June/May/April 2026, inbox messages — all mock.
- **ComingSoon stubs:** Change passcode, Trusted devices, FAQs, Contact support, statement downloads.
- **Demo/test seams:** `game.resetDemo()` on Log out; env vars `RYZE_LANG`, `RYZE_RIZ`, `RYZE_ASK`, `RYZE_CAT`, `RYZE_SHEET`.
- **Copy mismatch:** Invite subtitle "2,000 points" vs share/invite-card "200 points".
- **Token doc drift:** `BRANDING.md` says `hairline` = white 8% and Eyebrow tick = `yellow`; code uses white 9%/black 10% and `yellowInk`. Code is authoritative.
- **Out-of-file definitions:** `AppCard`, `FeaturedCard`, `PillButton`, `QuickAction`, `IconTile`, `Avatar`, `Ring`, `StatCard`, `Bar`, `MissionRowView`, `ToastBanner`, `AmountSheet`, `RizRichText`, `ScreenScroll`, the `MainTabView`/tab bar itself, and the entire Home/Cards/Pay roots live in `Ryze/AppViews.swift` (not read for this chapter); their internals are documented from `BRANDING.md` and call sites only.

# Security & Technical Architecture

This chapter documents how Ryze boots, wires its state, persists data, and defends sensitive surfaces on-device. It is faithful to the four implementation files (`RyzeApp.swift`, `AppSecurity.swift`, `Hardening.swift`, `project.yml`) and to the honest posture statement in `SECURITY.md`. Where a control is a nudge, a stub, or fails open by design, that is stated explicitly. `SECURITY.md` itself opens by declaring Ryze "a **hackathon prototype** of a youth banking app" — the spec below does not overclaim beyond what that document states.

### Overview: what the security domain covers

Ryze ships an on-device security posture for a youth banking prototype with four pillars, all client-side (there is no Ryze backend in this build):

1. **App entry & gating** — a single `RootView` that routes between the onboarding flow and the main tabs, plus an environment-variable QA harness.
2. **State model & wiring** — three `ObservableObject` models (`GameModel`, `BankModel`, `OnboardingModel`) injected as `@EnvironmentObject`, with `BankModel` holding a back-reference to `GameModel`.
3. **Persistence** — AES-GCM encrypted snapshots (`SecureStore`) keyed by a 256-bit Keychain key, replacing legacy cleartext `UserDefaults`.
4. **Capture protection, biometric gates, and PII hygiene** — privacy cover, screenshot detection, screen-recording redaction, an opt-in app lock, a biometric reveal gate, IBAN masking, and an auto-expiring clipboard.

> Note on scope: `GameModel`, `BankModel`, and `OnboardingModel` are referenced by `RyzeApp.swift` / `RootView` but their full definitions live in files outside this chapter's source set (e.g. `AppViews.swift`, `Sections.swift`). This chapter documents them only to the extent their fields and methods are invoked in the read files; field-level detail beyond those call sites is out of scope and not invented here.

---

### 1. App entry and root gating

#### 1.1 `RyzeApp` — the `@main` scene

`RyzeApp` (in `RyzeApp.swift`) is the SwiftUI `App` entry point. It owns the four top-level state objects and composes the global security overlays.

| Property | Type | Role |
|---|---|---|
| `game` | `@StateObject GameModel` | Gamification + onboarding flag + persistence (`saveState`), toasts (`notify`) |
| `bank` | `@StateObject BankModel` | Bank data, card reveal flags, persistence (`saveState`) |
| `capture` | `@StateObject CaptureGuard` | Screenshot / screen-capture awareness |
| `lock` | `@StateObject AppLockModel` | Opt-in biometric app lock |
| `scenePhase` | `@Environment(\.scenePhase)` | Drives privacy cover, save-on-background, and lock timing |

The scene body is a `ZStack` with three layers stacked by `zIndex`:

| zIndex | Layer | Shown when |
|---|---|---|
| (base) | `RootView()` + injected environment objects | always |
| 1 | `PrivacyCover()` (`.transition(.opacity)`) | `scenePhase != .active` |
| 2 | `LockScreen(lock:)` (`.transition(.opacity)`) | `lock.locked == true` |

Two `.animation` modifiers drive the overlays: `.easeInOut(duration: 0.2)` keyed on `scenePhase`, and `.easeInOut(duration: 0.2)` keyed on `lock.locked`.

**Wiring performed in `.onAppear`:**
- `bank.game = game` — establishes `BankModel`'s back-reference to `GameModel` so bank actions can award XP / trigger game logic.
- `lock.armOnLaunch()` — arms the lock on cold launch if the user enabled it.

**`.onChange(of: scenePhase)` — leaving `.active` (background / app-switcher):**
1. `game.saveState()` and `bank.saveState()` — persist both snapshots.
2. `bank.revealed = false; bank.virtualRevealed = false` — collapse any revealed PAN/card state. Inline comment: *"never freeze a revealed PAN into the app-switcher snapshot."*
3. `lock.willResign()` — records the resign timestamp for the inactivity-relock grace window.

On returning to `.active`, `lock.didActivate()` runs (re-locks if past the grace window).

**`.onChange(of: capture.screenshotTick)` — a screenshot was taken:**
1. `bank.revealed = false; bank.virtualRevealed = false` — re-mask the card.
2. `game.notify(...)` — show toast `"Screenshot detected — card hidden"` / `"U kap pamja — karta u fsheh"` (Albanian via the `T(en, sq)` localization helper).

#### 1.2 `RootView` — gating and the QA harness

`RootView` resolves which screen to show. It reads two environment variables and one persisted appearance preference.

| Source | Key | Purpose |
|---|---|---|
| `@AppStorage` | `ryze_appearance` (default `"dark"`) | Persisted light/dark/system preference |
| `ProcessInfo` env | `RYZE_VIEW` | QA deep-link: render one screen in isolation |
| `ProcessInfo` env | `RYZE_APPEARANCE` | Overrides `ryze_appearance` at launch for QA |

**Primary gate (production path):** when no `RYZE_VIEW` override matches, `RootView` branches on `game.onboarded`:
- `game.onboarded == true` → `MainTabView()`
- otherwise → `OnboardingFlow()`

This transition is animated with `.animation(.easeInOut, value: game.onboarded)`.

**QA harness (`RYZE_VIEW`):** if the env var is set to a recognized token, `RootView` renders that single screen instead of the normal gate. This is a developer/QA affordance for screenshotting individual surfaces, not a user-reachable feature. The complete token table found in the code:

| `RYZE_VIEW` value | Rendered view |
|---|---|
| `profile` | `ProfileSheet()` |
| `plans` | `PlansView()` |
| `settings` | `NavigationStack { ProfileDetailView(detail: .settings) }` |
| `qr` | `QRSheet()` |
| `analytics` | `AnalyticsView()` |
| `exchange` | `ExchangeView()` |
| `scan` | `ScanPayView()` |
| `split` | `SplitBillView()` |
| `bank` | `BankTransferView()` |
| `redeem` | `RewardsStoreSheet()` |
| `earn` | `EarnSheet()` |
| `search` | `SearchSheet()` |
| `ordercard` | `OrderCardSheet()` |
| `cardlimit` | `CardLimitSheet()` |
| `applepay` | `ApplePaySheet()` |
| `cardstudio` | `CardStudioSheet()` |
| `coupon` | `CouponRedeemedSheet(reward: GameModel.rewards[1])` |
| `vcard` | `ScreenScroll` with two `CardFace`s: virtual `last4: "8842"` (`.midnight`, revealed), and `last4: "4827"` (`.gold`, `customText: "DREAM BIG"`, not revealed); both `name: "Klevi"` |
| `grow` | `GrowView()` |
| `newgoal` | `AddGoalSheet()` |
| `goaldetail` | `NavigationStack { GoalDetailView(goalId: "phone") }` |

The hard-coded demo values in the `vcard` and `coupon` cases (`last4` `8842` / `4827`, name `Klevi`, `GameModel.rewards[1]`, goal id `phone`) are QA fixtures, not production data.

**Global appearance:** `RootView` applies `.fontDesign(.rounded)`, `.monospacedDigit()`, and a `.preferredColorScheme` computed from `RYZE_APPEARANCE ?? ryze_appearance`: `"system"` → `nil` (follow OS), `"light"` → `.light`, anything else → `.dark`.

---

### 2. State model and wiring

State is propagated by SwiftUI environment injection. `RyzeApp` injects four objects (`game`, `bank`, `capture`, `lock`) into `RootView`'s environment; child views consume them via `@EnvironmentObject` / `@ObservedObject`.

| Model | Lifetime | Consumed via | Security-relevant surface (in these files) |
|---|---|---|---|
| `GameModel` | `@StateObject` in `RyzeApp` | `@EnvironmentObject` in `RootView` | `onboarded` (gate), `saveState()`, `notify(_:)`, static `rewards` |
| `BankModel` | `@StateObject` in `RyzeApp` | `@EnvironmentObject` | `game` (back-ref), `revealed`, `virtualRevealed`, `saveState()` |
| `OnboardingModel` | (defined elsewhere) | — | drives `OnboardingFlow()` when `game.onboarded == false` |
| `CaptureGuard` | `@StateObject` in `RyzeApp` | `@EnvironmentObject` | `isCaptured`, `screenshotTick` |
| `AppLockModel` | `@StateObject` in `RyzeApp` (`@MainActor`) | `@ObservedObject` in `LockScreen` | `locked`, lifecycle hooks, `unlock()`, static `confirm(_:)` |

`BankModel.game` is the one explicit cross-model reference, set once in `.onAppear`. The reveal flags `bank.revealed` / `bank.virtualRevealed` are the single source of truth for whether full card data is on screen; they are forcibly reset on backgrounding and on screenshot, ensuring sensitive card state never persists across an app-switch snapshot or survives a capture event.

> `OnboardingModel` is named in the chapter brief; in the read source the onboarding gate is driven by `game.onboarded` and the `OnboardingFlow()` view. A distinct `OnboardingModel` object is not instantiated in `RyzeApp.swift`. Treat the brief's "OnboardingModel" as the onboarding-flow state owned within the onboarding subsystem, which is out of scope for these files.

---

### 3. Persistence — `SecureStore`, `Keychain`, `Clip` (`Hardening.swift`)

`Hardening.swift` provides three enums: a Keychain wrapper, an AES-GCM file store, and an expiring clipboard helper.

#### 3.1 `Keychain` — device-only generic-password items

| Method | Behavior |
|---|---|
| `set(_ data: Data, for key: String) -> Bool` | Deletes any existing item for `key`, then adds with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. Returns `true` on `errSecSuccess`. `@discardableResult`. |
| `get(_ key: String) -> Data?` | Returns the item's data, or `nil` if not found (`kSecMatchLimitOne`). |
| `delete(_ key: String)` | Deletes the generic-password item for `key`. |

All items are `kSecClassGenericPassword`. The accessibility class is **`AfterFirstUnlockThisDeviceOnly`**: readable after the first device unlock per boot, and never migrated to another device or backup.

#### 3.2 `SecureStore` — AES-GCM encrypted on-device store

`SecureStore` replaces cleartext `UserDefaults` for the bank and game snapshots. The inline comment states it is "device-bound by design (blob is unreadable after a restore, which is correct for a re-fetchable financial cache)."

| Element | Value / behavior |
|---|---|
| Key tag | `"ryze.datakey.v1"` |
| Key | 256-bit `SymmetricKey` (`.bits256`), lazily generated and stored in Keychain on first use; reloaded thereafter |
| Cipher | `AES.GCM.seal(...).combined` to encrypt; `AES.GCM.SealedBox` + `AES.GCM.open` to decrypt |
| File location | `applicationSupportDirectory` (created if missing), file named `"<name>.enc"` |
| Write options | `[.atomic, .completeFileProtectionUntilFirstUserAuthentication]` |

| Method | Behavior |
|---|---|
| `key() -> SymmetricKey` (private) | Returns the existing Keychain key, or generates + stores a new 256-bit key |
| `url(_ name:) -> URL` (private) | Resolves / creates the `.enc` file URL under Application Support |
| `save(_ data: Data, _ name: String)` | Seals and writes atomically with file protection; silently no-ops if sealing fails (`guard ... else { return }`) |
| `load(_ name: String) -> Data?` | Reads, opens the sealed box, decrypts; returns `nil` if any step fails |
| `remove(_ name: String)` | Deletes the `.enc` file |

Failure handling is deliberately silent (`try?` throughout): an unreadable or restored blob yields `nil`, which the caller treats as "no cached snapshot" and re-fetches — consistent with the "re-fetchable financial cache" design note.

**Migration:** per `SECURITY.md`, "Legacy cleartext `UserDefaults` blobs are migrated once and deleted." The previous implementation stored snapshots as plaintext `UserDefaults`; the migration code performing the one-time move is invoked by the model `saveState`/load paths (outside these files).

#### 3.3 `Clip` — sensitive, auto-expiring clipboard

| Method | Behavior |
|---|---|
| `copySensitive(_ s: String, seconds: TimeInterval = 60)` | Writes to `UIPasteboard.general` with `.localOnly: true` (never synced via Handoff/Universal Clipboard) and `.expirationDate` set to now + `seconds` (default **60 s**) |

Used for copied reward codes (`SECURITY.md`), so a redeemed code is local-only and self-clears after one minute.

---

### 4. Capture protection (`AppSecurity.swift`)

#### 4.1 `CaptureGuard` — capture awareness

`CaptureGuard` is an `ObservableObject` that tracks two capture conditions via NotificationCenter publishers stored in a Combine `bag`.

| Published property | Initial value | Updated by |
|---|---|---|
| `isCaptured` | `UIScreen.main.isCaptured` | `UIScreen.capturedDidChangeNotification` (delivered on `RunLoop.main`) → re-reads `UIScreen.main.isCaptured` |
| `screenshotTick` | `0` | `UIApplication.userDidTakeScreenshotNotification` → increments by 1 |

`isCaptured` reflects active screen recording or AirPlay/mirroring. `screenshotTick` is a monotonically increasing counter; `RyzeApp` observes changes to it (not its value) to trigger the re-mask + toast.

#### 4.2 `PrivacyCover` — app-switcher snapshot cover

A full-screen `View` rendered whenever `scenePhase != .active`. It fills with `Brand.bg`, centered on the `"RaiffeisenLogo"` image (60×60, rounded-rect clipped, corner radius 17) above the title `"Ryze"` (rounded bold, size 22, `Brand.text`). Its purpose: replace all sensitive UI (balances, cards, KYC) in the iOS multitasking snapshot so nothing sensitive appears in the app switcher.

#### 4.3 `redactWhileCapturing()` — live redaction overlay

`RedactWhileCapturing` is a `ViewModifier` (exposed via the `View.redactWhileCapturing()` extension) that consumes `CaptureGuard` from the environment. When `capture.isCaptured == true`, it overlays the decorated view with a `RoundedRectangle` (corner radius 20, `Brand.elev3`) bearing the label `"Hidden while recording"` / `"Fshehur gjatë regjistrimit"` with the `eye.slash.fill` SF Symbol (size 12 semibold, `Brand.mute`). This is applied to the balance tile and card faces (`SECURITY.md`), redacting them live during a recording or mirror session.

#### 4.4 Capture-protection limits (per `SECURITY.md`)

`SECURITY.md` is explicit that iOS cannot block screenshots app-wide — there is **no public equivalent of Android's `FLAG_SECURE`**. The team evaluated the private `UITextField` secure-canvas trick to blank specific views in screenshots; it proved **inconsistent across the view hierarchy** (blanked one card but not another) and was removed in favor of the reliable detect-+-redact-+-privacy-cover approach. Screenshot **detection fires after** the image is saved, so it is a **nudge + auto-re-mask, not prevention.**

---

### 5. Biometric authentication (`AppSecurity.swift`)

#### 5.1 `AppLockModel` — opt-in app lock

`@MainActor final class AppLockModel: ObservableObject`.

| Member | Value / behavior |
|---|---|
| `locked` (`@Published`) | `false` initially; drives `LockScreen` overlay |
| `lastActive` (private) | Timestamp of last resign; default `Date()` |
| `grace` (private) | `60` seconds inactivity window before relock |
| `enabled` (private, computed) | `UserDefaults.standard.bool(forKey: "ryze_app_lock")` — the opt-in flag set in Settings ▸ Security |
| `armOnLaunch()` | If `enabled`, set `locked = true` (cold-launch gate) |
| `willResign()` | Record `lastActive = Date()` |
| `didActivate()` | If `enabled` **and** more than `grace` (60 s) elapsed since `lastActive`, set `locked = true` |
| `unlock()` (async) | Runs biometric `evaluate(...)`; on success sets `locked = false` with `.easeOut(duration: 0.25)` |
| `confirm(_ reason:)` (static, async) → `Bool` | Step-up auth for a single sensitive action; thin wrapper over `evaluate` |
| `evaluate(_ reason:)` (private static, async) → `Bool` | Core `LAContext` evaluation |

**`evaluate` logic:**
- Builds an `LAContext`; sets `localizedFallbackTitle` to `"Use passcode"` / `"Përdor kodin"`.
- Calls `canEvaluatePolicy(.deviceOwnerAuthentication, error:)`. **If the device has no biometry/passcode enrolled, this returns `false` and `evaluate` returns `true` (fails OPEN).** The code comment: *"Fails OPEN when no biometry/passcode is enrolled (e.g. a bare simulator) so a demo is never bricked; on real hardware it prompts."*
- Otherwise runs `evaluatePolicy(.deviceOwnerAuthentication, localizedReason:)`; returns the result, or `false` on throw.

The unlock reason string is `"Unlock Ryze"` / `"Shkyç Ryze"`.

#### 5.2 `LockScreen`

Full-screen dark overlay (`Brand.void` background, forced `.colorScheme(.dark)`). Contents: the `"RaiffeisenLogo"` (72×72, rounded-rect radius 20), title `"Ryze is locked"` / `"Ryze është kyçur"` (size 20 bold, white), and a yellow capsule button (`Brand.yellow`, 50pt tall) labeled `"Unlock"` / `"Shkyç"` with the `faceid` SF Symbol. The button calls `await lock.unlock()`; additionally `.task { await lock.unlock() }` auto-prompts on appearance so Face ID fires immediately without a tap.

#### 5.3 Biometric reveal gate

Per `SECURITY.md`, showing the full PAN / expiry / CVV requires Face ID / passcode (`LAContext`, `.deviceOwnerAuthentication`) — this is the `AppLockModel.confirm(_:)` step-up path. **Hiding never requires auth.** The reveal toggles `bank.revealed` / `bank.virtualRevealed`, which the entry-point logic resets on background and on screenshot.

#### 5.4 Biometric limits (per `SECURITY.md`)

`SECURITY.md` states plainly: "**Biometrics are intent confirmation, not a security boundary.**" They stop shoulder-surfing and casual access; real authentication requires the backend to enforce SCA / 3-D Secure. On a device with no passcode/biometry the gates **fail open by design** so a demo is never bricked. There are also **no jailbreak / anti-debug checks** — described as defeatable, advisory-only, and risking demo breakage, hence out of scope.

---

### 6. PII hygiene

| Control | Mechanism | File |
|---|---|---|
| IBAN masking | Masked by default with reveal-on-tap | `Sections.swift` (per `SECURITY.md`) |
| Reward-code copy | Auto-expiring, local-only pasteboard, 60 s (`Clip.copySensitive`) | `Hardening.swift` |
| Card reveal lifecycle | `revealed`/`virtualRevealed` reset on background + on screenshot | `RyzeApp.swift` |
| Transport security | HTTPS-only under Apple's **default ATS**; no sensitive values logged | (App Transport Security default) |

No custom ATS exception keys are declared; the app relies on Apple's default ATS posture (HTTPS-only, modern TLS).

---

### 7. Project configuration (`project.yml`)

The Xcode project is generated from `project.yml` (XcodeGen). It defines a single application target.

| Setting | Value |
|---|---|
| Project name | `Ryze` |
| `bundleIdPrefix` | `al.raiffeisen` |
| Deployment target | iOS **17.0** |
| `createIntermediateGroups` | `true` |
| Target `Ryze` type / platform | `application` / `iOS` |
| Sources | `Ryze` |
| `PRODUCT_BUNDLE_IDENTIFIER` | **`al.raiffeisen.ryze`** |
| `PRODUCT_NAME` | `Ryze` |
| `MARKETING_VERSION` | `1.0` |
| `CURRENT_PROJECT_VERSION` | `1` |
| `SWIFT_VERSION` | `5.0` |
| `TARGETED_DEVICE_FAMILY` | `1` (iPhone only) |
| `GENERATE_INFOPLIST_FILE` | `YES` (no checked-in `Info.plist`; keys set inline) |
| `INFOPLIST_KEY_NSFaceIDUsageDescription` | `"Ryze uses Face ID to unlock the app and reveal your card details."` |
| `INFOPLIST_KEY_UILaunchScreen_Generation` | `YES` |
| `INFOPLIST_KEY_UIStatusBarStyle` | `UIStatusBarStyleLightContent` |
| `ASSETCATALOG_COMPILER_APPICON_NAME` | `AppIcon` |
| `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME` | `AccentColor` |

**Capabilities / usage descriptions:** the only privacy usage description declared is `NSFaceIDUsageDescription`, which underpins both the app-lock gate and the card-reveal gate. No other entitlements (push, App Attest/DeviceCheck, keychain sharing, App Groups) are configured in this file. No QA env hooks (`RYZE_VIEW` / `RYZE_APPEARANCE`) appear in `project.yml`; those are injected at run/launch time (e.g. scheme environment or launch arguments), not baked into the build settings.

---

### 8. Known limitations and production roadmap (per `SECURITY.md`)

`SECURITY.md` frames overclaiming as "itself a failure" for a banking product and enumerates the gaps. These are reproduced honestly, not minimized.

#### 8.1 Known limitations (deliberate, hackathon scope)

| Limitation | Detail |
|---|---|
| No app-wide screenshot block | iOS has no public `FLAG_SECURE`; the private secure-canvas trick was inconsistent and removed. Detection fires **after** capture — nudge + auto-re-mask, not prevention. |
| Bundled LLM key | The **Riz** LLM API key is bundled in `RizSecret.swift` (**gitignored, never committed**). A key shipped in any binary is extractable via `strings` on the `.ipa` — treat as compromised and rotate. The real fix already in-repo: **`riz-proxy/`**, a Cloudflare Worker that holds the key server-side. |
| Biometrics ≠ security boundary | Intent confirmation only; real auth requires backend SCA / 3-D Secure. Gates **fail open** with no passcode/biometry. |
| No jailbreak / anti-debug checks | Defeatable, advisory-only, risk bricking the demo — out of scope. |
| At-rest encryption caveat | OS file protection only protects at rest if the device has a passcode; the **app-level AES-GCM layer is what makes it robust regardless.** |

#### 8.2 Flagged placeholders / "next" items

- **`RizSecret.swift`** — a gitignored on-device secret; explicitly flagged as compromised-by-design and slated for removal in production.
- **`riz-proxy/`** — the intended replacement (Cloudflare Worker), present in-repo but the on-device key path is still what ships in this build.
- **Legacy `UserDefaults` snapshots** — superseded by `SecureStore`; migrated-once-then-deleted. Pre-migration installs still carry the legacy path until first run after upgrade.
- The `vcard` / `coupon` QA routes in `RootView` use hard-coded demo card numbers, names, and reward indices — fixtures, not production data.

#### 8.3 Production roadmap (verbatim scope from `SECURITY.md`)

Server-held secrets + App Attest · backend-enforced SCA on payments · device-bound session tokens in Keychain · certificate pinning at a stable gateway · de-identified/minimised LLM context · scoped CORS + auth + rate-limit on the proxy.

---

### 9. End-to-end security flows

**Cold launch (lock enabled):** `RyzeApp` inits models → `.onAppear` sets `bank.game = game`, calls `lock.armOnLaunch()` → if `ryze_app_lock` is set, `lock.locked = true` → `LockScreen` (zIndex 2) overlays everything and `.task` auto-invokes `unlock()` → on biometric success (or fail-open with no enrollment) `locked = false`, overlay fades.

**Background / app-switch:** `scenePhase != .active` → `PrivacyCover` (zIndex 1) appears; `game.saveState()` + `bank.saveState()` persist via `SecureStore`; both reveal flags reset; `lock.willResign()` stamps `lastActive`. On return, if `> 60 s` elapsed and lock is enabled, `lock.didActivate()` re-locks.

**Screenshot:** `userDidTakeScreenshotNotification` → `CaptureGuard.screenshotTick += 1` → `RyzeApp.onChange` resets `revealed`/`virtualRevealed` and fires the `"Screenshot detected — card hidden"` toast. The screenshot already on disk still contains whatever was visible at capture time (detection is post-hoc).

**Active screen recording / mirror:** `capturedDidChangeNotification` → `CaptureGuard.isCaptured = true` → every surface decorated with `redactWhileCapturing()` shows the "Hidden while recording" overlay for the duration of the capture.

**Reveal full card:** user taps reveal → step-up `AppLockModel.confirm("…")` runs `.deviceOwnerAuthentication` → on success the view sets `bank.revealed` / `bank.virtualRevealed = true`; any background, screenshot, or screen-record event tears the reveal back down.

**Copy reward code:** `Clip.copySensitive(code)` writes a local-only pasteboard item with a 60-second expiration; it never leaves the device and self-clears.

# Roadmap — What's Next

Ryze is a prototype with a deliberate production path. The near-term roadmap, drawn from the project's own submission notes, security posture, and engineering follow-ups:

### Banking & payments
- **Real Raiffeisen API integration** — replace the in-memory `BankModel` mock with live accounts, cards, and payment rails.
- **Biometric step-up on payments** — Face ID / passcode confirmation before a transfer, backed by server-enforced **SCA / 3-D Secure** (biometrics today are intent confirmation, not a security boundary).
- **Apple Pay** provisioning for cards.
- **Persistence & sync** beyond the local encrypted snapshot.

### Riz (AI coach)
- Ship **no on-device API key**; route every call through the `riz-proxy` Cloudflare Worker, gated by **App Attest / DeviceCheck**.
- **De-identified / minimised LLM context** — send the model only what a question needs.
- Scoped CORS + auth + rate-limiting on the proxy.

### Engagement
- **Push notifications** for streaks, missions, money received, and reward drops.
- Deeper redemption (live partner coupon inventory and fulfilment).

### Youth & compliance
- **Parent / guardian view** for under-18 users.
- **Legal review** — the in-app disclosures are PROTOTYPE copy and require Raiffeisen legal sign-off.

### Security hardening (production)
- Server-held secrets + App Attest · backend-enforced SCA on payments · device-bound session tokens in Keychain · certificate pinning at a stable gateway · scoped, authenticated, rate-limited proxy.

---

# Appendix A — Demo & QA Hooks

The app seeds a demo user ("Klevi") and reads `RYZE_*` environment variables (or `SIMCTL_CHILD_RYZE_*` via `simctl`) so a judge can deep-link straight to any screen.

| Variable | Values | Effect |
|---|---|---|
| `RYZE_HOME` | `1` | Skip onboarding, open the app at Home |
| `RYZE_TAB` | `0`–`4` | Open a tab: 0 Home · 1 Cards · 2 Pay · 3 Riz · 4 Rewards |
| `RYZE_SHEET` | `profile` \| `plans` \| `grow` | Present a sheet on launch |
| `RYZE_VIEW` | `profile` \| `plans` | Open a full view |
| `RYZE_THREAD` | `<contactId>` | Open a specific Pay chat thread |
| `RYZE_ASK` | free text | Send a question to Riz on launch |
| `RYZE_SCROLLBOTTOM` | `1` | Scroll the current screen to the bottom |
| `RYZE_LANG` | `en` \| `sq` | Force locale |
| `RYZE_APPEARANCE` | `dark` \| `light` | Force theme |

**Example — jump into Riz with a live question:**
```bash
SIMCTL_CHILD_RYZE_HOME=1 SIMCTL_CHILD_RYZE_TAB=3 \
  SIMCTL_CHILD_RYZE_ASK="How am I spending this month?" \
  xcrun simctl launch booted al.raiffeisen.ryze
```

---

# Appendix B — Repository Layout & Build

| Path | What |
|---|---|
| `ryze-ios/` | **The product** — native SwiftUI app (iOS 17+). |
| `ryze-ios/Ryze/` | App sources (models, views, sections, theme, security). |
| `ryze-ios/riz-proxy/` | Cloudflare Worker that holds the Riz LLM key server-side. |
| `ryze-ios/BRANDING.md` | Design system reference. |
| `ryze-ios/SECURITY.md` | Honest security posture. |
| `ryze/` | Earlier React Native / Expo reference implementation. |
| `ryze-app-screenshots/` | Screenshots of every app section (EN + dark). |
| `ryze-video/` | Demo-video + pitch-deck pipeline (Remotion). |
| `ryze-deck.pdf` | Pitch deck. |

**Build & run (iOS):** requires Xcode 16+ and an iOS 17+ simulator.
```bash
cd ryze-ios
xcodegen generate          # generates Ryze.xcodeproj from project.yml
open Ryze.xcodeproj         # run on an iPhone simulator (Cmd+R)
```

---

# Appendix C — Glossary

| Term | Meaning |
|---|---|
| **Riz** | The in-app AI money coach (the assistant persona). |
| **RyzePoints** | The reward currency earned through good financial behaviour; spent in the points store. |
| **Tier** | A status level (e.g. Rookie → Saver → Pro → Elite) driven by XP. |
| **Squad** | A user's crew; powers the shared squad goal and social splits. |
| **Round-up** | Spare-change rounding of a purchase, swept into a savings goal. |
| **Banana Yellow** | The single scarce Raiffeisen-yellow brand stamp (`#F8D01F`). |
| **KYC** | Know Your Customer — the online identity-verification onboarding. |
| **SCA / 3-D Secure** | Strong Customer Authentication; regulated payment auth (roadmap). |
| **Money bubble** | A payment rendered as a chat bubble in a Pay thread. |
| **Card Studio** | The card-personalisation surface (colour + custom print text). |

---

*Ryze — Product Specification · Team PentaByte · JunctionX Tirana 2026. This document describes a hackathon prototype; sections marked stub/mock/roadmap are not production-ready and the legal and security controls require Raiffeisen review before any real-money use.*
