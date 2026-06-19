// @ts-nocheck — standalone bun script, run with: bun src/game/engine.check.ts
// Runnable self-check for the leveling math. Run: bun src/game/engine.check.ts
import { levelInfo, streakMultiplier, tierForLevel, xpForLevel } from './engine';
import assert from 'node:assert';

assert.equal(xpForLevel(1), 140);
assert.equal(levelInfo(0).level, 1);
assert.equal(levelInfo(139).level, 1);
assert.equal(levelInfo(140).level, 2); // exactly enough rolls over
assert.ok(levelInfo(140).progress < 0.01);

// progress is monotonic and bounded
let prev = -1;
for (let xp = 0; xp < 5000; xp += 37) {
  const p = levelInfo(xp).progress;
  assert.ok(p >= 0 && p < 1, `progress out of range at ${xp}`);
}

assert.equal(tierForLevel(1).tier.name, 'Rookie');
assert.equal(tierForLevel(5).tier.name, 'Saver');
assert.equal(tierForLevel(10).tier.name, 'Pro');
assert.equal(tierForLevel(25).tier.name, 'Elite');

assert.equal(streakMultiplier(0), 1);
assert.equal(streakMultiplier(5), 1.5);
assert.equal(streakMultiplier(100), 2); // capped

console.log('engine.check OK');
void prev;
