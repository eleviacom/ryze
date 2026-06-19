// One mission row. Drives the do -> claim loop. Revolut card language.
import { Ionicons } from '@expo/vector-icons';
import { View } from 'react-native';

import { C } from '@/constants/brand';
import { useGame } from '@/game/store';
import { Mission } from '@/game/types';
import { Button, Card, IconTile, ProgressBar, Txt } from '@/components/game/ui';

// content icon per mission (iconography, not emoji)
const ICONS: Record<string, { name: keyof typeof Ionicons.glyphMap; color: string }> = {
  'ob-verify': { name: 'person-circle-outline', color: C.blue },
  'ob-card': { name: 'card-outline', color: C.teal },
  'ob-goal': { name: 'flag-outline', color: C.accent },
  'd-checkin': { name: 'sunny-outline', color: C.accent },
  'd-round': { name: 'cash-outline', color: C.teal },
  'd-quiz': { name: 'bulb-outline', color: C.orange },
  'w-save': { name: 'wallet-outline', color: C.teal },
  'w-spend': { name: 'flash-outline', color: C.accent },
  's-invite': { name: 'people-outline', color: C.pink },
};

export function MissionCard({ mission }: { mission: Mission }) {
  const progressMission = useGame((s) => s.progressMission);
  const claimMission = useGame((s) => s.claimMission);
  const done = mission.progress >= mission.target;
  const multi = mission.target > 1;
  const ic = mission.aiGenerated
    ? { name: 'sparkles' as const, color: C.accent }
    : ICONS[mission.id] ?? { name: 'star-outline' as const, color: C.accent };

  return (
    <Card style={{ padding: 16, marginBottom: 10 }}>
      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 14 }}>
        <IconTile name={ic.name} color={ic.color} />
        <View style={{ flex: 1 }}>
          <Txt variant="bodyBold">{mission.title}</Txt>
          <View style={{ flexDirection: 'row', gap: 12, marginTop: 3 }}>
            <Txt variant="caption" color={C.pos}>+{mission.xp} XP</Txt>
            <Txt variant="caption" color={C.accent}>+{mission.coins} coins</Txt>
          </View>
        </View>
        {mission.claimed ? (
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5 }}>
            <Ionicons name="checkmark-circle" size={18} color={C.pos} />
            <Txt variant="buttonSm" color={C.onDarkMute}>Done</Txt>
          </View>
        ) : done ? (
          <Button label="Claim" size="sm" variant="primary" onPress={() => claimMission(mission.id)} />
        ) : (
          <Button label={multi ? '+1' : 'Start'} size="sm" variant="soft"
            onPress={() => progressMission(mission.id, multi ? 1 : mission.target)} />
        )}
      </View>
      {multi && !mission.claimed && (
        <View style={{ marginTop: 12 }}>
          <ProgressBar progress={mission.progress / mission.target} height={6} />
          <Txt variant="caption" color={C.onDarkFaint} style={{ marginTop: 6 }}>{mission.progress}/{mission.target}</Txt>
        </View>
      )}
    </Card>
  );
}
