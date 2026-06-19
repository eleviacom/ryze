// Rewards — spend coins. Closes the earn -> spend loop.
import { Ionicons } from '@expo/vector-icons';
import { ScrollView, View } from 'react-native';

import { C, S } from '@/constants/brand';
import { Button, Card, FeaturedCard, IconTile, Screen, Txt } from '@/components/game/ui';
import { REWARDS } from '@/game/data';
import { levelInfo, tierForLevel, TIERS } from '@/game/engine';
import { useGame } from '@/game/store';

const ICONS: Record<string, { name: keyof typeof Ionicons.glyphMap; color: string }> = {
  'r-spotify': { name: 'musical-notes', color: C.teal },
  'r-coffee': { name: 'cafe', color: C.orange },
  'r-cinema': { name: 'film', color: C.pink },
  'r-cashback': { name: 'rocket', color: C.accent },
  'r-data': { name: 'cellular', color: C.blue },
  'r-merch': { name: 'shirt', color: C.cobalt },
};

export default function Rewards() {
  const { coins, xp, redeemed } = useGame();
  const redeem = useGame((s) => s.redeem);
  const tierIndex = tierForLevel(levelInfo(xp).level).index;

  return (
    <Screen>
      <ScrollView contentContainerStyle={{ padding: S.xl, paddingBottom: 96 }} showsVerticalScrollIndicator={false}>
        <Txt variant="displayLg" style={{ marginBottom: S.lg }}>Rewards</Txt>

        <FeaturedCard style={{ marginBottom: S.xl }}>
          <Txt variant="eyebrow" color="#00000088" upper>Your balance</Txt>
          <View style={{ flexDirection: 'row', alignItems: 'flex-end', gap: 8, marginTop: 6 }}>
            <Txt variant="displayXl" color={C.onAccent}>{coins.toLocaleString()}</Txt>
            <Txt variant="h3" color="#000000b0" style={{ marginBottom: 8 }}>coins</Txt>
          </View>
          <Txt variant="body" color="#000000b0" style={{ marginTop: 4 }}>Earn coins from missions, streaks and invites.</Txt>
        </FeaturedCard>

        <Txt variant="h3" style={{ marginBottom: 12 }}>Redeem</Txt>
        {REWARDS.map((r) => {
          const owned = redeemed.includes(r.id);
          const tierLocked = (r.tierMin ?? 0) > tierIndex;
          const afford = coins >= r.cost;
          const disabled = owned || tierLocked || !afford;
          const ic = ICONS[r.id];
          return (
            <Card key={r.id} style={{ marginBottom: 10, flexDirection: 'row', alignItems: 'center', gap: 14 }}>
              <IconTile name={ic.name} color={ic.color} />
              <View style={{ flex: 1 }}>
                <Txt variant="bodyBold">{r.title}</Txt>
                <Txt variant="bodySm" color={C.onDarkMute}>{r.brand}</Txt>
              </View>
              {owned ? (
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5 }}>
                  <Ionicons name="checkmark-circle" size={18} color={C.pos} />
                  <Txt variant="buttonSm" color={C.onDarkMute}>Owned</Txt>
                </View>
              ) : tierLocked ? (
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5 }}>
                  <Ionicons name="lock-closed" size={14} color={C.onDarkFaint} />
                  <Txt variant="buttonSm" color={C.onDarkFaint}>{TIERS[r.tierMin ?? 0].name}</Txt>
                </View>
              ) : (
                <Button label={`${r.cost}`} size="sm" variant="primary" disabled={!afford} onPress={() => redeem(r.id)} />
              )}
            </Card>
          );
        })}
      </ScrollView>
    </Screen>
  );
}
