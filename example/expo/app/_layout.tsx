import { Stack } from 'expo-router';

export const unstable_settings = {
  initialRouteName: 'index',
};

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
      <Stack.Screen
        name="modal"
        options={{ presentation: 'fullScreenModal', headerShown: false }}
      />
    </Stack>
  );
}
