// Simplified, colorable Raiffeisen Giebelkreuz mark for embossing inside illustrations.
// The canonical, pixel-perfect lockup uses the official PNG (see Logo.tsx).
import Svg, { G, Rect } from 'react-native-svg';

import { C } from '@/constants/brand';

export function GiebelkreuzMark({ size = 24, color = C.onAccent }: { size?: number; color?: string }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 100 100">
      <G fill={color}>
        <Rect x="41" y="6" width="18" height="88" rx="3" transform="rotate(45 50 50)" />
        <Rect x="41" y="6" width="18" height="88" rx="3" transform="rotate(-45 50 50)" />
      </G>
    </Svg>
  );
}
