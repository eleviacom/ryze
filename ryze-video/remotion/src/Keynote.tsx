import React from 'react';
import {
  AbsoluteFill, Img, OffthreadVideo, Sequence, staticFile,
  useCurrentFrame, useVideoConfig, interpolate, spring, random,
} from 'remotion';
import {loadFont} from '@remotion/google-fonts/Inter';

const {fontFamily} = loadFont();

export const FPS = 30;
export const WIDTH = 1920;
export const HEIGHT = 1080;

// ---- Apple-keynote palette (white) + Ryze banana gold accent ----
const C = {
  bg: '#F5F5F7',        // Apple light gray canvas
  white: '#FFFFFF',
  ink: '#1D1D1F',       // near-black headline
  faint: '#6E6E73',     // secondary
  gold: '#F8D01F',      // brand stamp accent (scarce)
  goldDeep: '#D4A200',
};

// 120 BPM at 30fps -> 1 beat = 15 frames. Scenes are multiples of a beat.
const B = 15;

// ===================================================================
// SCENES — each app clip is a Seedance motion shot of the REAL UI on white.
// Edit caption text here. len is in frames.
// ===================================================================
type Scene = {
  kind: 'broll' | 'app' | 'logo' | 'montage' | 'outro';
  clip?: string;
  eyebrow?: string;
  title?: string;
  len: number;
  capPos?: 'top' | 'bottom';
  emoji?: string[];     // playful burst (social beat)
};

const SCENES: Scene[] = [
  {kind: 'broll', clip: 'broll_woman.mp4', eyebrow: 'FOR 14–25 · ALBANIA', title: 'Banking, but\nmade yours.', len: 9 * B, capPos: 'bottom'},
  {kind: 'logo', title: 'Ryze', len: 6 * B},
  {kind: 'app', clip: 'success_motion.mp4', eyebrow: 'OPEN IN 2 MINUTES', title: 'A real Raiffeisen\naccount.', len: 10 * B, capPos: 'top'},
  {kind: 'app', clip: 'home_motion.mp4', eyebrow: 'ONE HOME FOR YOUR MONEY', title: 'Everything\nin one place.', len: 10 * B, capPos: 'top'},
  {kind: 'app', clip: 'riz_motion.mp4', eyebrow: 'MEET RIZ', title: 'Your AI\nmoney coach.', len: 10 * B, capPos: 'top'},
  {kind: 'app', clip: 'split_motion.mp4', eyebrow: 'PAY · REQUEST · SPLIT', title: 'Money, made\nsocial.', len: 10 * B, capPos: 'top', emoji: ['💸', '🪙', '⚡️', '💰']},
  {kind: 'app', clip: 'rewards_motion.mp4', eyebrow: 'PLAY · INVITE · BELONG', title: 'Every smart\nmove earns.', len: 10 * B, capPos: 'top'},
  {kind: 'app', clip: 'coupon_motion.mp4', eyebrow: 'REAL REWARDS', title: 'Points become\nreal rewards.', len: 9 * B, capPos: 'top'},
  {kind: 'app', clip: 'cardstudio_motion.mp4', eyebrow: 'CARD STUDIO', title: 'Make your\ncard yours.', len: 9 * B, capPos: 'top'},
  {kind: 'app', clip: 'analytics_motion.mp4', eyebrow: 'GROW', title: 'See where\nit goes.', len: 9 * B, capPos: 'top'},
  {kind: 'montage', title: 'One app.\nYour whole money life.', len: 11 * B},
  {kind: 'outro', len: 15 * B},
];

// ---- absolute scene starts ----
const STARTS: number[] = [];
SCENES.reduce((acc, s, i) => { STARTS[i] = acc; return acc + s.len; }, 0);
export const DURATION = SCENES.reduce((a, s) => a + s.len, 0);

// ===================================================================
// shared bits
// ===================================================================
const Canvas: React.FC<{children?: React.ReactNode}> = ({children}) => (
  <AbsoluteFill style={{background: C.bg}}>
    <AbsoluteFill style={{
      background: `radial-gradient(120% 85% at 50% -10%, rgba(248,208,31,0.10) 0%, rgba(248,208,31,0.03) 30%, transparent 60%)`,
    }} />
    {children}
  </AbsoluteFill>
);

// quick white flash on every cut (beat hit)
const CutFlash: React.FC<{len: number}> = ({len}) => {
  const frame = useCurrentFrame();
  const o = interpolate(frame, [0, 5], [0.32, 0], {extrapolateRight: 'clamp'})
    + interpolate(frame, [len - 4, len], [0, 0.22], {extrapolateLeft: 'clamp'});
  return <AbsoluteFill style={{background: '#fff', opacity: o, pointerEvents: 'none'}} />;
};

