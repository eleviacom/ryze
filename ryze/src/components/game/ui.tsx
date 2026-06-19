// Ryze UI kit — Revolut component language. Pills, hairlines, no shadows.
import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { ReactNode, useEffect } from 'react';
import { Platform, Pressable, StyleSheet, Text, TextProps, View, ViewStyle } from 'react-native';
import Animated, { useAnimatedStyle, useSharedValue, withTiming } from 'react-native-reanimated';
import { SafeAreaView } from 'react-native-safe-area-context';

import { C, R, S, T } from '@/constants/brand';

function tap() {
  if (Platform.OS !== 'web') Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light).catch(() => {});
}

type TVariant = keyof typeof T;
export function Txt({
  variant = 'body', color = C.onDark, upper, style, ...rest
}: TextProps & { variant?: TVariant; color?: string; upper?: boolean }) {
  return (
    <Text
      style={[T[variant], { color }, upper && { textTransform: 'uppercase' }, style]}
      {...rest}
    />
  );
}

export function Screen({ children, bg = C.black }: { children: ReactNode; bg?: string }) {
  return (
    <View style={{ flex: 1, backgroundColor: bg }}>
      <SafeAreaView edges={['top']} style={{ flex: 1 }}>{children}</SafeAreaView>
    </View>
  );
}

export function Card({ children, style, inset }: { children: ReactNode; style?: ViewStyle; inset?: boolean }) {
  return (
    <View style={[styles.card, inset && { backgroundColor: C.surfaceDeep }, style]}>{children}</View>
  );
}

/** The single yellow surface — featured/hero blocks only. Black content. */
export function FeaturedCard({ children, style }: { children: ReactNode; style?: ViewStyle }) {
  return <View style={[styles.card, { backgroundColor: C.accent, borderColor: C.accent }, style]}>{children}</View>;
}

type BtnVariant = 'primary' | 'dark' | 'soft' | 'outline';
export function Button({
  label, onPress, variant = 'primary', disabled, icon, size = 'lg', block,
}: {
  label: string; onPress: () => void; variant?: BtnVariant; disabled?: boolean;
  icon?: keyof typeof Ionicons.glyphMap; size?: 'lg' | 'sm'; block?: boolean;
}) {
  const map: Record<BtnVariant, { bg: string; fg: string; border?: string; pressed: string }> = {
    primary: { bg: C.white, fg: C.black, pressed: C.faint },
    dark: { bg: C.black, fg: C.white, pressed: '#222' },
    soft: { bg: C.surfaceElevated, fg: C.white, border: C.hairline, pressed: C.surfacePressed },
    outline: { bg: 'transparent', fg: C.white, border: C.onDark, pressed: 'rgba(255,255,255,0.08)' },
  };
  const v = map[variant];
  return (
    <Pressable
      onPress={() => { if (disabled) return; tap(); onPress(); }}
      style={({ pressed }) => [
        styles.btn,
        size === 'sm' && { height: 40, paddingHorizontal: 16 },
        block && { alignSelf: 'stretch' },
        { backgroundColor: pressed && !disabled ? v.pressed : v.bg, opacity: disabled ? 0.35 : 1 },
        v.border ? { borderWidth: 1, borderColor: v.border } : null,
      ]}>
      {icon ? <Ionicons name={icon} size={size === 'sm' ? 16 : 18} color={v.fg} /> : null}
      <Text style={[size === 'sm' ? T.buttonSm : T.button, { color: v.fg }]}>{label}</Text>
    </Pressable>
  );
}

/** Small filter/nav pill. */
export function Chip({ label, active, onPress }: { label: string; active?: boolean; onPress?: () => void }) {
  return (
    <Pressable onPress={() => { if (onPress) { tap(); onPress(); } }}
      style={[styles.chip, active ? { backgroundColor: C.white } : { backgroundColor: C.surfaceElevated, borderWidth: 1, borderColor: C.hairline }]}>
      <Text style={[T.buttonSm, { color: active ? C.black : C.onDarkMute }]}>{label}</Text>
    </Pressable>
  );
}

export function Tag({ label, feature }: { label: string; feature?: boolean }) {
  return (
    <View style={[styles.tag, feature ? { backgroundColor: C.accent } : { backgroundColor: 'rgba(255,255,255,0.08)' }]}>
      <Text style={[T.caption, { color: feature ? C.onAccent : C.onDarkMute }]}>{label}</Text>
    </View>
  );
}

/** Rounded icon tile — gives content "iconography" instead of raw emoji. */
export function IconTile({ name, color = C.accent, bg }: { name: keyof typeof Ionicons.glyphMap; color?: string; bg?: string }) {
  return (
    <View style={[styles.iconTile, { backgroundColor: bg ?? 'rgba(255,255,255,0.06)' }]}>
      <Ionicons name={name} size={20} color={color} />
    </View>
  );
}

export function ProgressBar({ progress, color = C.accent, height = 6 }: { progress: number; color?: string; height?: number }) {
  const w = useSharedValue(0);
  useEffect(() => { w.value = withTiming(Math.max(0, Math.min(1, progress)), { duration: 650 }); }, [progress, w]);
  const fill = useAnimatedStyle(() => ({ width: `${Math.max(2, w.value * 100)}%` }));
  return (
    <View style={[styles.track, { height }]}>
      <Animated.View style={[{ height, borderRadius: height, backgroundColor: color }, fill]} />
    </View>
  );
}

export function Divider() {
  return <View style={{ height: 1, backgroundColor: C.hairline }} />;
}

export const styles = StyleSheet.create({
  card: { backgroundColor: C.surfaceElevated, borderRadius: R.lg, padding: S.xl, borderWidth: 1, borderColor: C.hairline },
  btn: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8, height: 48, paddingHorizontal: 24, borderRadius: R.full },
  chip: { paddingHorizontal: 16, height: 36, borderRadius: R.full, alignItems: 'center', justifyContent: 'center' },
  tag: { paddingHorizontal: 12, paddingVertical: 5, borderRadius: R.full, alignSelf: 'flex-start' },
  iconTile: { width: 44, height: 44, borderRadius: R.md, alignItems: 'center', justifyContent: 'center' },
  track: { backgroundColor: 'rgba(255,255,255,0.12)', borderRadius: 999, overflow: 'hidden', width: '100%' },
});
