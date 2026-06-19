// @ts-nocheck — standalone bun script: bun src/onboarding/machine.check.ts
import assert from 'node:assert';
import { ageFromDob, validateAge, isValidEmail, isValidOtp, isValidPhone, consentsSatisfied } from './machine';
import { CONSENTS } from './legal';

const now = new Date('2026-06-19T00:00:00Z');
assert.equal(ageFromDob('19/06/2006', now), 20);
assert.equal(ageFromDob('20/06/2006', now), 19); // birthday not yet reached
assert.equal(ageFromDob('19/06/2008', now), 18);
assert.ok(Number.isNaN(ageFromDob('bad', now)));

assert.equal(validateAge('19/06/2008', now).ok, true);
assert.equal(validateAge('19/06/2009', now).reason, 'too_young'); // 17
assert.equal(validateAge('19/06/1995', now).reason, 'too_old');   // 31
assert.equal(validateAge('99/99/9999', now).reason, 'invalid');

assert.ok(isValidPhone('69 123 4567'));
assert.ok(!isValidPhone('12'));
assert.ok(isValidEmail('a@b.co'));
assert.ok(!isValidEmail('nope'));
assert.ok(isValidOtp('123456'));
assert.ok(!isValidOtp('12345'));

const mand = Object.fromEntries(CONSENTS.filter(c => c.mandatory).map(c => [c.id, true]));
assert.equal(consentsSatisfied(mand), true);
delete mand[CONSENTS.find(c => c.mandatory).id];
assert.equal(consentsSatisfied(mand), false);

console.log('machine.check OK');
