// Home — daily dashboard. Coins balance hero, streak, AI pick, daily loop.
import { Ionicons } from '@expo/vector-icons';
import { useEffect } from 'react';
import { ScrollView, View } from 'react-native';

import { C, S } from '@/constants/brand';
import { Button, Card, Divider, FeaturedCard, ProgressBar, Screen, Tag, Txt } from '@/components/game/ui';
import { MissionCard } from '@/components/game/MissionCard';
import { levelInfo, tierForLevel, todayKey } from '@/game/engine';
import { useGame } from '@/game/store';

export default function Home() {
  const { xp, coins, streak, name, missions, aiMission, lastCheckIn } = useGame();
  const dailyCheckIn = useGame((s) => s.dailyCheckIn);
  const generateAi = useGame((s) => s.generateAi);
  useEffect(() => { if (!aiMission) generateAi(); }, [aiMission, generateAi]);

  const li = levelInfo(xp);
  const { tier } = tierForLevel(li.level);
  const checkedToday = lastCheckIn === todayKey();
  const daily = missions.filter((m) => m.category === 'daily' && m.id !== 'd-checkin');

  return (
    <Screen>
      <ScrollView contentContainerStyle={{ padding: S.xl, paddingBottom: 96 }} showsVerticalScrollIndicator={false}>
        <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: S.xl }}>
          <View>
            <Txt variant="eyebrow" color={C.onDarkFaint} upper>Welcome back</Txt>
            <Txt variant="h1" style={{ marginTop: 2 }}>Hey, {name}</Txt>
          </View>
          <View style={{ width: 46, height: 46, borderRadius: 23, backgroundColor: C.surfaceElevated, borderWidth: 1, borderColor: C.hairline, alignItems: 'center', justifyContent: 'center' }}>
            <Txt variant="h3">{name.slice(0, 1).toUpperCase()}</Txt>
          </View>
        </View>

        {/* Coins balance hero */}
        <Card style={{ marginBottom: S.lg }}>
          <Txt variant="eyebrow" color={C.onDarkFaint} upper>Your coins</Txt>
          <View style={{ flexDirection: 'row', alignItems: 'flex-end', gap: 8, marginTop: 6 }}>
            <Txt variant="displayLg">{coins.toLocaleString()}</Txt>
            <Txt variant="h3" color={C.onDarkMute} style={{ marginBottom: 5 }}>coins</Txt>
          </View>
          <View style={{ marginVertical: S.lg }}><Divider /></View>
          <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
              <Txt variant="bodyBold">Level {li.level}</Txt>
              <Tag label={tier.name} />
            </View>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5 }}>
              <Ionicons name="flame" size={16} color={C.accent} />
              <Txt variant="bodyBold" color={C.accent}>{streak} day{streak === 1 ? '' : 's'}</Txt>
            </View>
          </View>
          <ProgressBar progress={li.progress} />
          <Txt variant="caption" color={C.onDarkFaint} style={{ marginTop: 8 }}>{li.intoLevel}/{li.needed} XP to level {li.level + 1}</Txt>
        </Card>

        {/* Daily check-in: yellow stamp only when action is pending */}
        {checkedToday ? (
          <Card style={{ marginBottom: S.xl, flexDirection: 'row', alignItems: 'center', gap: 12 }}>
            <Ionicons name="checkmark-circle" size={24} color={C.pos} />
            <View style={{ flex: 1 }}>
              <Txt variant="bodyBold">Checked in today</Txt>
              <Txt variant="bodySm" color={C.onDarkMute}>Day {streak} streak — come back tomorrow</Txt>
            </View>
          </Card>
        ) : (
          <FeaturedCard style={{ marginBottom: S.xl }}>
            <Txt variant="h2" color={C.onAccent}>Daily check-in</Txt>
            <Txt variant="body" color="#000000b0" style={{ marginTop: 4, marginBottom: S.lg }}>
              Tap in to keep your streak and grow your reward multiplier.
            </Txt>
            <Button label="Check in" variant="dark" icon="sunny-outline" onPress={() => dailyCheckIn()} />
          </FeaturedCard>
        )}

        {aiMission && (
          <View style={{ marginBottom: S.sm }}>
            <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
              <Txt variant="eyebrow" color={C.onDarkFaint} upper>For you</Txt>
              <Tag label="AI pick" feature />
            </View>
            <MissionCard mission={aiMission} />
          </View>
        )}

        <Txt variant="eyebrow" color={C.onDarkFaint} upper style={{ marginBottom: 12, marginTop: 6 }}>Today</Txt>
        {daily.map((m) => <MissionCard key={m.id} mission={m} />)}

        <Txt variant="caption" color={C.onDarkFaint} style={{ textAlign: 'center', marginTop: S.lg }}>
          Play. Invite. Belong.
        </Txt>
      </ScrollView>
    </Screen>
  );
}
