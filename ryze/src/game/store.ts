// Central gamification store. One engine, every screen reads/writes here.
// Persisted to AsyncStorage so progress survives app restarts (demo-safe).
import AsyncStorage from '@react-native-async-storage/async-storage';
import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';

import { generateDailyMission } from '@/game/ai';
import { REWARDS, SEED_BADGES, SEED_MISSIONS, SEED_SQUAD, makeReferralCode } from '@/game/data';
import { isYesterday, levelInfo, streakMultiplier, todayKey } from '@/game/engine';
import { Badge, Mission, Squad } from '@/game/types';

export type RewardToast = { xp: number; coins: number; label: string } | null;

type State = {
  hydrated: boolean;
  onboarded: boolean;
  name: string;
  xp: number;
  coins: number;
  streak: number;
  lastCheckIn: string | null;
  savedTotal: number;
  missions: Mission[];
  aiMission: Mission | null;
  badges: Badge[];
  redeemed: string[];
  referralCode: string;
  invites: number;
  squad: Squad;
  celebrateNonce: number; // bump => confetti
  toast: RewardToast;
  kycStatus: 'none' | 'verified';
  accountOpened: boolean;
};

type Actions = {
  setHydrated: () => void;
  setName: (name: string) => void;
  finishOnboarding: () => void;
  progressMission: (id: string, by?: number) => void;
  claimMission: (id: string) => void;
  dailyCheckIn: () => boolean; // false if already checked in today
  redeem: (rewardId: string) => boolean;
  simulateReferral: () => void;
  generateAi: () => void;
  clearToast: () => void;
  setKycVerified: (name?: string) => void;
  reset: () => void;
};

const initial = (): Omit<State, 'hydrated' | 'celebrateNonce' | 'toast'> => ({
  onboarded: false,
  name: 'Friend',
  xp: 0,
  coins: 120,
  streak: 0,
  lastCheckIn: null,
  savedTotal: 0,
  missions: SEED_MISSIONS.map((m) => ({ ...m })),
  aiMission: null,
  badges: SEED_BADGES.map((b) => ({ ...b })),
  redeemed: [],
  referralCode: makeReferralCode(),
  invites: 0,
  squad: { ...SEED_SQUAD, members: SEED_SQUAD.members.map((m) => ({ ...m })) },
  kycStatus: 'none',
  accountOpened: false,
});

// Re-derive earned badges from current state; celebrate on a fresh unlock.
function evalBadges(s: State): { badges: Badge[]; unlocked: boolean } {
  const level = levelInfo(s.xp).level;
  const onboardDone = s.missions
    .filter((m) => m.category === 'onboarding')
    .every((m) => m.claimed);
  const cond: Record<string, boolean> = {
    'b-first-invite': s.invites >= 1,
    'b-streak7': s.streak >= 7,
    'b-level10': level >= 10,
    'b-onboard': onboardDone,
    'b-squad': s.squad.progress >= s.squad.goal,
    'b-saver': s.savedTotal >= 100,
  };
  let unlocked = false;
  const badges = s.badges.map((b) => {
    const earned = b.earned || !!cond[b.id];
    if (earned && !b.earned) unlocked = true;
    return { ...b, earned };
  });
  return { badges, unlocked };
}

