// Onboarding primitives — Revolut component language on the true-black canvas.
import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { ReactNode, useEffect, useRef, useState } from 'react';
import {
  KeyboardAvoidingView, Modal, Platform, Pressable, ScrollView, StyleSheet, Text, TextInput, View, ViewStyle,
} from 'react-native';
import Animated, { FadeIn, FadeInUp, FadeOut, useAnimatedStyle, useSharedValue, withRepeat, withSequence, withTiming } from 'react-native-reanimated';

import { C, FONTS, R, S, T } from '@/constants/brand';
import { Button, Txt } from '@/components/game/ui';
import { Logo } from '@/components/brand/Logo';
import { LegalDoc, PROTOTYPE_DISCLAIMER } from '@/onboarding/legal';
import { askRiz, Msg } from '@/buddy/client';
import { stepWhy } from '@/buddy/system-prompt';

const tap = () => { if (Platform.OS !== 'web') Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light).catch(() => {}); };

/* ── Progress segments (top, Revolut-style) ─────────────────────────── */
export function ProgressSegments({ count, active }: { count: number; active: number }) {
  return (
    <View style={{ flexDirection: 'row', gap: 6 }}>
      {Array.from({ length: count }).map((_, i) => (
        <View key={i} style={{ flex: 1, height: 3, borderRadius: 999, backgroundColor: i <= active ? C.accent : 'rgba(255,255,255,0.16)' }} />
      ))}
    </View>
  );
}

/* ── Text field (with animated focus border + error shake) ───────────── */
export function Field({
  label, value, onChangeText, keyboardType, placeholder, prefix, error, autoFocus,
}: {
  label: string; value: string; onChangeText: (s: string) => void;
  keyboardType?: 'default' | 'email-address' | 'number-pad' | 'phone-pad';
  placeholder?: string; prefix?: string; error?: boolean; autoFocus?: boolean;
}) {
  const [focused, setFocused] = useState(false);
  const shake = useSharedValue(0);
  useEffect(() => { if (error) shake.value = withSequence(withTiming(-6, { duration: 50 }), withTiming(6, { duration: 50 }), withTiming(0, { duration: 50 })); }, [error, shake]);
  const aStyle = useAnimatedStyle(() => ({ transform: [{ translateX: shake.value }] }));
  return (
    <View style={{ marginBottom: S.md }}>
      <Txt variant="caption" color={C.onDarkMute} style={{ marginBottom: 8 }}>{label}</Txt>
      <Animated.View style={[styles.input, aStyle, { borderColor: error ? C.danger : focused ? C.white : C.hairline }]}>
        {prefix ? <Text style={[T.body, { color: C.onDark, marginRight: 8 }]}>{prefix}</Text> : null}
        <TextInput
          value={value} onChangeText={onChangeText} placeholder={placeholder} placeholderTextColor={C.onDarkFaint}
          keyboardType={keyboardType} autoFocus={autoFocus} autoCapitalize={keyboardType === 'email-address' ? 'none' : 'sentences'}
          onFocus={() => setFocused(true)} onBlur={() => setFocused(false)}
          style={{ flex: 1, color: C.onDark, fontFamily: FONTS.regular, fontSize: 17, padding: 0 }}
        />
      </Animated.View>
    </View>
  );
}

/* ── Select / country picker (modal list) ───────────────────────────── */
export function SelectField({ label, value, options, onSelect, placeholder }: { label: string; value: string; options: string[]; onSelect: (v: string) => void; placeholder?: string }) {
  const [open, setOpen] = useState(false);
  return (
    <View style={{ marginBottom: S.md }}>
      <Txt variant="caption" color={C.onDarkMute} style={{ marginBottom: 8 }}>{label}</Txt>
      <Pressable onPress={() => { tap(); setOpen(true); }} style={[styles.input, { justifyContent: 'space-between' }]}>
        <Text style={[T.body, { color: value ? C.onDark : C.onDarkFaint }]}>{value || placeholder || 'Select'}</Text>
        <Ionicons name="chevron-down" size={18} color={C.onDarkMute} />
      </Pressable>
      <Modal visible={open} transparent animationType="slide" onRequestClose={() => setOpen(false)}>
        <Pressable style={styles.backdrop} onPress={() => setOpen(false)} />
        <View style={styles.sheet}>
          <Txt variant="h3" style={{ marginBottom: 12 }}>{label}</Txt>
          <ScrollView style={{ maxHeight: 360 }}>
            {options.map((o) => (
              <Pressable key={o} onPress={() => { tap(); onSelect(o); setOpen(false); }} style={styles.optRow}>
                <Text style={[T.body, { color: C.onDark }]}>{o}</Text>
                {value === o && <Ionicons name="checkmark" size={18} color={C.accent} />}
              </Pressable>
            ))}
          </ScrollView>
        </View>
      </Modal>
    </View>
  );
}

