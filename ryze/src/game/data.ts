// Seed content for the demo. In production these come from the Gamification
// Service + Rewards Service; here they hydrate the store on first run.
import { Badge, LeaderRow, Mission, Reward, Squad } from '@/game/types';

export const SEED_MISSIONS: Mission[] = [
  // Onboarding journey — completing these is the "improve onboarding" objective.
  { id: 'ob-verify', title: 'Verify your identity', desc: 'Quick KYC to unlock your account', icon: '🪪', xp: 120, coins: 50, category: 'onboarding', progress: 0, target: 1, claimed: false },
  { id: 'ob-card', title: 'Activate your card', desc: 'Add Ryze to Apple/Google Pay', icon: '💳', xp: 100, coins: 40, category: 'onboarding', progress: 0, target: 1, claimed: false },
  { id: 'ob-goal', title: 'Set a savings goal', desc: 'Name something you are saving for', icon: '🎯', xp: 90, coins: 30, category: 'onboarding', progress: 0, target: 1, claimed: false },

  // Daily loop — engagement.
  { id: 'd-checkin', title: 'Daily check-in', desc: 'Open Ryze and keep your streak alive', icon: '☀️', xp: 30, coins: 10, category: 'daily', progress: 0, target: 1, claimed: false },
  { id: 'd-round', title: 'Round-up a purchase', desc: 'Save the change on any card spend', icon: '🪙', xp: 40, coins: 15, category: 'daily', progress: 0, target: 1, claimed: false },
  { id: 'd-quiz', title: 'Money quiz', desc: 'Answer todays 3-question money quiz', icon: '🧠', xp: 50, coins: 20, category: 'daily', progress: 0, target: 3, claimed: false },

  // Weekly — deeper product usage.
  { id: 'w-save', title: 'Save €25 this week', desc: 'Move money into any goal', icon: '🏦', xp: 150, coins: 60, category: 'weekly', progress: 0, target: 25, claimed: false },
  { id: 'w-spend', title: 'Pay with Ryze 5 times', desc: 'Use your card 5 times', icon: '⚡️', xp: 130, coins: 50, category: 'weekly', progress: 0, target: 5, claimed: false },

  // Social — referral / viral.
  { id: 's-invite', title: 'Invite a friend', desc: 'Both of you earn 200 coins', icon: '🤝', xp: 200, coins: 100, category: 'social', progress: 0, target: 1, claimed: false },
];

export const REWARDS: Reward[] = [
  { id: 'r-spotify', title: '1 month Spotify', brand: 'Spotify', icon: '🎧', cost: 300 },
  { id: 'r-coffee', title: '€5 coffee voucher', brand: 'Mulliri Vjeter', icon: '☕️', cost: 150 },
  { id: 'r-cinema', title: 'Cinema ticket', brand: 'Kinema Millennium', icon: '🎬', cost: 250 },
  { id: 'r-cashback', title: '+1% cashback boost', brand: 'Ryze', icon: '🚀', cost: 400, tierMin: 1 },
  { id: 'r-data', title: '5GB mobile data', brand: 'ONE', icon: '📶', cost: 200 },
  { id: 'r-merch', title: 'Ryze hoodie', brand: 'Ryze', icon: '🧥', cost: 800, tierMin: 2 },
];

export const SEED_BADGES: Badge[] = [
  { id: 'b-first-invite', title: 'Connector', icon: '🤝', desc: 'Invited your first friend', earned: false },
  { id: 'b-streak7', title: 'On Fire', icon: '🔥', desc: '7-day streak', earned: false },
  { id: 'b-level10', title: 'Pro', icon: '🏆', desc: 'Reached level 10', earned: false },
  { id: 'b-onboard', title: 'All Set', icon: '✅', desc: 'Finished onboarding', earned: false },
  { id: 'b-squad', title: 'Team Player', icon: '🧩', desc: 'Completed a squad goal', earned: false },
  { id: 'b-saver', title: 'Stacker', icon: '💰', desc: 'Saved €100 total', earned: false },
];

// Friends leaderboard (excludes you — your row is injected at render time).
export const SEED_LEADERBOARD: LeaderRow[] = [
  { id: 'l1', name: 'Elsa', avatar: '🦊', xp: 1840 },
  { id: 'l2', name: 'Muhamed', avatar: '🐼', xp: 1520 },
  { id: 'l3', name: 'Aleks', avatar: '🐯', xp: 980 },
  { id: 'l4', name: 'Drin', avatar: '🐸', xp: 610 },
  { id: 'l5', name: 'Sara', avatar: '🦉', xp: 430 },
];

export const SEED_SQUAD: Squad = {
  name: 'Tirana Crew',
  goalTitle: 'Invite 10 friends together',
  goal: 10,
  progress: 4,
  rewardCoins: 500,
  members: [
    { id: 'm0', name: 'You', avatar: '😎', contributed: 1 },
    { id: 'm1', name: 'Elsa', avatar: '🦊', contributed: 2 },
    { id: 'm2', name: 'Drin', avatar: '🐸', contributed: 1 },
  ],
};

export function makeReferralCode(): string {
  const a = ['RYZE', 'PLAY', 'RAI'];
  const n = String(1000 + Math.floor(Math.random() * 8999));
  return `${a[Math.floor(Math.random() * a.length)]}-${n}`;
}
