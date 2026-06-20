import React from 'react';
import {AbsoluteFill, Img, staticFile, useCurrentFrame} from 'remotion';
import {loadFont} from '@remotion/google-fonts/Nunito';

const {fontFamily} = loadFont();
const C = {void: '#000000', bg: '#151412', elev2: '#272421', yellow: '#F8D01F', goldTop: '#FFE470', goldBot: '#D4A200', text: '#FFFFFF', mute: '#B0B0B0', faint: '#76736D'};
const GOLD = `linear-gradient(180deg, ${C.goldTop}, ${C.yellow} 55%, ${C.goldBot})`;

const Bg: React.FC<{isVoid?: boolean}> = ({isVoid}) => (
  <AbsoluteFill style={{background: isVoid ? C.void : C.bg}}>
    <AbsoluteFill style={{background: 'radial-gradient(120% 80% at 16% -10%, rgba(248,208,31,0.13) 0%, rgba(248,208,31,0.04) 30%, transparent 64%)'}} />
  </AbsoluteFill>
);
const Phone: React.FC<{src: string; h?: number}> = ({src, h = 700}) => {
  const w = Math.round((h * 1206) / 2622), bz = 11;
  return (
    <div style={{width: w + bz * 2, height: h + bz * 2, borderRadius: 46, padding: bz, position: 'relative', background: 'linear-gradient(160deg,#2A2724,#141311)', boxShadow: '0 2px 6px rgba(0,0,0,.6), 0 26px 70px rgba(0,0,0,.5)'}}>
      <div style={{position: 'absolute', inset: 0, borderRadius: 46, pointerEvents: 'none', boxShadow: 'inset 0 1.5px 0 rgba(255,255,255,.16)'}} />
      <div style={{width: w, height: h, borderRadius: 36, overflow: 'hidden', background: C.bg}}>
        <Img src={staticFile(src)} style={{width: '100%', height: '100%', objectFit: 'cover'}} />
      </div>
    </div>
  );
};
const Eyebrow: React.FC<{t: string}> = ({t}) => (
  <div style={{display: 'inline-flex', alignItems: 'center', gap: 14, marginBottom: 26, fontFamily, fontWeight: 700, fontSize: 25, letterSpacing: '0.16em', textTransform: 'uppercase', color: C.faint}}>
    <span style={{width: 36, height: 4, borderRadius: 99, background: C.yellow}} />{t}
  </div>
);
const Title: React.FC<{children: React.ReactNode; size?: number}> = ({children, size = 64}) => (
  <div style={{fontFamily, fontWeight: 800, color: C.text, letterSpacing: '-0.03em', lineHeight: 1.05, fontSize: size, maxWidth: 900, whiteSpace: 'pre-line'}}>{children}</div>
);
type B = {h: string; t?: string};
const Bullets: React.FC<{items: B[]}> = ({items}) => (
  <div style={{marginTop: 34, display: 'flex', flexDirection: 'column', gap: 18, maxWidth: 860}}>
    {items.map((b, i) => (
      <div key={i} style={{display: 'flex', gap: 16, alignItems: 'flex-start'}}>
        <div style={{width: 12, height: 12, borderRadius: 99, background: GOLD, marginTop: 13, flex: '0 0 auto'}} />
        <div style={{fontFamily, fontWeight: 500, fontSize: 29, lineHeight: 1.3, color: C.mute}}>
          <b style={{color: C.text, fontWeight: 700}}>{b.h}</b>{b.t ? ` — ${b.t}` : ''}
        </div>
      </div>
    ))}
  </div>
);
const Content: React.FC<{eyebrow: string; title: React.ReactNode; bullets?: B[]; phones?: React.ReactNode; titleSize?: number}> = ({eyebrow, title, bullets, phones, titleSize}) => (
  <AbsoluteFill style={{flexDirection: 'row', alignItems: 'center', padding: '90px 60px 90px 130px'}}>
    <div style={{flex: phones ? '1 1 56%' : '1 1 100%'}}>
      <Eyebrow t={eyebrow} />
      <Title size={titleSize}>{title}</Title>
      {bullets ? <Bullets items={bullets} /> : null}
    </div>
    {phones ? <div style={{flex: '1 1 44%', display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 28}}>{phones}</div> : null}
  </AbsoluteFill>
);