/* ── Yes / No toggle ────────────────────────────────────────────────── */
export function Toggle({ label, value, onChange }: { label: string; value: boolean; onChange: (v: boolean) => void }) {
  return (
    <View style={{ marginBottom: S.md }}>
      <Txt variant="caption" color={C.onDarkMute} style={{ marginBottom: 8 }}>{label}</Txt>
      <View style={{ flexDirection: 'row', gap: 8 }}>
        {[{ k: false, l: 'No' }, { k: true, l: 'Yes' }].map((o) => {
          const on = value === o.k;
          return (
            <Pressable key={o.l} onPress={() => { tap(); onChange(o.k); }}
              style={[styles.toggle, on ? { backgroundColor: C.white } : { backgroundColor: C.surfaceElevated, borderWidth: 1, borderColor: C.hairline }]}>
              <Text style={[T.bodyBold, { color: on ? C.black : C.onDarkMute }]}>{o.l}</Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

/* ── OTP input (6 cells) ────────────────────────────────────────────── */
export function OtpInput({ value, onChange, length = 6 }: { value: string; onChange: (s: string) => void; length?: number }) {
  const ref = useRef<TextInput>(null);
  return (
    <Pressable onPress={() => ref.current?.focus()} style={{ flexDirection: 'row', gap: 8 }}>
      {Array.from({ length }).map((_, i) => {
        const active = i === value.length;
        return (
          <View key={i} style={[styles.otpCell, { borderColor: active ? C.white : value[i] ? C.hairline : 'rgba(255,255,255,0.08)' }]}>
            <Text style={[T.h2, { color: C.onDark }]}>{value[i] ?? ''}</Text>
          </View>
        );
      })}
      <TextInput
        ref={ref} value={value} onChangeText={(t) => onChange(t.replace(/\D/g, '').slice(0, length))}
        keyboardType="number-pad" maxLength={length} autoFocus
        style={{ position: 'absolute', opacity: 0, width: 1, height: 1 }}
      />
    </Pressable>
  );
}

/* ── Consent row ────────────────────────────────────────────────────── */
export function ConsentRow({ checked, onToggle, label, onReadMore }: { checked: boolean; onToggle: () => void; label: string; onReadMore?: () => void }) {
  return (
    <Pressable onPress={() => { tap(); onToggle(); }} style={styles.consentRow}>
      <View style={[styles.checkbox, checked && { backgroundColor: C.accent, borderColor: C.accent }]}>
        {checked && <Ionicons name="checkmark" size={15} color={C.onAccent} />}
      </View>
      <View style={{ flex: 1 }}>
        <Text style={[T.bodySm, { color: C.onDark }]}>{label}</Text>
        {onReadMore && (
          <Text onPress={onReadMore} style={[T.bodySm, { color: C.accent, marginTop: 4 }]}>Read</Text>
        )}
      </View>
    </Pressable>
  );
}

/* ── Legal sheet (disclosures / why) ────────────────────────────────── */
export function LegalSheet({ open, onClose, doc }: { open: boolean; onClose: () => void; doc: LegalDoc | null }) {
  return (
    <Modal visible={open} transparent animationType="slide" onRequestClose={onClose}>
      <Pressable style={styles.backdrop} onPress={onClose} />
      <View style={[styles.sheet, { maxHeight: '82%' }]}>
        <Txt variant="h2" style={{ marginBottom: 14 }}>{doc?.title}</Txt>
        <ScrollView showsVerticalScrollIndicator={false}>
          {doc?.sections.map((sec, i) => (
            <View key={i} style={{ marginBottom: 16 }}>
              {sec.heading ? <Txt variant="bodyBold" style={{ marginBottom: 4 }}>{sec.heading}</Txt> : null}
              <Txt variant="bodySm" color={C.onDarkMute}>{sec.body}</Txt>
            </View>
          ))}
          <Txt variant="caption" color={C.onDarkFaint} style={{ marginTop: 4, marginBottom: 16 }}>{PROTOTYPE_DISCLAIMER}</Txt>
        </ScrollView>
        <Button label="Got it" variant="primary" block onPress={onClose} />
      </View>
    </Modal>
  );
}

/* ── KYC screen shell ───────────────────────────────────────────────── */
export function KycScreen({
  title, body, why, onWhy, onClose, progress, children, footer,
}: {
  title: string; body: string; why?: string; onWhy?: () => void; onClose: () => void;
  progress: number; children: ReactNode; footer: ReactNode;
}) {
  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={{ flex: 1 }}>
      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 12, marginBottom: 18 }}>
        <Pressable onPress={() => { tap(); onClose(); }} hitSlop={10}><Ionicons name="close" size={26} color={C.accent} /></Pressable>
        <View style={{ flex: 1 }}><View style={{ height: 3, borderRadius: 999, backgroundColor: 'rgba(255,255,255,0.12)' }}>
          <View style={{ width: `${Math.round(progress * 100)}%`, height: 3, borderRadius: 999, backgroundColor: C.accent }} />
        </View></View>
        <Logo size={26} />
      </View>
      <ScrollView contentContainerStyle={{ paddingBottom: 16 }} showsVerticalScrollIndicator={false} keyboardShouldPersistTaps="handled">
        <Txt variant="displayLg" style={{ marginBottom: 12 }}>{title}</Txt>
        <Txt variant="bodyLg" color={C.onDarkMute} style={{ marginBottom: why ? 6 : 22 }}>{body}</Txt>
        {why ? <Text onPress={onWhy} style={[T.bodyBold, { color: C.accent, marginBottom: 22 }]}>Why do we need it?</Text> : null}
        {children}
      </ScrollView>
      <View style={{ paddingTop: 10, gap: 10 }}>{footer}</View>
    </KeyboardAvoidingView>
  );
}

/* ── Riz buddy: FAB + chat sheet ────────────────────────────────────── */
export function AiBuddyButton({ onPress }: { onPress: () => void }) {
  const s = useSharedValue(1);
  useEffect(() => { s.value = withRepeat(withSequence(withTiming(1.08, { duration: 900 }), withTiming(1, { duration: 900 })), -1); }, [s]);
  const a = useAnimatedStyle(() => ({ transform: [{ scale: s.value }] }));
  return (
    <Animated.View style={[{ position: 'absolute', right: 18, bottom: 28 }, a]}>
      <Pressable onPress={() => { tap(); onPress(); }} style={styles.fab}>
        <Logo size={52} />
        <View style={styles.fabDot}><Text style={[T.caption, { color: C.onAccent, fontFamily: FONTS.bold }]}>?</Text></View>
      </Pressable>
    </Animated.View>
  );
}

export function AiBuddySheet({ open, onClose, stepId, name, stepTitle, seedWhy }: {
  open: boolean; onClose: () => void; stepId?: string; name?: string; stepTitle?: string; seedWhy?: boolean;
}) {
  const [msgs, setMsgs] = useState<Msg[]>([]);
  const [text, setText] = useState('');
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (open && msgs.length === 0) {
      const intro = (seedWhy && stepId && stepWhy(stepId))
        || "Hey, I'm Riz. I'll walk you through opening your account — nothing's submitted until you say so. Ask me to explain any step.";
      setMsgs([{ role: 'assistant', text: intro }]);
    }
    if (!open) { setMsgs([]); setText(''); }
  }, [open, seedWhy, stepId]); // eslint-disable-line react-hooks/exhaustive-deps

  const send = async () => {
    const q = text.trim();
    if (!q || busy) return;
    setText(''); setBusy(true);
    const history = msgs;
    setMsgs((m) => [...m, { role: 'user', text: q }]);
    const reply = await askRiz({ stepId, name, history, text: q });
    setMsgs((m) => [...m, { role: 'assistant', text: reply }]);
    setBusy(false);
  };

  return (
    <Modal visible={open} transparent animationType="slide" onRequestClose={onClose}>
      <Pressable style={styles.backdrop} onPress={onClose} />
      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
        <View style={[styles.sheet, { height: '82%' }]}>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10, marginBottom: 12 }}>
            <Logo size={34} />
            <View style={{ flex: 1 }}>
              <Txt variant="h3">Riz</Txt>
              {stepTitle ? <Txt variant="caption" color={C.onDarkFaint}>{stepTitle}</Txt> : null}
            </View>
            <Pressable onPress={onClose} hitSlop={10}><Ionicons name="close" size={24} color={C.onDarkMute} /></Pressable>
          </View>
          <ScrollView style={{ flex: 1 }} contentContainerStyle={{ paddingVertical: 8, gap: 10 }} showsVerticalScrollIndicator={false}>
            {msgs.map((m, i) => (
              <Animated.View key={i} entering={FadeInUp.duration(200)}
                style={[styles.bubble, m.role === 'user' ? { alignSelf: 'flex-end', backgroundColor: C.white } : { alignSelf: 'flex-start', backgroundColor: C.surfaceElevated, borderWidth: 1, borderColor: C.hairline }]}>
                <Text style={[T.body, { color: m.role === 'user' ? C.black : C.onDark }]}>{m.text}</Text>
              </Animated.View>
            ))}
            {busy && <Animated.View entering={FadeIn} exiting={FadeOut} style={[styles.bubble, { alignSelf: 'flex-start', backgroundColor: C.surfaceElevated, borderWidth: 1, borderColor: C.hairline }]}><Text style={[T.body, { color: C.onDarkFaint }]}>…</Text></Animated.View>}
          </ScrollView>
          <View style={{ flexDirection: 'row', gap: 8, alignItems: 'center', paddingTop: 8 }}>
            <View style={[styles.input, { flex: 1 }]}>
              <TextInput value={text} onChangeText={setText} placeholder="Ask Riz…" placeholderTextColor={C.onDarkFaint}
                onSubmitEditing={send} returnKeyType="send" style={{ flex: 1, color: C.onDark, fontFamily: FONTS.regular, fontSize: 16, padding: 0 }} />
            </View>
            <Pressable onPress={send} style={styles.sendBtn}><Ionicons name="arrow-up" size={20} color={C.black} /></Pressable>
          </View>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  input: { flexDirection: 'row', alignItems: 'center', backgroundColor: C.surfaceElevated, borderWidth: 1, borderColor: C.hairline, borderRadius: R.md, height: 56, paddingHorizontal: 16 },
  backdrop: { flex: 1, backgroundColor: 'rgba(0,0,0,0.6)' },
  sheet: { backgroundColor: C.surfaceElevated, borderTopLeftRadius: R.xl, borderTopRightRadius: R.xl, borderWidth: 1, borderColor: C.hairline, padding: 20, paddingBottom: 34 },
  optRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingVertical: 16, borderBottomWidth: 1, borderBottomColor: C.hairline },
  toggle: { flex: 1, height: 48, borderRadius: R.full, alignItems: 'center', justifyContent: 'center' },
  otpCell: { width: 46, height: 56, borderRadius: R.md, borderWidth: 1.5, backgroundColor: C.surfaceElevated, alignItems: 'center', justifyContent: 'center' },
  consentRow: { flexDirection: 'row', gap: 12, alignItems: 'flex-start', paddingVertical: 12 },
  checkbox: { width: 24, height: 24, borderRadius: 7, borderWidth: 1.5, borderColor: C.hairline, alignItems: 'center', justifyContent: 'center', marginTop: 1 },
  fab: { width: 56, height: 56, borderRadius: 18, alignItems: 'center', justifyContent: 'center' },
  fabDot: { position: 'absolute', top: -4, right: -4, width: 20, height: 20, borderRadius: 10, backgroundColor: C.accent, alignItems: 'center', justifyContent: 'center', borderWidth: 2, borderColor: C.black },
  bubble: { maxWidth: '86%', paddingVertical: 10, paddingHorizontal: 14, borderRadius: 18 },
  sendBtn: { width: 44, height: 44, borderRadius: 22, backgroundColor: C.accent, alignItems: 'center', justifyContent: 'center' },
});
