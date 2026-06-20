import React from 'react';
import {
  AbsoluteFill, Audio, Img, OffthreadVideo, Sequence, staticFile,
  useCurrentFrame, useVideoConfig, interpolate, spring, Easing,
} from 'remotion';
import {loadFont} from '@remotion/google-fonts/Nunito';

const {fontFamily} = loadFont();

export const FPS = 30;
export const WIDTH = 1920;
export const HEIGHT = 1080;
export const DURATION = 1676; // 55.87s == VO length, cuts on the VO pauses

// ---- brand tokens (from ryze-ios/Theme.swift + BRANDING.md) ----
const C = {
  void: '#000000', bg: '#151412', elev1: '#1E1C19', elev2: '#272421',
  yellow: '#F8D01F', goldTop: '#FFE470', goldBot: '#D4A200', goldEdge: '#FFEFA8',
  text: '#FFFFFF', mute: '#B0B0B0', faint: '#76736D',
};

// ===================================================================
// CAPTIONS — edit the text here. Set USE_SUGGESTED = false to BLANK
// every caption (leaves the styled space empty) and write your own.
// ===================================================================
export const USE_SUGGESTED = true;
const SUGGESTED = [
  {eyebrow: 'FOR EVERY YOUNG ALBANIAN', title: 'Your bank still treats\nyou like your parents.'},
  {eyebrow: '', title: 'Meet Ryze.'},
  {eyebrow: 'OPEN IN 2 MINUTES', title: 'A real account.\n100% online.'},
  {eyebrow: 'ONE HOME FOR YOUR MONEY', title: 'Balance, goals and level —\nall in one place.'},
  {eyebrow: 'MEET RIZ', title: 'Your AI\nmoney coach.'},
  {eyebrow: 'PAY & SPLIT', title: 'Money, made\nsocial.'},
  {eyebrow: 'PLAY · SAVE · EARN', title: 'Every smart move\nearns real rewards.'},
  {eyebrow: 'JUNCTIONX TIRANA 2026', title: 'Ryze — money that\nlevels up with you.'},
];
const BLANK = SUGGESTED.map(() => ({eyebrow: '', title: ''}));
const CAP = USE_SUGGESTED ? SUGGESTED : BLANK;

// scene frame ranges (sum = 1676)
const SC = [
  {from: 0, len: 265}, {from: 265, len: 140}, {from: 405, len: 224}, {from: 629, len: 130},
  {from: 759, len: 298}, {from: 1057, len: 247}, {from: 1304, len: 216}, {from: 1520, len: 156},
];

const Background: React.FC<{isVoid?: boolean}> = ({isVoid}) => {
  const frame = useCurrentFrame();
  const drift = interpolate(frame % 600, [0, 300, 600], [0, 1, 0]);
  return (
    <AbsoluteFill style={{background: isVoid ? C.void : C.bg}}>
      <AbsoluteFill style={{
        background: `radial-gradient(120% 80% at ${18 + drift * 5}% -8%, rgba(248,208,31,0.12) 0%, rgba(248,208,31,0.04) 28%, transparent 62%)`,
      }} />
    </AbsoluteFill>
  );
};

const Eyebrow: React.FC<{text: string; center?: boolean}> = ({text, center}) => (
  <div style={{
    display: 'inline-flex', alignItems: 'center', gap: 14, marginBottom: 30,
    fontFamily, fontWeight: 700, fontSize: 24, letterSpacing: '0.16em',
    textTransform: 'uppercase', color: C.faint,
    justifyContent: center ? 'center' : 'flex-start',
  }}>
    <span style={{width: 34, height: 4, borderRadius: 99, background: C.yellow}} />
    {text}
  </div>
);

const Caption: React.FC<{i: number; center?: boolean; inAt?: number; size?: number}> = ({i, center, inAt = 10, size}) => {
  const frame = useCurrentFrame();
  const cap = CAP[i];
  const t = Math.max(0, frame - inAt);
  const y = interpolate(t, [0, 22], [28, 0], {extrapolateRight: 'clamp', easing: Easing.out(Easing.cubic)});
  const o = interpolate(t, [0, 22], [0, 1], {extrapolateRight: 'clamp'});
  const blur = interpolate(t, [0, 22], [8, 0], {extrapolateRight: 'clamp'});
  const fs = size ?? (center ? 116 : 76);
  return (
    <div style={{
      transform: `translateY(${y}px)`, opacity: o, filter: `blur(${blur}px)`,
      display: 'flex', flexDirection: 'column',
      alignItems: center ? 'center' : 'flex-start', textAlign: center ? 'center' : 'left',
    }}>
      {cap.eyebrow ? <Eyebrow text={cap.eyebrow} center={center} /> : null}
      <div style={{
        fontFamily, fontWeight: 800, color: C.text, letterSpacing: '-0.03em',
        lineHeight: 1.04, fontSize: fs, whiteSpace: 'pre-line',
        maxWidth: center ? 1500 : 780, minHeight: cap.title ? undefined : fs * 1.5,
      }}>{cap.title}</div>
    </div>
  );
};

