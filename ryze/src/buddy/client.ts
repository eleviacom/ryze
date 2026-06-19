// Riz client: hard safety guard -> backend proxy (if configured) -> offline local reply.
// The Anthropic key NEVER ships in the app; a backend proxy injects it. Offline, a
// deterministic local reply keeps the buddy useful on flaky conference Wi-Fi.
import { buildContext, RIZ_SYSTEM, stepWhy } from '@/buddy/system-prompt';

export type Msg = { role: 'user' | 'assistant'; text: string };

const SECRET = /\b(\d{4,8})\b/; // crude: a bare numeric code pasted into chat
const SECRET_WORDS = /(otp|pin|password|cvv|one[-\s]?time|code)\b/i;
const ADVICE = /(should i|which (account|card)|is .* (a good|worth it)|what should i do with|invest|recommend)/i;
const ESCALATE = /(fraud|stolen|blocked|locked|complain|charged|refund|someone (took|accessed))/i;

/** Pre-flight guard. Returns a canned safe reply, or null to fall through to the model/local. */
export function guardInput(text: string): string | null {
  if (SECRET_WORDS.test(text) || SECRET.test(text)) {
    return "Don't share codes, PINs or passwords with anyone — including me. Just enter the code on the screen above. (Hard rule, for your safety.)";
  }
  if (ESCALATE.test(text)) {
    return "That's one for a real person on the Raiffeisen team. Want me to point you to in-app support?";
  }
  if (ADVICE.test(text)) {
    return "I can explain how the options work, but what's right for your money is your call — I can't advise on that. Want me to connect you with a Raiffeisen specialist?";
  }
  return null;
}

/** Deterministic fallback grounded in the same per-step "why" copy. */
export function localReply(stepId: string | undefined, text: string): string {
  const guard = guardInput(text);
  if (guard) return guard;
  const why = stepId ? stepWhy(stepId) : undefined;
  if (/safe|secure|trust|protect|privacy/i.test(text)) {
    return 'Yes. Raiffeisen is supervised by the Bank of Albania, your deposits are insured by the ASD, and your data is handled under Albanian Law No. 124/2024. We use these details only to open and run your account.';
  }
  if (/how long|time|minutes|quick/i.test(text)) {
    return 'It takes a few minutes. Nothing is submitted until the final step, so you can take your time.';
  }
  if (why) return why;
  return "I'm here to explain any step. Ask me what something means or why it's needed.";
}

const ENDPOINT = process.env.EXPO_PUBLIC_RIZ_URL; // backend proxy; unset in the demo

/** Ask Riz. Guard -> proxy (if configured) -> local fallback. Never throws. */
export async function askRiz(args: { stepId?: string; name?: string; locale?: string; history: Msg[]; text: string }): Promise<string> {
  const guard = guardInput(args.text);
  if (guard) return guard;
  if (!ENDPOINT) return localReply(args.stepId, args.text);
  try {
    const res = await fetch(ENDPOINT, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        system: RIZ_SYSTEM,
        context: buildContext(args.stepId, args.name, args.locale),
        messages: [...args.history, { role: 'user', text: args.text }],
      }),
    });
    if (!res.ok) return localReply(args.stepId, args.text);
    const data = await res.json();
    return (data.reply as string) || localReply(args.stepId, args.text);
  } catch {
    return localReply(args.stepId, args.text);
  }
}