const Eyebrow: React.FC<{text: string; center?: boolean}> = ({text, center}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const s = spring({frame: frame - 2, fps, config: {damping: 20, stiffness: 300, mass: 0.7}});
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 14, marginBottom: 22,
      fontFamily, fontWeight: 700, fontSize: 22, letterSpacing: '0.18em',
      textTransform: 'uppercase', color: C.faint,
      justifyContent: center ? 'center' : 'flex-start',
      opacity: s, transform: `translateY(${(1 - s) * 14}px)`,
    }}>
      <span style={{width: 30, height: 4, borderRadius: 99, background: C.gold}} />
      {text}
    </div>
  );
};

// big bold caption with spring pop + staggered eyebrow/title
const Caption: React.FC<{eyebrow?: string; title?: string; center?: boolean; size?: number; dark?: boolean}> = ({eyebrow, title, center, size = 92, dark}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const s = spring({frame: frame - 4, fps, config: {damping: 22, stiffness: 280, mass: 0.8}});
  const o = interpolate(frame, [2, 16], [0, 1], {extrapolateRight: 'clamp'});
  return (
    <div style={{
      display: 'flex', flexDirection: 'column',
      alignItems: center ? 'center' : 'flex-start', textAlign: center ? 'center' : 'left',
    }}>
      {eyebrow ? <Eyebrow text={eyebrow} center={center} /> : null}
      {title ? (
        <div style={{
          fontFamily, fontWeight: 800, color: dark ? '#fff' : C.ink, letterSpacing: '-0.035em',
          lineHeight: 0.98, fontSize: size, whiteSpace: 'pre-line',
          opacity: o, transform: `translateY(${(1 - s) * 26}px) scale(${0.94 + s * 0.06})`,
          transformOrigin: center ? 'center' : 'left center',
          textShadow: dark ? '0 2px 30px rgba(0,0,0,0.35)' : 'none',
        }}>{title}</div>
      ) : null}
    </div>
  );
};

// app clip filling the frame, with a subtle beat-synced scale punch on entry
const ClipFill: React.FC<{clip: string}> = ({clip}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const pop = spring({frame, fps, config: {damping: 26, stiffness: 200, mass: 1}});
  const scale = 1.06 - pop * 0.06; // tiny settle so the cut "lands"
  return (
    <AbsoluteFill style={{transform: `scale(${scale})`}}>
      <OffthreadVideo src={staticFile('seedance/' + clip)} muted
        style={{width: '100%', height: '100%', objectFit: 'cover'}} />
    </AbsoluteFill>
  );
};

// playful emoji burst that breaks out toward the camera (social beat)
const EmojiBurst: React.FC<{emoji: string[]; startAt: number}> = ({emoji, startAt}) => {
  const frame = useCurrentFrame();
  const t = frame - startAt;
  if (t < 0 || t > 40) return null;
  return (
    <AbsoluteFill style={{pointerEvents: 'none'}}>
      {Array.from({length: 14}).map((_, i) => {
        const seed = i + 1;
        const a = (i / 14) * Math.PI * 2 + random(`a${seed}`) * 0.5;
        const prog = interpolate(t, [0, 30], [0, 1], {extrapolateRight: 'clamp'});
        const e = 1 - Math.pow(1 - prog, 2.5);
        const dist = (300 + random(`d${seed}`) * 380) * e;
        const dx = Math.cos(a) * dist;
        const dy = Math.sin(a) * dist - 60 * e;
        const sc = 0.6 + e * (1.1 + random(`s${seed}`) * 0.8);
        const op = interpolate(prog, [0, 0.65, 1], [0, 1, 0]);
        const rot = (random(`r${seed}`) - 0.5) * 120 * e;
        return (
          <div key={i} style={{
            position: 'absolute', left: '50%', top: '52%', fontSize: 64,
            transform: `translate(-50%,-50%) translate(${dx}px,${dy}px) scale(${sc}) rotate(${rot}deg)`,
            opacity: op,
          }}>{emoji[i % emoji.length]}</div>
        );
      })}
    </AbsoluteFill>
  );
};

// ---- the Ryze gable logo (yellow rounded square + crossed gables) ----
const RyzeMark: React.FC<{size: number}> = ({size}) => (
  <Img src={staticFile('logo.png')} style={{width: size, height: size, objectFit: 'contain'}} />
);