const Phone: React.FC<{src: string; video?: boolean; poster?: string; startFrom?: number; h?: number; enter?: boolean}> = ({src, video, poster, startFrom = 0, h = 866, enter = true}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const inY = enter ? spring({frame, fps, from: 150, to: 0, config: {damping: 18, stiffness: 85, mass: 1}}) : 0;
  const inO = enter ? interpolate(frame, [0, 18], [0, 1], {extrapolateRight: 'clamp'}) : 1;
  const drift = interpolate(frame, [0, 240], [0, -22], {extrapolateRight: 'clamp'});
  const w = Math.round((h * 1206) / 2622);
  const bz = 13;
  return (
    <div style={{transform: `translateY(${inY + drift}px)`, opacity: inO}}>
      <div style={{
        width: w + bz * 2, height: h + bz * 2, borderRadius: 60, padding: bz, position: 'relative',
        background: 'linear-gradient(160deg,#2A2724,#141311)',
        boxShadow: '0 2px 6px rgba(0,0,0,.6), 0 30px 80px rgba(0,0,0,.45), 0 60px 160px rgba(0,0,0,.55)',
      }}>
        <div style={{position: 'absolute', inset: 0, borderRadius: 60, pointerEvents: 'none',
          boxShadow: 'inset 0 1.5px 0 rgba(255,255,255,.16), inset 0 -1.5px 0 rgba(255,255,255,.03)'}} />
        <div style={{width: w, height: h, borderRadius: 48, overflow: 'hidden', position: 'relative', background: C.bg}}>
          {poster ? <Img src={staticFile(poster)} style={{position: 'absolute', inset: 0, width: '100%', height: '100%', objectFit: 'cover'}} /> : null}
          {video
            ? <OffthreadVideo src={staticFile(src)} startFrom={startFrom} muted style={{position: 'relative', width: '100%', height: '100%', objectFit: 'cover'}} />
            : <Img src={staticFile(src)} style={{position: 'relative', width: '100%', height: '100%', objectFit: 'cover'}} />}
        </div>
      </div>
    </div>
  );
};

const Confetti: React.FC<{startAt: number; cx?: number; cy?: number}> = ({startAt, cx = 0.73, cy = 0.45}) => {
  const frame = useCurrentFrame();
  const t = (frame - startAt) / FPS;
  if (t < 0 || t > 1.5) return null;
  const prog = Math.min(1, t / 0.9);
  const e = 1 - Math.pow(1 - prog, 3);
  return (
    <AbsoluteFill>
      {Array.from({length: 18}).map((_, i) => {
        const a = (i / 18) * Math.PI * 2;
        const dx = Math.cos(a) * 240 * e;
        const dy = Math.sin(a) * 240 * e - 40 * e;
        const rot = 240 * e;
        const op = interpolate(prog, [0, 0.7, 1], [1, 1, 0]);
        const circle = i % 2 === 0;
        const white = i % 3 === 0;
        return (
          <div key={i} style={{
            position: 'absolute', left: `${cx * 100}%`, top: `${cy * 100}%`,
            width: circle ? 16 : 18, height: circle ? 16 : 10, borderRadius: circle ? '50%' : 4,
            background: white ? '#fff' : C.yellow,
            transform: `translate(${dx}px,${dy}px) rotate(${rot}deg)`, opacity: op,
          }} />
        );
      })}
    </AbsoluteFill>
  );
};

