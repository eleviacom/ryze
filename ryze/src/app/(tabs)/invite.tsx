// Invite — the hero loop. Referral code, squad goal, leaderboard.
import { Ionicons } from '@expo/vector-icons';
import { Share, ScrollView, View } from 'react-native';

import { C, R, S } from '@/constants/brand';
import { Button, Card, Divider, FeaturedCard, ProgressBar, Screen, Txt } from '@/components/game/ui';
import { SEED_LEADERBOARD } from '@/game/data';
import { levelInfo } from '@/game/engine';
import { useGame } from '@/game/store';

function Avatar({ label, you }: { label: string; you?: boolean }) {
  return (
    <View style={{ width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center', backgroundColor: you ? C.accent : C.surfaceDeep, borderWidth: 1, borderColor: you ? C.accent : C.hairline }}>
      <Txt variant="bodyBold" color={you ? C.onAccent : C.onDark}>{label.slice(0, 1).toUpperCase()}</Txt>
    </View>
  );
}

export default function Invite() {
  const { referralCode, invites, squad, name, xp } = useGame();
  const simulateReferral = useGame((s) => s.simulateReferral);
  const board = [...SEED_LEADERBOARD, { id: 'you', name, avatar: '', xp, you: true }].sort((a, b) => b.xp - a.xp);
  const onShare = () => Share.share({ message: `Join me on Ryze — Raiffeisen Youth. Use code ${referralCode} and we both get 200 coins.` }).catch(() => {});

  return (
    <Screen>
      <ScrollView contentContainerStyle={{ padding: S.xl, paddingBottom: 96 }} showsVerticalScrollIndicator={false}>
        <Txt variant="displayLg" style={{ marginBottom: 4 }}>Invite</Txt>
        <Txt variant="body" color={C.onDarkMute} style={{ marginBottom: S.lg }}>You both win. Your squad wins. Everyone climbs.</Txt>

        <FeaturedCard style={{ marginBottom: S.lg }}>
          <Txt variant="eyebrow" color="#00000088" upper>Your invite code</Txt>
          <Txt variant="displayLg" color={C.onAccent} style={{ marginVertical: 6 }}>{referralCode}</Txt>
          <Txt variant="body" color="#000000b0" style={{ marginBottom: S.lg }}>
            A friend joins with your code and you both get 200 coins and 200 XP.
          </Txt>
          <Button label="Share invite" variant="dark" icon="share-outline" onPress={onShare} />
        </FeaturedCard>

        <Card style={{ marginBottom: S.xl, flexDirection: 'row', alignItems: 'center', gap: 12 }}>
          <View style={{ flex: 1 }}>
            <Txt variant="bodySm" color={C.onDarkMute}>Demo control</Txt>
            <Txt variant="bodyBold">Simulate a friend joining</Txt>
          </View>
          <Button label="Run" size="sm" variant="soft" icon="play" onPress={() => simulateReferral()} />
        </Card>

        <Txt variant="h3" style={{ marginBottom: 12 }}>Squad challenge</Txt>
        <Card style={{ marginBottom: S.xl }}>
          <Txt variant="bodyBold">{squad.name}</Txt>
          <Txt variant="bodySm" color={C.onDarkMute} style={{ marginBottom: 12 }}>{squad.goalTitle} · reward {squad.rewardCoins} coins each</Txt>
          <ProgressBar progress={squad.progress / squad.goal} />
          <Txt variant="caption" color={C.onDarkFaint} style={{ marginTop: 8 }}>{squad.progress}/{squad.goal} invites · {invites} from you</Txt>
          <View style={{ flexDirection: 'row', gap: 16, marginTop: S.lg }}>
            {squad.members.map((m) => (
              <View key={m.id} style={{ alignItems: 'center', gap: 4 }}>
                <Avatar label={m.name} you={m.name === 'You'} />
                <Txt variant="caption" color={C.onDarkMute}>{m.name}</Txt>
              </View>
            ))}
          </View>
        </Card>

        <Txt variant="h3" style={{ marginBottom: 12 }}>Leaderboard</Txt>
        <Card>
          {board.map((row, i) => (
            <View key={row.id}>
              <View style={{ flexDirection: 'row', alignItems: 'center', paddingVertical: 12 }}>
                <Txt variant="bodyBold" color={i < 3 ? C.accent : C.onDarkFaint} style={{ width: 26 }}>{i + 1}</Txt>
                <View style={{ marginRight: 12 }}><Avatar label={row.name} you={!!row.you} /></View>
                <Txt variant="bodyBold" color={row.you ? C.accent : C.onDark} style={{ flex: 1 }}>{row.name}{row.you ? ' (you)' : ''}</Txt>
                <Txt variant="bodySm" color={C.onDarkMute}>{row.xp} XP · Lv {levelInfo(row.xp).level}</Txt>
              </View>
              {i < board.length - 1 && <Divider />}
            </View>
          ))}
        </Card>
      </ScrollView>
    </Screen>
  );
}
