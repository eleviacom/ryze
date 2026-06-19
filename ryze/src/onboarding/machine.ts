// Pure onboarding/KYC logic: age gate, field + consent validation, step gating.
// No React, no I/O — covered by machine.check.ts.
import { CONSENTS } from '@/onboarding/legal';

/** Age in whole years from a DD/MM/YYYY string. Returns NaN if unparseable. */
export function ageFromDob(dob: string, now: Date = new Date()): number {
  const m = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(dob.trim());
  if (!m) return NaN;
  const [, dd, mm, yyyy] = m;
  const d = Number(dd), mo = Number(mm), y = Number(yyyy);
  if (mo < 1 || mo > 12 || d < 1 || d > 31) return NaN;
  let age = now.getFullYear() - y;
  const beforeBirthday = now.getMonth() + 1 < mo || (now.getMonth() + 1 === mo && now.getDate() < d);
  if (beforeBirthday) age -= 1;
  return age;
}

export type AgeVerdict = { ok: boolean; age: number; reason?: 'too_young' | 'too_old' | 'invalid' };

/** Ryze is 18–25. Under-18 is redirected (not rejected); >25 is informational. */
export function validateAge(dob: string, now: Date = new Date()): AgeVerdict {
  const age = ageFromDob(dob, now);
  if (Number.isNaN(age) || age < 0 || age > 120) return { ok: false, age, reason: 'invalid' };
  if (age < 18) return { ok: false, age, reason: 'too_young' };
  if (age > 25) return { ok: false, age, reason: 'too_old' }; // eligible elsewhere; Ryze targets 18–25
  return { ok: true, age };
}

export const isValidPhone = (s: string) => /^\d{6,12}$/.test(s.replace(/\s/g, ''));
export const isValidEmail = (s: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s.trim());
export const isValidOtp = (s: string) => /^\d{6}$/.test(s);

/** All mandatory consents must be ticked to open the account. */
export function consentsSatisfied(checked: Record<string, boolean>): boolean {
  return CONSENTS.filter((c) => c.mandatory).every((c) => checked[c.id]);
}