// ===================================================================
// scene renderers
// ===================================================================
const BrollScene: React.FC<{s: Scene}> = ({s}) => {
  const frame = useCurrentFrame();
  const o = interpolate(frame, [0, 10, s.len - 8, s.len], [0, 1, 1, 0.0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  return (
    <AbsoluteFill style={{opacity: o}}>
      <ClipFill clip={s.clip!} />
      <AbsoluteFill style={{background: 'linear-gradient(to top, rgba(0,0,0,0.45) 0%, rgba(0,0,0,0.0) 42%)'}} />
      <AbsoluteFill style={{justifyContent: 'flex-end', alignItems: 'flex-start', padding: '0 0 96px 110px'}}>
        <Caption eyebrow={s.eyebrow} title={s.title} size={108} dark />
      </AbsoluteFill>
      <CutFlash len={s.len} />
    </AbsoluteFill>
  );
};

const LogoScene: React.FC<{s: Scene}> = ({s}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const pop = spring({frame, fps, config: {damping: 12, stiffness: 200, mass: 0.9}});
  const wordO = interpolate(frame, [10, 24], [0, 1], {extrapolateRight: 'clamp'});
  const o = interpolate(frame, [0, 8, s.len - 8, s.len], [0, 1, 1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  return (
    <Canvas>
      <AbsoluteFill style={{opacity: o, justifyContent: 'center', alignItems: 'center', gap: 8}}>
        <div style={{transform: `scale(${0.6 + pop * 0.4}) rotate(${(1 - pop) * -12}deg)`, filter: `drop-shadow(0 20px 50px rgba(248,208,31,0.35))`}}>
          <RyzeMark size={260} />
        </div>
        <div style={{fontFamily, fontWeight: 800, fontSize: 128, color: C.ink, letterSpacing: '-0.04em', opacity: wordO, transform: `translateY(${(1 - wordO) * 16}px)`}}>{s.title}</div>
      </AbsoluteFill>
      <CutFlash len={s.len} />
    </Canvas>
  );
};

const AppScene: React.FC<{s: Scene}> = ({s}) => {
  const frame = useCurrentFrame();
  const o = interpolate(frame, [0, 8, s.len - 8, s.len], [0, 1, 1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const top = s.capPos !== 'bottom';
  return (
    <Canvas>
      <AbsoluteFill style={{opacity: o}}>
        <ClipFill clip={s.clip!} />
        <AbsoluteFill style={{background: top
          ? 'linear-gradient(to bottom, #F5F5F7 0%, rgba(245,245,247,0.97) 17%, rgba(245,245,247,0) 41%)'
          : 'linear-gradient(to top, #F5F5F7 0%, rgba(245,245,247,0.97) 17%, rgba(245,245,247,0) 41%)'}} />
        <AbsoluteFill style={{
          justifyContent: top ? 'flex-start' : 'flex-end', alignItems: 'center',
          padding: top ? '62px 80px 0' : '0 80px 62px',
        }}>
          <Caption eyebrow={s.eyebrow} title={s.title} center size={80} />
        </AbsoluteFill>
        {s.emoji ? <EmojiBurst emoji={s.emoji} startAt={Math.round(s.len * 0.42)} /> : null}
      </AbsoluteFill>
      <CutFlash len={s.len} />
    </Canvas>
  );
};

// montage: many real screenshots fly in + settle into an overlapping grid, slow zoom
const MONTAGE_SHOTS = [
  '11-home', '14-assistant-riz', '16-rewards', '13-pay', '23-analytics',
  '27-card-studio', '24-grow-savings', '12-cards', '21-pay-qr', '32-rewards-redeem-store',
  '18-pay-split-bill', '22-exchange',
];
const MontageScene: React.FC<{s: Scene}> = ({s}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const o = interpolate(frame, [0, 8, s.len - 10, s.len], [0, 1, 1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const zoom = interpolate(frame, [0, s.len], [1.18, 1.0], {extrapolateRight: 'clamp'});
  const cols = 4, rows = 3, gapX = 470, gapY = 380;
  return (
    <Canvas>
      <AbsoluteFill style={{opacity: o, justifyContent: 'center', alignItems: 'center'}}>
        <div style={{position: 'relative', width: 1, height: 1, transform: `scale(${zoom})`}}>
          {MONTAGE_SHOTS.map((name, i) => {
            const col = i % cols, row = Math.floor(i / cols);
            const x = (col - (cols - 1) / 2) * gapX + (random(`mx${i}`) - 0.5) * 60;
            const y = (row - (rows - 1) / 2) * gapY + (random(`my${i}`) - 0.5) * 60;
            const delay = i * 2.2;
            const sp = spring({frame: frame - delay, fps, config: {damping: 18, stiffness: 140, mass: 1}});
            const fromA = (i / MONTAGE_SHOTS.length) * Math.PI * 2;
            const fx = Math.cos(fromA) * 1400 * (1 - sp);
            const fy = Math.sin(fromA) * 1000 * (1 - sp);
            const rot = (random(`mr${i}`) - 0.5) * 16 * sp;
            return (
              <div key={name} style={{
                position: 'absolute', left: 0, top: 0,
                width: 256, height: 556, marginLeft: -128, marginTop: -278,
                transform: `translate(${x + fx}px,${y + fy}px) rotate(${rot}deg) scale(${0.6 + sp * 0.4})`,
                opacity: sp,
                borderRadius: 30, overflow: 'hidden',
                boxShadow: '0 30px 60px rgba(0,0,0,0.18), 0 6px 14px rgba(0,0,0,0.12)',
                border: '6px solid #111',
              }}>
                <Img src={staticFile('shots/' + name + '.png')} style={{width: '100%', height: '100%', objectFit: 'cover'}} />
              </div>
            );
          })}
        </div>
      </AbsoluteFill>
      <AbsoluteFill style={{background: 'linear-gradient(to bottom, #F5F5F7 0%, rgba(245,245,247,0.92) 16%, rgba(245,245,247,0) 38%)', opacity: o}} />
      <AbsoluteFill style={{justifyContent: 'flex-start', alignItems: 'center', padding: '62px 80px 0', opacity: o}}>
        <Caption title={s.title} center size={78} />
      </AbsoluteFill>
      <CutFlash len={s.len} />
    </Canvas>
  );
};

// outro: slot-machine word + logo + CTA
const SLOT_WORDS = ['gets you', 'is social', 'pays you back', 'levels up with you'];
const OutroScene: React.FC<{s: Scene}> = ({s}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const o = interpolate(frame, [0, 10], [0, 1], {extrapolateRight: 'clamp'});

  // slot machine: scroll through words, snap to last
  const lineH = 116;
  const settleAt = 7 * B; // when it locks
  const idxFloat = interpolate(frame, [6, settleAt], [0, SLOT_WORDS.length - 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const ease = frame < settleAt ? idxFloat : SLOT_WORDS.length - 1;
  const yOff = -(ease) * lineH;

  // logo + cta appear after the lock
  const lockT = frame - (settleAt + 6);
  const logoS = spring({frame: lockT, fps, config: {damping: 12, stiffness: 200}});
  const ctaO = interpolate(lockT, [16, 34], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const showFinal = frame > settleAt + 2;

  return (
    <Canvas>
      <AbsoluteFill style={{opacity: o, justifyContent: 'center', alignItems: 'center', flexDirection: 'column'}}>
        {!showFinal || logoS < 0.02 ? (
          <div style={{display: 'flex', alignItems: 'baseline', gap: 22, fontFamily, fontWeight: 800, fontSize: 92, color: C.ink, letterSpacing: '-0.035em'}}>
            <span>Money that</span>
            <div style={{height: lineH, overflow: 'hidden', display: 'inline-block', position: 'relative', minWidth: 760, textAlign: 'left'}}>
              <div style={{transform: `translateY(${yOff}px)`}}>
                {SLOT_WORDS.map((w, i) => (
                  <div key={w} style={{height: lineH, lineHeight: `${lineH}px`, color: i === SLOT_WORDS.length - 1 ? C.goldDeep : C.ink}}>{w}.</div>
                ))}
              </div>
            </div>
          </div>
        ) : (
          <AbsoluteFill style={{justifyContent: 'center', alignItems: 'center', gap: 14}}>
            <div style={{transform: `scale(${0.7 + logoS * 0.3})`, filter: 'drop-shadow(0 20px 50px rgba(248,208,31,0.35))'}}>
              <RyzeMark size={240} />
            </div>
            <div style={{fontFamily, fontWeight: 800, fontSize: 100, color: C.ink, letterSpacing: '-0.04em', transform: `translateY(${(1 - logoS) * 14}px)`}}>Ryze</div>
            <div style={{fontFamily, fontWeight: 700, fontSize: 30, color: C.ink, letterSpacing: '-0.01em', opacity: ctaO, marginTop: 4}}>Money that levels up with you.</div>
            <div style={{fontFamily, fontWeight: 600, fontSize: 22, color: C.faint, letterSpacing: '0.04em', opacity: ctaO, marginTop: 18}}>JunctionX Tirana 2026 · Raiffeisen</div>
          </AbsoluteFill>
        )}
      </AbsoluteFill>
    </Canvas>
  );
};

// ===================================================================
export const RyzeKeynote: React.FC = () => (
  <AbsoluteFill style={{backgroundColor: C.bg, fontFamily}}>
    {/* MUSIC SLOT — drop a 120 BPM track at public/music.mp3 and uncomment:
    <Audio src={staticFile('music.mp3')} /> */}
    {SCENES.map((s, i) => (
      <Sequence key={i} from={STARTS[i]} durationInFrames={s.len}>
        {s.kind === 'broll' ? <BrollScene s={s} /> :
         s.kind === 'logo' ? <LogoScene s={s} /> :
         s.kind === 'montage' ? <MontageScene s={s} /> :
         s.kind === 'outro' ? <OutroScene s={s} /> :
         <AppScene s={s} />}
      </Sequence>
    ))}
  </AbsoluteFill>
);
