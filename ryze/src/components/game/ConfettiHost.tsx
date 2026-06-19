// Restrained reward feedback: a brief confetti burst + a hairline toast pill.
// Disciplined palette (yellow + white + grey) so it reads premium, not noisy.
import ConfettiCannon from 'react-native-confetti-cannon';
import { useEffect, useRef, useState } from 'react';
import { Dimensions, StyleSheet, View } from 'react-native';
import Animated, { FadeInUp, FadeOutUp } from 'react-native-reanimated';

import { C, R, T } from '@/constants/brand';
import { useGame } from '@/game/store';
import { Txt } from '@/components/game/ui';

const { width } = Dimensions.get('window');

export function ConfettiHost() {
  const nonce = useGame((s) => s.celebrateNonce);
  const toast = useGame((s) => s.toast);
  const clearToast = useGame((s) => s.clearToast);
  const [burst, setBurst] = useState(0);
  const first = useRef(true);

  useEffect(() => {
    if (first.current) { first.current = false; return; }
    setBurst((b) => b + 1);
    const tm = setTimeout(() => clearToast(), 2200);
    return () => clearTimeout(tm);
  }, [nonce, clearToast]);

  return (
    <View pointerEvents="none" style={StyleSheet.absoluteFill}>
      {burst > 0 && (
        <ConfettiCannon
          key={burst}
          count={70}
          origin={{ x: width / 2, y: -20 }}
          fadeOut
          autoStart
          explosionSpeed={400}
          fallSpeed={2700}
          colors={[C.accent, C.white, C.stone, C.accentPressed]}
        />
      )}
      {toast && (
        <Animated.View entering={FadeInUp} exiting={FadeOutUp} style={styles.toast}>
          <Txt variant="bodyBold" numberOfLines={1} style={{ maxWidth: 200 }}>{toast.label}</Txt>
          <View style={{ flexDirection: 'row', gap: 12 }}>
            {toast.xp > 0 && <Txt variant="bodyBold" color={C.pos}>+{toast.xp} XP</Txt>}
            {toast.coins !== 0 && (
              <Txt variant="bodyBold" color={toast.coins < 0 ? C.onDarkMute : C.accent}>
                {toast.coins > 0 ? '+' : ''}{toast.coins} coins
              </Txt>
            )}
          </View>
        </Animated.View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  toast: {
    position: 'absolute', top: 56, alignSelf: 'center', flexDirection: 'row', alignItems: 'center', gap: 14,
    backgroundColor: C.surfaceElevated, borderWidth: 1, borderColor: C.hairline,
    paddingVertical: 12, paddingHorizontal: 18, borderRadius: R.full,
  },
});