export const RyzeDeck: React.FC = () => {
  const f = useCurrentFrame();
  let body: React.ReactNode = null, isVoid = false;
  switch (f) {
    case 0:
      isVoid = true;
      body = (
        <AbsoluteFill style={{justifyContent: 'center', alignItems: 'center'}}>
          <Img src={staticFile('logo.png')} style={{width: 270, height: 270, objectFit: 'contain', marginBottom: 4}} />
          <div style={{fontFamily, fontWeight: 800, fontSize: 132, letterSpacing: '-0.04em', color: C.text}}>Ryze</div>
          <div style={{fontFamily, fontWeight: 600, fontSize: 40, color: C.mute, marginTop: 2}}>Banking that levels up with you.</div>
          <div style={{marginTop: 44, fontFamily, fontWeight: 700, fontSize: 23, letterSpacing: '0.10em', color: C.faint, textTransform: 'uppercase'}}>PentaByte · JunctionX Tirana 2026 · Raiffeisen Play · Invite · Belong</div>
        </AbsoluteFill>
      );
      break;
    case 1:
      body = <Content eyebrow="THE PROBLEM" titleSize={70} title={'A first bank account feels\nlike homework — not freedom.'} bullets={[
        {h: 'Built for adults', t: 'adult language, adult assumptions, nothing for a 16-year-old'},
        {h: 'Zero guidance', t: 'no coaching, no nudges, no way to build good habits'},
        {h: 'No reason to start early', t: 'so a whole generation learns money the hard way'},
      ]} />;
      break;
    case 2:
      body = <Content eyebrow="THE SOLUTION" title={'Real banking, in a game\nyoung people want to play.'} bullets={[
        {h: 'Everything in one app', t: 'accounts, cards, pay & save on real Raiffeisen rails'},
        {h: 'An AI coach in your pocket', t: 'meet Riz'},
        {h: 'Rewards for smart money moves', t: 'streaks, levels, real coupons'},
      ]} phones={<Phone src="shots/11-home.png" h={800} />} />;
      break;
    case 3:
      body = <Content eyebrow="ONBOARDING" title={'Open a real account\nin 2 minutes.'} bullets={[
        {h: '100% online KYC', t: 'phone, OTP, ID scan, face check'},
        {h: 'Albania-correct & compliant', t: 'real legal disclosures, 18+ handling'},
        {h: 'EN + Albanian', t: 'from the very first screen'},
      ]} phones={<><Phone src="shots/06-onboarding-identity.png" h={640} /><Phone src="shots/10-onboarding-success.png" h={640} /></>} />;
      break;
    case 4:
      body = <Content eyebrow="AI MONEY COACH" title={'Meet Riz.'} bullets={[
        {h: 'Answers from your real data', t: '“How am I spending this month?”'},
        {h: 'Safety guardrails', t: 'refuses unsafe or off-topic requests'},
        {h: 'Works offline', t: 'local fallback when there’s no key or connection'},
      ]} phones={<Phone src="shots/15-assistant-riz-answer.png" h={820} />} />;
      break;
    case 5:
      body = <Content eyebrow="SOCIAL MONEY" title={'Pay and split\nlike texting.'} bullets={[
        {h: 'Send & request in chat', t: 'money bubbles with live status'},
        {h: 'Split a bill in seconds', t: 'pick your crew — done'},
      ]} phones={<><Phone src="shots/17-pay-chat-thread.png" h={640} /><Phone src="shots/18-pay-split-bill.png" h={640} /></>} />;
      break;
    case 6:
      body = <Content eyebrow="PLAY · INVITE · BELONG" title={'Saving that actually\nrewards you.'} bullets={[
        {h: 'Play', t: 'daily streaks, levels, AI missions tied to real money actions'},
        {h: 'Invite', t: 'referrals and a shared squad goal'},
        {h: 'Belong', t: 'a points store with real coupons — Spotify, KFC — redeemed by QR'},
      ]} phones={<><Phone src="shots/16-rewards.png" h={640} /><Phone src="shots/34-rewards-coupon.png" h={640} /></>} />;
      break;
    case 7:
      body = <Content eyebrow="CARDS & SAVINGS" title={'Cards you own.\nGoals you hit.'} bullets={[
        {h: 'Virtual + physical cards', t: 'freeze, limits, and a Card Studio to personalise'},
        {h: 'Savings goals with round-ups', t: 'plus clear spending analytics'},
      ]} phones={<><Phone src="shots/27-card-studio.png" h={640} /><Phone src="shots/24-grow-savings.png" h={640} /></>} />;
      break;
    case 8:
      body = <Content eyebrow="UNDER THE HOOD" title={'Built native.\nBuilt right.'} bullets={[
        {h: 'Native SwiftUI (iOS 17+)', t: 'modular Bank / Game / Onboarding / Riz models, 1:1 with the challenge services'},
        {h: 'Riz AI', t: 'live backend + safe offline fallback, with input guardrails'},
        {h: 'Real Albanian Lek', t: 'with ALL ↔ EUR exchange'},
        {h: 'EN / Albanian · light / dark', t: 'a Revolut-grade design system, one scarce Raiffeisen yellow stamp'},
      ]} phones={<Phone src="shots/12-cards.png" h={780} />} />;
      break;
    default:
      isVoid = true;
      body = (
        <AbsoluteFill style={{justifyContent: 'center', alignItems: 'center', padding: 120, textAlign: 'center'}}>
          <Eyebrow t="THE IMPACT" />
          <Title size={78}>{'Financial confidence for\nthe next generation.'}</Title>
          <div style={{fontFamily, fontWeight: 500, fontSize: 32, color: C.mute, marginTop: 30, maxWidth: 1200}}>Young Albanians learn money by playing — and Raiffeisen earns a loyal generation from day one.</div>
          <div style={{marginTop: 56, fontFamily, fontWeight: 700, fontSize: 27, color: C.text}}>github.com/eleviacom/ryze</div>
          <div style={{marginTop: 8, fontFamily, fontWeight: 600, fontSize: 23, color: C.faint}}>Ryze · PentaByte · JunctionX Tirana 2026</div>
        </AbsoluteFill>
      );
  }
  return (
    <AbsoluteFill style={{fontFamily}}>
      <Bg isVoid={isVoid} />
      {body}
      {f > 0 ? <div style={{position: 'absolute', bottom: 40, left: 130, fontFamily, fontWeight: 600, fontSize: 21, color: C.faint}}>Ryze · PentaByte</div> : null}
      <div style={{position: 'absolute', bottom: 40, right: 60, fontFamily, fontWeight: 600, fontSize: 21, color: C.faint}}>{f + 1} / 10</div>
    </AbsoluteFill>
  );
};
