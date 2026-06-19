// Pure leveling + tier math. No state, no I/O — trivially testable.
// XP is the progression spine (status); coins are spendable currency.

/** XP required to advance FROM `level` to `level+1`. Grows linearly. */
export function xpForLevel(level: number): number {
  return 80 + level * 60;
}

export type LevelInfo = {
  level: number;
  intoLevel: number; // xp earned inside the current level
  needed: number; // xp needed to finish the current level
  progress: number; // 0..1
};

/** Resolve a total XP figure into a level + progress to the next one. */
export function levelInfo(totalXp: number): LevelInfo {
  let level = 1;
  let remaining = Math.max(0, Math.floor(totalXp));
  while (remaining >= xpForLevel(level)) {
    remaining -= xpForLevel(level);
    level += 1;
  }
  const needed = xpForLevel(level);
  return { level, intoLevel: remaining, needed, progress: remaining / needed };
}

export type Tier = { name: string; minLevel: number; color: string; perk: string };

export const TIERS: Tier[] = [
  { name: 'Rookie', minLevel: 1, color: '#9BA1AD', perk: '1% cashback on card spend' },
  { name: 'Saver', minLevel: 5, color: '#34E2B0', perk: '2% cashback + free savings goals' },
  { name: 'Pro', minLevel: 10, color: '#4DA3FF', perk: '3% cashback + premium rewards' },
  { name: 'Elite', minLevel: 20, color: '#FFE600', perk: '5% cashback + Helsinki perks' },
];

export function tierForLevel(level: number): { tier: Tier; index: number } {
  let index = 0;
  for (let i = 0; i < TIERS.length; i++) {
    if (level >= TIERS[i].minLevel) index = i;
  }
  return { tier: TIERS[index], index };
}

/** Streak multiplier: +10% per consecutive day, capped at 2x. */
export function streakMultiplier(streak: number): number {
  return Math.min(2, 1 + streak * 0.1);
}

/** Local YYYY-MM-DD for streak day comparisons. */
export function todayKey(d: Date = new Date()): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

export function isYesterday(prev: string, now: Date = new Date()): boolean {
  const y = new Date(now);
  y.setDate(y.getDate() - 1);
  return prev === todayKey(y);
}
