// Domain types for the Ryze gamification engine.

export type MissionCategory = 'onboarding' | 'daily' | 'weekly' | 'social';

export type Mission = {
  id: string;
  title: string;
  desc: string;
  icon: string; // emoji
  xp: number;
  coins: number;
  category: MissionCategory;
  progress: number;
  target: number;
  claimed: boolean;
  aiGenerated?: boolean;
};

export type Reward = {
  id: string;
  title: string;
  brand: string;
  icon: string;
  cost: number;
  tierMin?: number; // min tier index required (0 = any)
};

export type Badge = {
  id: string;
  title: string;
  icon: string;
  desc: string;
  earned: boolean;
};

export type LeaderRow = {
  id: string;
  name: string;
  avatar: string;
  xp: number;
  you?: boolean;
};

export type SquadMember = { id: string; name: string; avatar: string; contributed: number };

export type Squad = {
  name: string;
  goalTitle: string;
  goal: number;
  progress: number;
  rewardCoins: number;
  members: SquadMember[];
};
