// Quests — full mission board with filter pills.
import { useState } from 'react';
import { ScrollView, View } from 'react-native';

import { C, S } from '@/constants/brand';
import { Card, Chip, ProgressBar, Screen, Txt } from '@/components/game/ui';
import { MissionCard } from '@/components/game/MissionCard';
import { useGame } from '@/game/store';
import { MissionCategory } from '@/game/types';

type Filter = 'all' | MissionCategory;
const FILTERS: { key: Filter; label: string }[] = [
  { key: 'all', label: 'All' },
  { key: 'onboarding', label: 'Setup' },
  { key: 'daily', label: 'Daily' },
  { key: 'weekly', label: 'Weekly' },
  { key: 'social', label: 'Social' },
];

export default function Quests() {
  const missions = useGame((s) => s.missions);
  const [filter, setFilter] = useState<Filter>('all');
  const ob = missions.filter((m) => m.category === 'onboarding');
  const obDone = ob.filter((m) => m.claimed).length;
  const shown = filter === 'all' ? missions : missions.filter((m) => m.category === filter);

  return (
    <Screen>
      <ScrollView contentContainerStyle={{ padding: S.xl, paddingBottom: 96 }} showsVerticalScrollIndicator={false}>
        <Txt variant="displayLg" style={{ marginBottom: 4 }}>Quests</Txt>
        <Txt variant="body" color={C.onDarkMute} style={{ marginBottom: S.lg }}>Every action earns XP and coins.</Txt>

        <Card style={{ marginBottom: S.lg }}>
          <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginBottom: 10 }}>
            <Txt variant="bodyBold">Onboarding</Txt>
            <Txt variant="bodyBold" color={C.accent}>{obDone}/{ob.length}</Txt>
          </View>
          <ProgressBar progress={ob.length ? obDone / ob.length : 0} />
          <Txt variant="caption" color={C.onDarkFaint} style={{ marginTop: 8 }}>Finish setup to unlock the All Set badge.</Txt>
        </Card>

        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 8, paddingBottom: S.lg }}>
          {FILTERS.map((f) => <Chip key={f.key} label={f.label} active={filter === f.key} onPress={() => setFilter(f.key)} />)}
        </ScrollView>

        {shown.map((m) => <MissionCard key={m.id} mission={m} />)}
      </ScrollView>
    </Screen>
  );
}
