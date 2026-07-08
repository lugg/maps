import { Stack } from 'expo-router';

export default function Layout() {
  return (
    <Stack>
      <Stack.Screen name="index" options={{ headerShown: false }} />
      <Stack.Screen
        name="detail"
        options={{ headerTransparent: true, title: '' }}
      />
      <Stack.Screen
        name="static-maps"
        options={{ title: 'Static Maps', headerTransparent: true }}
      />
    </Stack>
  );
}
