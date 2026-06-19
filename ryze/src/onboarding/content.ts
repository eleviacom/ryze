// The full onboarding flow content: value carousel + KYC steps. Single source of
// truth for the UI and the Riz buddy (per-step "why"). Copy from the verified spec.
import { CONSENTS } from '@/onboarding/legal';
import { consentsSatisfied, isValidEmail, isValidOtp, isValidPhone, validateAge } from '@/onboarding/machine';

export type IllustrationKey =
  | 'coins' | 'phone' | 'orbit' | 'shield' | 'idcard' | 'liveness' | 'bell' | 'seal';

export type FieldType = 'tel' | 'email' | 'text' | 'date' | 'country' | 'select' | 'toggle';
export type FieldDef = {
  key: string; label: string; type: FieldType;
  placeholder?: string; options?: string[]; optional?: boolean; conditional?: 'taxIdNeeded';
};

export type StepKind = 'otp' | 'intro' | 'capture' | 'liveness' | 'form' | 'consents' | 'permission';
export type KycStep = {
  id: string; kind: StepKind; title: string; body: string; why?: string;
  fields?: FieldDef[]; cta: string; secondaryCta?: string;
  illustration?: IllustrationKey; otpChannel?: 'phone' | 'email';
};

export type ValueSlide = { id: string; title: string; body: string; cta: string; illustration: IllustrationKey };

export const VALUE_SLIDES: ValueSlide[] = [
  { id: 'slide-welcome', illustration: 'coins', cta: 'Continue',
    title: 'Money that finally gets you',
    body: 'Ryze is the Raiffeisen account built for your twenties. Spend, save, and level up — all in one place that actually feels like yours.' },
  { id: 'slide-open', illustration: 'phone', cta: 'Continue',
    title: 'Open it in minutes, 100% online',
    body: 'Not a Raiffeisen customer yet? No branch, no paperwork, no fees to open. Just your ID and a quick video check — done from your couch.' },
  { id: 'slide-belong', illustration: 'orbit', cta: 'Get started',
    title: 'Do more, together',
    body: 'Free instant payments, real-time exchange, save while you spend, and rewards for inviting your crew. The more you play, the more you belong.' },
];

const COUNTRIES = ['Albania', 'Kosovo', 'North Macedonia', 'Italy', 'Greece', 'Other'];
const OCCUPATIONS = ['Student', 'Employed', 'Self-employed', 'Unemployed', 'Other'];
const SOURCES = ['Salary', 'Family support', 'Scholarship', 'Savings', 'Other'];
const INFLOWS = ['Under 30,000 ALL', '30,000–100,000 ALL', 'Over 100,000 ALL'];

