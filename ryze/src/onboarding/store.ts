// Onboarding view-model. Drives the value carousel + KYC flow. Transient by design:
// OTP codes, ID images and tokens are NEVER persisted.
import { create } from 'zustand';

import { Draft, Flags, KYC_STEPS, Toggles, stepValid } from '@/onboarding/content';
import { validateAge } from '@/onboarding/machine';
import { mockClient } from '@/onboarding/api';
import { useGame } from '@/game/store';

type Phase = 'value' | 'kyc' | 'success';
type AgeBlock = { reason: 'too_young' | 'invalid' } | null;

type State = {
  phase: Phase;
  slideIndex: number;
  stepIndex: number;
  draft: Draft;
  toggles: Toggles;
  otp: Record<string, string>;
  flags: Flags;
  consents: Record<string, boolean>;
  ageBlock: AgeBlock;
  submitting: boolean;
};

type Actions = {
  setSlide: (i: number) => void;
  nextSlide: () => void;
  setField: (key: string, value: string) => void;
  setToggle: (key: string, value: boolean) => void;
  setOtp: (channel: string, value: string) => void;
  setConsent: (id: string, value: boolean) => void;
  markFlag: (flag: keyof Flags) => void;
  next: () => Promise<void>;
  back: () => void;
  reset: () => void;
};

const seed = (): State => ({
  phase: 'value', slideIndex: 0, stepIndex: 0,
  draft: { idDocumentType: 'Albanian ID card', nationality: 'Albania', countryOfBirth: 'Albania', addressCountry: 'Albania', taxResidency: 'Albania' },
  toggles: { usTaxPerson: false, pep: false },
  otp: {}, flags: {}, consents: {}, ageBlock: null, submitting: false,
});

export const useOnboarding = create<State & Actions>((set, get) => ({
  ...seed(),

  setSlide: (i) => set({ slideIndex: i }),
  nextSlide: () => set((s) => (s.slideIndex < 2 ? { slideIndex: s.slideIndex + 1 } : { phase: 'kyc' })),
  setField: (key, value) => set((s) => ({ draft: { ...s.draft, [key]: value }, ageBlock: key === 'dob' ? null : s.ageBlock })),
  setToggle: (key, value) => set((s) => ({ toggles: { ...s.toggles, [key]: value } })),
  setOtp: (channel, value) => set((s) => ({ otp: { ...s.otp, [channel]: value } })),
  setConsent: (id, value) => set((s) => ({ consents: { ...s.consents, [id]: value } })),
  markFlag: (flag) => set((s) => ({ flags: { ...s.flags, [flag]: true } })),

  next: async () => {
    const s = get();
    const step = KYC_STEPS[s.stepIndex];
    if (!stepValid(step, s)) return;

    // Hard age gate on DOB (18+). Under-18 is redirected, not advanced.
    if (step.id === 'kyc-dob') {
      const v = validateAge(s.draft.dob ?? '');
      if (v.reason === 'invalid') { set({ ageBlock: { reason: 'invalid' } }); return; }
      if (v.reason === 'too_young') { set({ ageBlock: { reason: 'too_young' } }); return; }
    }

    if (s.stepIndex < KYC_STEPS.length - 1) { set({ stepIndex: s.stepIndex + 1 }); return; }

    // Last step -> submit application.
    set({ submitting: true });
    await mockClient.submitApplication({ draft: s.draft, toggles: s.toggles, consents: s.consents });
    useGame.getState().setKycVerified(s.draft.firstName || s.draft.lastName ? `${s.draft.firstName ?? ''}`.trim() : undefined);
    set({ submitting: false, phase: 'success' });
  },

  back: () => set((s) => {
    if (s.phase === 'kyc' && s.stepIndex > 0) return { stepIndex: s.stepIndex - 1, ageBlock: null };
    if (s.phase === 'kyc') return { phase: 'value', slideIndex: 2 };
    return {};
  }),

  reset: () => set(seed()),
}));
