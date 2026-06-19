// Official Raiffeisen Giebelkreuz mark (dark on yellow). Asset is the real logo.
import { Image } from 'expo-image';
import { View } from 'react-native';

import { R } from '@/constants/brand';

const SRC = require('@/assets/images/raiffeisen-logo.png');

/** The yellow logo tile. Rounded to read as an app glyph on the black canvas. */
export function Logo({ size = 56, radius }: { size?: number; radius?: number }) {
  return (
    <View style={{ width: size, height: size, borderRadius: radius ?? Math.round(size * 0.28), overflow: 'hidden' }}>
      <Image source={SRC} style={{ width: size, height: size }} contentFit="cover" />
    </View>
  );
}