export const KYC_STEPS: KycStep[] = [
  { id: 'kyc-phone', kind: 'form', illustration: undefined, cta: 'Send code',
    title: "What's your number?",
    body: "We'll text you a code to confirm it's really you. Your phone keeps your account secure — we never use it for marketing without your say-so.",
    why: 'We verify your phone so only you can reach the account and so we can contact you securely. Albania’s code is +355.',
    fields: [{ key: 'phone', label: 'Phone number', type: 'tel', placeholder: '69 123 4567' }] },

  { id: 'kyc-phone-otp', kind: 'otp', otpChannel: 'phone', cta: 'Verify',
    title: 'Enter your code',
    body: 'We sent a 6-digit code to your phone. Pop it in below — and keep it private. Raiffeisen staff will never ask for it, and neither will Riz.',
    why: 'The one-time code proves the phone is yours. Never share it with anyone, including us.' },

  { id: 'kyc-email', kind: 'form', cta: 'Send code',
    title: 'And your email?',
    body: "This is where we'll send your statements and account documents — so make sure it's one you actually check.",
    why: 'Your email receives statements, confirmations and account documents. We verify it the same quick way as your phone.',
    fields: [{ key: 'email', label: 'Email', type: 'email', placeholder: 'you@email.com' }] },

  { id: 'kyc-email-otp', kind: 'otp', otpChannel: 'email', cta: 'Verify',
    title: 'Confirm your email',
    body: "We sent a 6-digit code to your inbox. Check spam if it's hiding.",
    why: 'The code confirms the inbox is yours.' },

  { id: 'kyc-identity-intro', kind: 'intro', illustration: 'shield', cta: "I'm ready", secondaryCta: "Don't have an identity card?",
    title: 'Now, the easy part',
    body: "Two quick steps and we'll confirm your identity:\n\n1.  Take a photo of your ID card\n2.  A 5-second video check — automatic, no human watching.",
    why: 'By law a bank must confirm who you are before opening an account — this is called KYC, “Know Your Customer”. No person watches the video live.' },

  { id: 'kyc-id-capture', kind: 'capture', illustration: 'idcard', cta: 'Use these photos',
    title: 'Scan your ID card',
    body: "Hold your Albanian ID inside the frame. We'll read it automatically — front, then back. No typing.",
    why: 'A clear photo of your ID lets us read your legal name, date of birth and ID number — the details a regulated account requires (AML, Law 9917/2008).',
    fields: [{ key: 'idDocumentType', label: 'Document type', type: 'select', options: ['Albanian ID card', 'Passport', 'Residence permit'] }] },

  { id: 'kyc-selfie-liveness', kind: 'liveness', illustration: 'liveness', cta: 'Continue',
    title: 'Quick video check',
    body: "Look at the camera and follow the prompts. It takes about five seconds and confirms you're a real person — not a photo. It's fully automated; no human reviews your video.",
    why: 'The selfie-video confirms you’re a live person and match your ID — it stops anyone else opening an account in your name. Fully automatic.' },

  { id: 'kyc-name', kind: 'form', cta: 'Looks right',
    title: "Let's confirm your name",
    body: "We pulled this from your ID. Just check it matches exactly — it's the name on your account and card.",
    why: 'Your account and card are issued in your legal name, exactly as on your ID.',
    fields: [
      { key: 'firstName', label: 'First name', type: 'text', placeholder: 'First name' },
      { key: 'lastName', label: 'Last name', type: 'text', placeholder: 'Last name' },
    ] },

  { id: 'kyc-dob', kind: 'form', cta: 'Confirm',
    title: 'Your date of birth',
    body: "We pulled this from your ID — just confirm it's correct. You need to be at least 18 to open this account on your own.",
    why: 'We confirm you’re 18+ — the age of full legal capacity in Albania (Civil Code Art. 6) — and Ryze is built for ages 18–25.',
    fields: [{ key: 'dob', label: 'Date of birth', type: 'date', placeholder: 'DD/MM/YYYY' }] },

  { id: 'kyc-place-nationality', kind: 'form', cta: 'Continue',
    title: 'Where are you from?',
    body: 'Your nationality and place of birth, as on your ID. By law the Bank records this for every account holder.',
    why: 'Nationality and place of birth are part of the identity record AML law requires.',
    fields: [
      { key: 'nationality', label: 'Nationality', type: 'country', options: COUNTRIES },
      { key: 'countryOfBirth', label: 'Country of birth', type: 'country', options: COUNTRIES },
      { key: 'placeOfBirth', label: 'Place of birth', type: 'text', placeholder: 'e.g. Tirana' },
    ] },

  { id: 'kyc-address', kind: 'form', cta: 'Continue',
    title: 'Where do you live?',
    body: "Your current home address. AML law requires it, and we'll ship your card here.",
    why: 'A residential address is required by AML law and is where your card is delivered.',
    fields: [
      { key: 'addressStreet', label: 'Street and number', type: 'text', placeholder: 'Rruga e Durrësit 12' },
      { key: 'addressCity', label: 'City', type: 'text', placeholder: 'Tirana' },
      { key: 'addressPostalCode', label: 'Postal code', type: 'text', placeholder: '1001', optional: true },
      { key: 'addressCountry', label: 'Country', type: 'country', options: COUNTRIES },
    ] },

  { id: 'kyc-tax-pep', kind: 'form', cta: 'Continue',
    title: 'A couple of quick declarations',
    body: "Two things every bank in Albania has to ask. For most young people the answers are simple — honest answers keep your account compliant.",
    why: 'Banks must record where you pay tax (CRS, Law 4/2020) and whether you hold high public office (PEP, AML). For almost all youth the answers are Albania and No.',
    fields: [
      { key: 'taxResidency', label: 'Country of tax residence', type: 'country', options: COUNTRIES },
      { key: 'taxId', label: 'Tax ID (personal NID)', type: 'text', placeholder: 'Your personal ID number', conditional: 'taxIdNeeded' },
      { key: 'usTaxPerson', label: 'Are you a US tax person? (FATCA)', type: 'toggle' },
      { key: 'pep', label: 'Are you a Politically Exposed Person?', type: 'toggle' },
    ] },

  { id: 'kyc-occupation-funds', kind: 'form', cta: 'Continue',
    title: 'What do you do?',
    body: "Last set of questions — this tells us how you'll mostly use your account. As a youth account, 'student' is totally normal here.",
    why: 'A rough picture of your activity is part of the bank’s AML risk profile. There are no wrong answers.',
    fields: [
      { key: 'occupation', label: 'Occupation', type: 'select', options: OCCUPATIONS },
      { key: 'employerOrSchool', label: 'Employer or school', type: 'text', placeholder: 'e.g. University of Tirana', optional: true },
      { key: 'sourceOfFunds', label: 'Main source of funds', type: 'select', options: SOURCES },
      { key: 'expectedInflow', label: 'Expected money in per month', type: 'select', options: INFLOWS },
    ] },

  { id: 'kyc-consents', kind: 'consents', cta: 'Agree and open my account',
    title: 'Almost done — the agreements',
    body: 'Have a read and tick what applies. The agreements below are required to open your account; marketing is your choice.',
    why: 'These consents are how a regulated bank records your agreement. The first six are required by law to open the account; the last two are optional.' },

  { id: 'kyc-notifications', kind: 'permission', illustration: 'bell', cta: 'I want to be notified', secondaryCta: 'Maybe later',
    title: 'Stay one step ahead',
    body: "Turn on notifications and we'll ping you for security codes, instant-payment alerts, streaks, and rewards. You stay in control — change it anytime in Settings.",
    why: 'Alerts let you spot any sign-in or activity instantly — the easiest way to catch something odd early. It’s optional.' },
];

