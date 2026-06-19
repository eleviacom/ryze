// Onboarding data layer behind a DI seam (mirrors src/game/ai.ts).
// The hackathon demo runs on MOCK so it works offline; a real BFF client swaps in later.
import { Draft, Toggles } from '@/onboarding/content';

export type ApplicationPayload = { draft: Draft; toggles: Toggles; consents: Record<string, boolean> };
export type OnboardingClient = {
  sendOtp: (channel: 'phone' | 'email', to: string) => Promise<void>;
  verifyOtp: (channel: 'phone' | 'email', code: string) => Promise<boolean>;
  submitApplication: (p: ApplicationPayload) => Promise<{ accountId: string; kycStatus: 'verified' }>;
};

// ponytail: mock now; the real client POSTs to the BFF (/onboarding/*) later.
export const mockClient: OnboardingClient = {
  sendOtp: async () => {},
  verifyOtp: async (_c, code) => /^\d{6}$/.test(code), // any 6 digits pass in the demo
  submitApplication: async () => ({ accountId: 'AL' + '47' + '2026' + '0001', kycStatus: 'verified' }),
};