export const useGame = create<State & Actions>()(
  persist(
    (set, get) => ({
      ...initial(),
      hydrated: false,
      celebrateNonce: 0,
      toast: null,

      setHydrated: () => set({ hydrated: true }),
      setName: (name) => set({ name: name.trim() || 'Friend' }),
      finishOnboarding: () => set({ onboarded: true }),

      progressMission: (id, by = 1) =>
        set((s) => {
          const missions = s.missions.map((m) =>
            m.id === id ? { ...m, progress: Math.min(m.target, m.progress + by) } : m,
          );
          const savedTotal = id === 'w-save' ? s.savedTotal + by : s.savedTotal;
          return { missions, savedTotal };
        }),

      claimMission: (id) => {
        const s = get();
        const m = s.missions.find((x) => x.id === id);
        if (!m || m.claimed || m.progress < m.target) return;
        const mult = m.category === 'daily' ? streakMultiplier(s.streak) : 1;
        const coins = Math.round(m.coins * mult);
        const missions = s.missions.map((x) => (x.id === id ? { ...x, claimed: true } : x));
        const next: State = {
          ...s,
          missions,
          xp: s.xp + m.xp,
          coins: s.coins + coins,
        };
        const { badges, unlocked } = evalBadges(next);
        set({
          missions,
          xp: next.xp,
          coins: next.coins,
          badges,
          celebrateNonce: s.celebrateNonce + 1,
          toast: { xp: m.xp, coins, label: m.title },
        });
        void unlocked;
      },

      dailyCheckIn: () => {
        const s = get();
        const today = todayKey();
        if (s.lastCheckIn === today) return false;
        const streak = s.lastCheckIn && isYesterday(s.lastCheckIn) ? s.streak + 1 : 1;
        const mult = streakMultiplier(streak);
        const xp = Math.round(30 * mult);
        const coins = Math.round(10 * mult);
        const missions = s.missions.map((m) =>
          m.id === 'd-checkin' ? { ...m, progress: 1, claimed: true } : m,
        );
        const next: State = { ...s, streak, lastCheckIn: today, xp: s.xp + xp, coins: s.coins + coins, missions };
        const { badges } = evalBadges(next);
        set({
          streak,
          lastCheckIn: today,
          xp: next.xp,
          coins: next.coins,
          missions,
          badges,
          celebrateNonce: s.celebrateNonce + 1,
          toast: { xp, coins, label: `Day ${streak} streak!` },
        });
        return true;
      },

      redeem: (rewardId) => {
        const s = get();
        const r = REWARDS.find((x) => x.id === rewardId);
        if (!r || s.coins < r.cost || s.redeemed.includes(rewardId)) return false;
        set({
          coins: s.coins - r.cost,
          redeemed: [...s.redeemed, rewardId],
          celebrateNonce: s.celebrateNonce + 1,
          toast: { xp: 0, coins: -r.cost, label: `Redeemed ${r.title}` },
        });
        return true;
      },

      simulateReferral: () => {
        const s = get();
        const invites = s.invites + 1;
        const squad: Squad = {
          ...s.squad,
          progress: Math.min(s.squad.goal, s.squad.progress + 1),
          members: s.squad.members.map((m) =>
            m.name === 'You' ? { ...m, contributed: m.contributed + 1 } : m,
          ),
        };
        const missions = s.missions.map((m) =>
          m.id === 's-invite' ? { ...m, progress: m.target } : m,
        );
        const next: State = { ...s, invites, squad, missions, xp: s.xp + 200, coins: s.coins + 100 };
        const { badges } = evalBadges(next);
        set({
          invites,
          squad,
          missions,
          xp: next.xp,
          coins: next.coins,
          badges,
          celebrateNonce: s.celebrateNonce + 1,
          toast: { xp: 200, coins: 100, label: 'Friend joined Ryze!' },
        });
      },

      generateAi: () => {
        const s = get();
        set({
          aiMission: generateDailyMission({
            name: s.name, level: levelInfo(s.xp).level, streak: s.streak, coins: s.coins, invites: s.invites,
          }),
        });
      },

      setKycVerified: (name) => {
        const s = get();
        const missions = s.missions.map((m) =>
          m.id === 'ob-verify' ? { ...m, progress: m.target, claimed: true } : m,
        );
        const next = { ...s, missions, xp: s.xp + 120, coins: s.coins + 50, onboarded: true };
        const { badges } = evalBadges(next as State);
        set({
          missions, xp: next.xp, coins: next.coins, badges,
          onboarded: true, kycStatus: 'verified', accountOpened: true,
          name: name && name.length ? name : s.name,
          celebrateNonce: s.celebrateNonce + 1,
          toast: { xp: 120, coins: 50, label: 'Account opened!' },
        });
      },

      clearToast: () => set({ toast: null }),
      reset: () => set({ ...initial(), hydrated: true, celebrateNonce: 0, toast: null }),
    }),
    {
      name: 'ryze-game-v1',
      storage: createJSONStorage(() => AsyncStorage),
      partialize: (s) => ({
        onboarded: s.onboarded, name: s.name, xp: s.xp, coins: s.coins, streak: s.streak,
        lastCheckIn: s.lastCheckIn, savedTotal: s.savedTotal, missions: s.missions,
        badges: s.badges, redeemed: s.redeemed, referralCode: s.referralCode,
        invites: s.invites, squad: s.squad, kycStatus: s.kycStatus, accountOpened: s.accountOpened,
      }),
      onRehydrateStorage: () => (state) => state?.setHydrated(),
    },
  ),
);