const SceneWrap: React.FC<{len: number; children: React.ReactNode}> = ({len, children}) => {
  const frame = useCurrentFrame();
  const op = interpolate(frame, [0, 12, len - 12, len], [0, 1, 1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  return <AbsoluteFill style={{opacity: op}}>{children}</AbsoluteFill>;
};

const CenterScene: React.FC<{i: number; logo?: boolean; cta?: boolean}> = ({i, logo, cta}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const sc = spring({frame, fps, from: 0.7, to: 1, config: {damping: 14, stiffness: 100}});
  const lo = interpolate(frame, [0, 16], [0, 1], {extrapolateRight: 'clamp'});
  return (
    <SceneWrap len={SC[i].len}>
      <Background isVoid={logo} />
      <AbsoluteFill style={{justifyContent: 'center', alignItems: 'center', padding: 80}}>
        {logo ? <Img src={staticFile('logo.png')} style={{width: 300, height: 300, objectFit: 'contain', marginBottom: 20, transform: `scale(${sc})`, opacity: lo}} /> : null}
        <Caption i={i} center inAt={logo ? 16 : 10} />
        {cta ? <div style={{marginTop: 38, fontFamily, fontWeight: 700, fontSize: 26, letterSpacing: '0.04em', color: C.faint, opacity: lo}}>Youth banking for Raiffeisen · public demo</div> : null}
      </AbsoluteFill>
    </SceneWrap>
  );
};

const AppScene: React.FC<{i: number; src: string; video?: boolean; poster?: string; startFrom?: number; h?: number; confettiAt?: number}> = ({i, src, video, poster, startFrom, h, confettiAt}) => (
  <SceneWrap len={SC[i].len}>
    <Background />
    <AbsoluteFill style={{flexDirection: 'row', alignItems: 'center'}}>
      <div style={{flex: '0 0 46%', padding: '0 40px 0 120px'}}><Caption i={i} /></div>
      <div style={{flex: 1, display: 'flex', justifyContent: 'center', alignItems: 'center', position: 'relative'}}>
        <Phone src={src} video={video} poster={poster} startFrom={startFrom} h={h} />
      </div>
    </AbsoluteFill>
    {confettiAt != null ? <Confetti startAt={confettiAt} /> : null}
  </SceneWrap>
);

const DuoScene: React.FC<{i: number; a: string; b: string; confetti?: boolean}> = ({i, a, b, confetti}) => {
  const frame = useCurrentFrame();
  const len = SC[i].len;
  const swap = interpolate(frame, [len * 0.5, len * 0.6], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  return (
    <SceneWrap len={len}>
      <Background />
      <AbsoluteFill style={{flexDirection: 'row', alignItems: 'center'}}>
        <div style={{flex: '0 0 46%', padding: '0 40px 0 120px'}}><Caption i={i} /></div>
        <div style={{flex: 1, display: 'flex', justifyContent: 'center', alignItems: 'center', position: 'relative'}}>
          <div style={{position: 'absolute', opacity: 1 - swap}}><Phone src={a} /></div>
          <div style={{position: 'absolute', opacity: swap}}><Phone src={b} enter={false} /></div>
        </div>
      </AbsoluteFill>
      {confetti ? <Confetti startAt={Math.round(len * 0.58)} /> : null}
    </SceneWrap>
  );
};

export const RyzeVideo: React.FC = () => (
  <AbsoluteFill style={{backgroundColor: C.bg, fontFamily}}>
    <Audio src={staticFile('vo.mp3')} />
    {/* MUSIC SLOT: put a track at public/music.mp3, then uncomment:
    <Audio src={staticFile('music.mp3')} volume={0.22} /> */}
    <Sequence from={SC[0].from} durationInFrames={SC[0].len}><CenterScene i={0} /></Sequence>
    <Sequence from={SC[1].from} durationInFrames={SC[1].len}><CenterScene i={1} logo /></Sequence>
    <Sequence from={SC[2].from} durationInFrames={SC[2].len}><AppScene i={2} src="seal.png" confettiAt={28} /></Sequence>
    <Sequence from={SC[3].from} durationInFrames={SC[3].len}><AppScene i={3} src="home.png" /></Sequence>
    <Sequence from={SC[4].from} durationInFrames={SC[4].len}><AppScene i={4} src="riz.mp4" video poster="rizanswer.png" startFrom={45} h={940} /></Sequence>
    <Sequence from={SC[5].from} durationInFrames={SC[5].len}><DuoScene i={5} a="thread.png" b="split.png" /></Sequence>
    <Sequence from={SC[6].from} durationInFrames={SC[6].len}><DuoScene i={6} a="rewards.png" b="coupon.png" confetti /></Sequence>
    <Sequence from={SC[7].from} durationInFrames={SC[7].len}><CenterScene i={7} logo cta /></Sequence>
  </AbsoluteFill>
);