export const SUCCESS = {
  title: 'Welcome to Ryze',
  body: 'Your Raiffeisen account is open and ready. Your card is on its way, and your first quests are waiting. Let’s get you to level one — tap in and start playing.',
  cta: 'Start playing',
};

export type Draft = Record<string, string>;
export type Flags = { idFront?: boolean; idBack?: boolean; liveness?: boolean };
export type Toggles = Record<string, boolean>;

/** Does the current step have everything it needs to advance? Pure. */
export function stepValid(
  step: KycStep,
  s: { draft: Draft; flags: Flags; otp: Record<string, string>; consents: Record<string, boolean>; toggles: Toggles },
): boolean {
  switch (step.kind) {
    case 'intro':
    case 'permission':
      return true;
    case 'otp':
      return isValidOtp(s.otp[step.otpChannel ?? 'phone'] ?? '');
    case 'capture':
      return !!(s.flags.idFront && s.flags.idBack);
    case 'liveness':
      return !!s.flags.liveness;
    case 'consents':
      return consentsSatisfied(s.consents);
    case 'form':
      return (step.fields ?? []).every((f) => {
        if (f.optional) return true;
        if (f.type === 'toggle') return true; // a No answer is valid
        const v = (s.draft[f.key] ?? '').trim();
        if (f.conditional === 'taxIdNeeded') {
          const needed = (s.draft.taxResidency && s.draft.taxResidency !== 'Albania') || s.toggles.usTaxPerson;
          return needed ? v.length > 0 : true;
        }
        if (f.type === 'tel') return isValidPhone(v);
        if (f.type === 'email') return isValidEmail(v);
        if (f.type === 'date') return validateAge(v).reason !== 'invalid' && v.length === 10;
        return v.length > 0;
      });
    default:
      return true;
  }
}
