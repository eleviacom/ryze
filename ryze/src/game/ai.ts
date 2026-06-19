// AI personalization. Generates a daily "for you" mission tailored to behaviour.
// Today it runs a local rules engine so the demo works offline; the Claude call
// is one fetch away — see the seam below.
import { Mission } from '@/game/types';

export type AiContext = {
  name: string;
  level: number;
  streak: number;
  coins: number;
  invites: number;
};

const TEMPLATES: ((c: AiContext) => Omit<Mission, 'id' | 'category' | 'claimed' | 'aiGenerated'>)[] = [
  (c) => ({
    title: c.streak >= 3 ? `Keep your ${c.streak}-day streak` : 'Start a 3-day streak',
    desc: 'Check in tomorrow to grow your multiplier',
    icon: '🔥', xp: 60, coins: 25, progress: 0, target: 1,
  }),
  (c) => ({
    title: c.invites === 0 ? 'Invite your first friend' : 'Invite one more friend',
    desc: 'Your squad is close to its goal — you both win coins',
    icon: '🤝', xp: 120, coins: 60, progress: 0, target: 1,
  }),
  (c) => ({
    title: `Save your way to level ${c.level + 1}`,
    desc: 'Move €10 into a goal to climb the leaderboard',
    icon: '📈', xp: 90, coins: 35, progress: 0, target: 1,
  }),
];

/** Pick the most relevant template for this user right now. */
export function generateDailyMission(ctx: AiContext): Mission {
  let pick = TEMPLATES[2];
  if (ctx.streak < 3) pick = TEMPLATES[0];
  else if (ctx.invites < 3) pick = TEMPLATES[1];
  const body = pick(ctx);
  return { id: `ai-${Date.now()}`, category: 'daily', claimed: false, aiGenerated: true, ...body };
}

// ponytail: local generator now; swap for a real model when a key exists.
// Wire the Claude API (claude-opus-4-8 / claude-haiku-4-5) like so:
//
// export async function generateDailyMissionAI(ctx: AiContext): Promise<Mission> {
//   const r = await fetch('https://api.anthropic.com/v1/messages', {
//     method: 'POST',
//     headers: { 'content-type': 'application/json', 'x-api-key': KEY, 'anthropic-version': '2023-06-01' },
//     body: JSON.stringify({ model: 'claude-haiku-4-5', max_tokens: 200,
//       messages: [{ role: 'user', content: `Return JSON {title,desc,icon,xp,coins} for a youth banking
//         mission given: ${JSON.stringify(ctx)}` }] }),
//   });
//   const j = await r.json();
//   const m = JSON.parse(j.content[0].text);
//   return { id: `ai-${Date.now()}`, category: 'daily', claimed: false, aiGenerated: true,
//     progress: 0, target: 1, ...m };
// }
