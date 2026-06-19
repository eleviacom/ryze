// Profile — identity, tier, badges, lifetime stats.
import { Ionicons } from '@expo/vector-icons';
import { ScrollView, View } from 'react-native';

import { C, R, S } from '@/constants/brand';
import { Button, Card, ProgressBar, Screen, Txt } from '@/components/game/ui';
import { levelInfo, tierForLevel } from '@/game/engine';
import { useGame } from '@/game/store';

const BADGE_ICONS: Record<string, keyof typeof Ionicons.glyphMap> = {
  'b-first-invite': 'people', 'b-streak7': 'flame', 'b-level10': 'trophy',
  'b-onboard': 'checkmark-done', 'b-squad': 'people-circle', 'b-saver': 'wallet',
};

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <View style={{ flexBasis: '31%', backgroundColor: C.surfaceElevated, borderRadius: R.md, borderWidth: 1, borderColor: C.hairline, padding: 14, marginBottom: 10 }}>
      <Txt variant="h2">{value}</Txt>
      <Txt variant="caption" color={C.onDarkMute} style={{ marginTop: 2 }}>{label}</Txt>
    </View>
  );
}

export default function Profile() {
  const { xp, coins, streak, invites, savedTotal, badges, name } = useGame();
  const reset = useGame((s) => s.reset);
  const li = levelInfo(xp);
  const { tier } = tierForLevel(li.level);
  const earned = badges.filter((b) => b.earned).length;

  return (
    <Screen>
      <ScrollView contentContainerStyle={{ padding: S.xl, paddingBottom: 96 }} showsVerticalScrollIndicator={false}>
        <View style={{ alignItems: 'center', marginBottom: S.xl }}>
          <View style={{ width: 84, height: 84, borderRadius: 42, backgroundColor: C.surfaceElevated, borderWidth: 1, borderColor: C.hairline, alignItems: 'center', justifyContent: 'center' }}>
            <Txt variant="displayLg">{name.slice(0, 1).toUpperCase()}</Txt>
          </View>
          <Txt variant="h1" style={{ marginTop: 12 }}>{name}</Txt>
          <Txt variant="bodyBold" color={C.accent} style={{ marginTop: 2 }}>{tier.name} · Level {li.level}</Txt>
        </View>

        <Card style={{ marginBottom: S.xl }}>
          <Txt variant="bodySm" color={C.onDarkMute} style={{ marginBottom: 10 }}>{tier.perk}</Txt>
          <ProgressBar progress={li.progress} />
          <Txt variant="caption" color={C.onDarkFaint} style={{ marginTop: 8 }}>{li.intoLevel}/{li.needed} XP to level {li.level + 1}</Txt>
        </Card>

        <Txt variant="h3" style={{ marginBottom: 12 }}>Stats</Txt>
        <View style={{ flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-between' }}>
          <Stat label="Total XP" value={`${xp}`} />
          <Stat label="Coins" value={`${coins}`} />
          <Stat label="Streak" value={`${streak}d`} />
          <Stat label="Invites" value={`${invites}`} />
          <Stat label="Saved" value={`EUR ${savedTotal}`} />
          <Stat label="Badges" value={`${earned}/${badges.length}`} />
        </View>

        <Txt variant="h3" style={{ marginBottom: 12, marginTop: 6 }}>Badges</Txt>
        <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 10 }}>
          {badges.map((b) => (
            <Card key={b.id} style={{ flexBasis: '47%', alignItems: 'center', opacity: b.earned ? 1 : 0.45, padding: 16 }}>
              <View style={{ width: 48, height: 48, borderRadius: 24, alignItems: 'center', justifyContent: 'center', backgroundColor: b.earned ? 'rgba(255,230,0,0.12)' : 'rgba(255,255,255,0.05)', marginBottom: 8 }}>
                <Ionicons name={b.earned ? BADGE_ICONS[b.id] : 'lock-closed'} size={22} color={b.earned ? C.accent : C.onDarkFaint} />
              </View>
              <Txt variant="bodyBold">{b.title}</Txt>
              <Txt variant="caption" color={C.onDarkMute} style={{ textAlign: 'center', marginTop: 2 }}>{b.desc}</Txt>
            </Card>
          ))}
        </View>

        <View style={{ height: S.xl }} />
        <Button label="Reset demo" variant="outline" block onPress={() => reset()} />
      </ScrollView>
    </Screen>
  );
}
