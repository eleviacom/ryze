// Onboarding scene illustrations — pure react-native-svg, brand palette, no shadows.
// Most are static (premium, calm); the liveness ring sweeps and the success seal pops.
import { useEffect } from 'react';
import { View } from 'react-native';
import Animated, { Easing, useAnimatedProps, useAnimatedStyle, useSharedValue, withRepeat, withSequence, withTiming } from 'react-native-reanimated';
import Svg, { Circle, Defs, G, Line, Path, RadialGradient, Rect, Stop } from 'react-native-svg';

import { C } from '@/constants/brand';
import { GiebelkreuzMark } from '@/components/brand/Giebelkreuz';

const AC = Animated.createAnimatedComponent(Circle);

function Frame({ size, children }: { size: number; children: React.ReactNode }) {
  return <View style={{ width: size, height: size, alignItems: 'center', justifyContent: 'center' }}>{children}</View>;
}

/** Welcome — isometric stack of Giebelkreuz coins with a glow + sparks. */
export function CoinStack({ size = 240 }: { size?: number }) {
  return (
    <Frame size={size}>
      <Svg width={size} height={size} viewBox="0 0 200 200">
        <Defs>
          <RadialGradient id="glow" cx="50%" cy="45%" r="55%">
            <Stop offset="0" stopColor={C.accent} stopOpacity="0.22" />
            <Stop offset="1" stopColor={C.accent} stopOpacity="0" />
          </RadialGradient>
        </Defs>
        <Circle cx="100" cy="95" r="92" fill="url(#glow)" />
        {/* coin sides + tops, stacked */}
        {[130, 112, 94].map((cy, i) => (
          <G key={cy}>
            <Path d={`M44 ${cy} a56 20 0 0 0 112 0 v16 a56 20 0 0 1 -112 0 z`} fill={C.accentPressed} />
            <Path d={`M44 ${cy} a56 20 0 0 0 112 0 v16 a56 20 0 0 1 -112 0 z`} fill={C.accentPressed} opacity={0.5} />
            <Path d={`M44 ${cy} a56 20 0 1 0 112 0 a56 20 0 1 0 -112 0 z`} fill={C.accent} />
            {i === 2 && (
              <G transform="translate(74 74) scale(0.52)">
                <GiebelkreuzMark size={100} color={C.onAccent} />
              </G>
            )}
          </G>
        ))}
        {/* sparks */}
        <Rect x="40" y="44" width="9" height="9" rx="2" fill={C.accent} transform="rotate(45 44 48)" />
        <Rect x="150" y="58" width="6" height="6" rx="1.5" fill={C.onDarkMute} transform="rotate(45 153 61)" />
      </Svg>
    </Frame>
  );
}

/** Open account — phone with a yellow card sliding out + ZERO-fees dot. */
export function OpenAccountPhone({ size = 240 }: { size?: number }) {
  return (
    <Frame size={size}>
      <Svg width={size} height={size} viewBox="0 0 200 200">
        <Defs>
          <RadialGradient id="pglow" cx="50%" cy="45%" r="55%">
            <Stop offset="0" stopColor={C.accent} stopOpacity="0.16" />
            <Stop offset="1" stopColor={C.accent} stopOpacity="0" />
          </RadialGradient>
        </Defs>
        <Circle cx="100" cy="95" r="92" fill="url(#pglow)" />
        {/* phone */}
        <Rect x="62" y="28" width="76" height="150" rx="18" fill={C.surfaceElevated} stroke={C.hairline} strokeWidth="1" />
        <Rect x="70" y="40" width="60" height="120" rx="10" fill={C.surfaceDeep} />
        <Rect x="88" y="33" width="24" height="4" rx="2" fill={C.hairline} />
        {/* yellow card sliding out */}
        <G transform="rotate(-14 130 110)">
          <Rect x="96" y="88" width="86" height="54" rx="10" fill={C.accent} />
          <G transform="translate(104 96) scale(0.2)"><GiebelkreuzMark size={100} color={C.onAccent} /></G>
          <Rect x="106" y="122" width="46" height="5" rx="2.5" fill="#00000033" />
          <Rect x="106" y="131" width="30" height="5" rx="2.5" fill="#00000022" />
        </G>
        {/* ZERO fees dot */}
        <Circle cx="150" cy="60" r="13" fill={C.surfaceElevated} stroke={C.pos} strokeWidth="2" />
        <Path d="M144 60 l4 4 l8 -9" stroke={C.pos} strokeWidth="2.4" fill="none" strokeLinecap="round" strokeLinejoin="round" />
      </Svg>
    </Frame>
  );
}

