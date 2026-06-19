import { Ionicons } from '@expo/vector-icons';
import type { ColorValue } from 'react-native';
import { Redirect, Tabs } from 'expo-router';
import { ActivityIndicator, View } from 'react-native';

import { C, FONTS } from '@/constants/brand';
import { useGame } from '@/game/store';

function icon(active: keyof typeof Ionicons.glyphMap, idle: keyof typeof Ionicons.glyphMap) {
  return ({ color, focused }: { color: ColorValue; focused: boolean }) => (
    <Ionicons name={focused ? active : idle} size={23} color={color as string} />
  );
}

export default function TabsLayout() {
  const hydrated = useGame((s) => s.hydrated);
  const onboarded = useGame((s) => s.onboarded);

  if (!hydrated) {
    return <View style={{ flex: 1, backgroundColor: C.black, alignItems: 'center', justifyContent: 'center' }}><ActivityIndicator color={C.accent} /></View>;
  }
  if (!onboarded) return <Redirect href="/onboarding" />;

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: C.accent,
        tabBarInactiveTintColor: C.stone,
        tabBarStyle: { backgroundColor: C.black, borderTopColor: C.hairline, borderTopWidth: 1, height: 64, paddingTop: 8, paddingBottom: 10 },
        tabBarLabelStyle: { fontFamily: FONTS.semibold, fontSize: 11, letterSpacing: 0.2 },
      }}>
      <Tabs.Screen name="index" options={{ title: 'Home', tabBarIcon: icon('home', 'home-outline') }} />
      <Tabs.Screen name="quests" options={{ title: 'Quests', tabBarIcon: icon('flag', 'flag-outline') }} />
      <Tabs.Screen name="invite" options={{ title: 'Invite', tabBarIcon: icon('people', 'people-outline') }} />
      <Tabs.Screen name="rewards" options={{ title: 'Rewards', tabBarIcon: icon('gift', 'gift-outline') }} />
      <Tabs.Screen name="profile" options={{ title: 'Profile', tabBarIcon: icon('person', 'person-outline') }} />
    </Tabs>
  );
}