/** Do more — a Giebelkreuz hub with four capability satellites. */
export function DoMoreOrbit({ size = 240 }: { size?: number }) {
  const sat = (cx: number, cy: number, glyph: React.ReactNode) => (
    <G>
      <Line x1="100" y1="100" x2={cx} y2={cy} stroke={C.hairline} strokeWidth="1" />
      <Circle cx={cx} cy={cy} r="20" fill={C.surfaceElevated} stroke={C.hairline} strokeWidth="1" />
      {glyph}
    </G>
  );
  return (
    <Frame size={size}>
      <Svg width={size} height={size} viewBox="0 0 200 200">
        {sat(46, 50, <Path d="M40 50 h12 M48 46 l5 4 l-5 4" stroke={C.onDarkMute} strokeWidth="2.2" fill="none" strokeLinecap="round" strokeLinejoin="round" />)}
        {sat(154, 50, <Path d="M148 47 h12 M148 53 h12 M150 44 l-3 3 l3 3 M158 50 l3 3 l-3 3" stroke={C.onDarkMute} strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round" />)}
        {sat(46, 150, <G><Rect x="38" y="144" width="16" height="13" rx="2" fill="none" stroke={C.onDarkMute} strokeWidth="2" /><Line x1="38" y1="149" x2="54" y2="149" stroke={C.onDarkMute} strokeWidth="2" /></G>)}
        {sat(154, 150, <Path d="M154 142 l3 7 l7 0.5 l-5.5 4.5 l2 7 l-6.5 -4 l-6.5 4 l2 -7 l-5.5 -4.5 l7 -0.5 z" fill={C.accent} />)}
        <Circle cx="100" cy="100" r="34" fill={C.accent} />
        <G transform="translate(74 74) scale(0.52)"><GiebelkreuzMark size={100} color={C.onAccent} /></G>
      </Svg>
    </Frame>
  );
}

/** Identity intro — trust shield carrying the Giebelkreuz + a check badge. */
export function SecurityShield({ size = 200 }: { size?: number }) {
  return (
    <Frame size={size}>
      <Svg width={size} height={size} viewBox="0 0 200 200">
        <Path d="M100 26 L156 48 V104 C156 140 130 162 100 174 C70 162 44 140 44 104 V48 Z"
          fill={C.surfaceElevated} stroke={C.hairline} strokeWidth="1.5" />
        <G transform="translate(70 64) scale(0.6)"><GiebelkreuzMark size={100} color={C.accent} /></G>
        <Circle cx="138" cy="138" r="20" fill={C.accent} />
        <Path d="M129 138 l6 6 l12 -13" stroke={C.onAccent} strokeWidth="3.4" fill="none" strokeLinecap="round" strokeLinejoin="round" />
      </Svg>
    </Frame>
  );
}

/** ID capture — ID card inside a yellow corner-bracket viewfinder. */
export function IdCard({ size = 220 }: { size?: number }) {
  const br = (d: string) => <Path d={d} stroke={C.accent} strokeWidth="3.5" fill="none" strokeLinecap="round" />;
  return (
    <Frame size={size}>
      <Svg width={size} height={size} viewBox="0 0 200 200">
        <Rect x="46" y="64" width="108" height="72" rx="10" fill={C.surfaceElevated} stroke={C.hairline} strokeWidth="1" />
        <Circle cx="72" cy="92" r="12" fill="rgba(255,255,255,0.1)" />
        <Path d="M64 116 a8 8 0 0 1 16 0 z" fill="rgba(255,255,255,0.1)" />
        <Rect x="94" y="82" width="46" height="6" rx="3" fill="rgba(255,255,255,0.12)" />
        <Rect x="94" y="96" width="38" height="6" rx="3" fill="rgba(255,255,255,0.09)" />
        <Rect x="94" y="110" width="44" height="6" rx="3" fill="rgba(255,255,255,0.09)" />
        {br('M34 64 v-10 a4 4 0 0 1 4 -4 h10')}
        {br('M166 64 v-10 a4 4 0 0 0 -4 -4 h-10')}
        {br('M34 136 v10 a4 4 0 0 0 4 4 h10')}
        {br('M166 136 v10 a4 4 0 0 1 -4 4 h-10')}
      </Svg>
    </Frame>
  );
}

/** Liveness — sweeping yellow ring around a neutral face outline. */
export function LivenessRing({ size = 200, active = true }: { size?: number; active?: boolean }) {
  const R = 70, C0 = 2 * Math.PI * R;
  const off = useSharedValue(0);
  useEffect(() => {
    if (active) off.value = withRepeat(withTiming(-C0, { duration: 1500, easing: Easing.linear }), -1);
  }, [active, off, C0]);
  const props = useAnimatedProps(() => ({ strokeDashoffset: off.value }));
  return (
    <Frame size={size}>
      <Svg width={size} height={size} viewBox="0 0 200 200">
        <Circle cx="100" cy="100" r={R} fill="none" stroke="rgba(255,255,255,0.12)" strokeWidth="6" />
        <AC cx="100" cy="100" r={R} fill="none" stroke={C.accent} strokeWidth="6" strokeLinecap="round"
          strokeDasharray={`${C0 * 0.28} ${C0}`} animatedProps={props} transform="rotate(-90 100 100)" />
        {/* neutral face */}
        <Circle cx="100" cy="92" r="20" fill="none" stroke={C.onDarkMute} strokeWidth="2.4" />
        <Path d="M70 150 a30 26 0 0 1 60 0" fill="none" stroke={C.onDarkMute} strokeWidth="2.4" strokeLinecap="round" />
      </Svg>
    </Frame>
  );
}

/** Notifications — bell with a yellow dot and soft sound waves. */
export function NotifyBell({ size = 200 }: { size?: number }) {
  return (
    <Frame size={size}>
      <Svg width={size} height={size} viewBox="0 0 200 200">
        <Path d="M100 52 c-20 0 -32 14 -32 34 c0 24 -8 30 -14 38 h92 c-6 -8 -14 -14 -14 -38 c0 -20 -12 -34 -32 -34 z"
          fill={C.surfaceElevated} stroke={C.hairline} strokeWidth="1.5" />
        <Path d="M88 124 a12 12 0 0 0 24 0" fill="none" stroke={C.onDarkMute} strokeWidth="2.4" strokeLinecap="round" />
        <Circle cx="100" cy="46" r="5" fill={C.onDarkMute} />
        <Circle cx="132" cy="60" r="11" fill={C.accent} />
        <Path d="M150 60 a20 20 0 0 0 -6 -14 M158 60 a30 30 0 0 0 -9 -21" fill="none" stroke="rgba(255,255,255,0.18)" strokeWidth="2.4" strokeLinecap="round" />
      </Svg>
    </Frame>
  );
}

/** Success — Giebelkreuz seal that pops + a drawn-on ring. */
export function SuccessSeal({ size = 200 }: { size?: number }) {
  const scale = useSharedValue(0.6);
  useEffect(() => {
    scale.value = withSequence(withTiming(1.08, { duration: 320, easing: Easing.out(Easing.back(2)) }), withTiming(1, { duration: 160 }));
  }, [scale]);
  const astyle = useAnimatedStyle(() => ({ transform: [{ scale: scale.value }] }));
  return (
    <Frame size={size}>
      <Animated.View style={astyle}>
        <Svg width={size} height={size} viewBox="0 0 200 200">
          <Defs>
            <RadialGradient id="sglow" cx="50%" cy="50%" r="55%">
              <Stop offset="0" stopColor={C.accent} stopOpacity="0.25" />
              <Stop offset="1" stopColor={C.accent} stopOpacity="0" />
            </RadialGradient>
          </Defs>
          <Circle cx="100" cy="100" r="96" fill="url(#sglow)" />
          <Circle cx="100" cy="100" r="64" fill="none" stroke={C.accent} strokeWidth="3" opacity={0.5} />
          <Rect x="58" y="58" width="84" height="84" rx="24" fill={C.accent} />
          <G transform="translate(72 72) scale(0.56)"><GiebelkreuzMark size={100} color={C.onAccent} /></G>
        </Svg>
      </Animated.View>
    </Frame>
  );
}

export const ILLUSTRATIONS = {
  coins: CoinStack, phone: OpenAccountPhone, orbit: DoMoreOrbit, shield: SecurityShield,
  idcard: IdCard, liveness: LivenessRing, bell: NotifyBell, seal: SuccessSeal,
} as const;
