import { useCallback } from 'react';
import { useColorScheme } from 'react-native';
import {
  NavigationContainer,
  DarkTheme,
  DefaultTheme,
} from '@react-navigation/native';
import {
  createNativeStackNavigator,
  type NativeStackScreenProps,
} from '@react-navigation/native-stack';
import type { MarkerPressEvent } from '@lugg/maps';
import { HomeScreen, type MarkerData } from '@lugg/shared-example';

import { DetailScreen } from './screens/DetailScreen';
import { StaticMapsScreen } from './screens/StaticMapsScreen';

export type RootStackParamList = {
  Home: undefined;
  Detail: { name: string };
  StaticMaps: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

type HomeProps = NativeStackScreenProps<RootStackParamList, 'Home'>;

function Home({ navigation }: HomeProps) {
  const handleMarkerPress = useCallback(
    (_e: MarkerPressEvent, marker: MarkerData) => {
      navigation.navigate('Detail', { name: marker.name });
    },
    [navigation]
  );

  const handleShowStaticMaps = useCallback(() => {
    navigation.navigate('StaticMaps');
  }, [navigation]);

  return (
    <HomeScreen
      onMarkerPress={handleMarkerPress}
      onShowStaticMaps={handleShowStaticMaps}
    />
  );
}

export default function App() {
  const scheme = useColorScheme();

  return (
    <NavigationContainer theme={scheme === 'dark' ? DarkTheme : DefaultTheme}>
      <Stack.Navigator>
        <Stack.Screen
          name="Home"
          component={Home}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="Detail"
          component={DetailScreen}
          options={{ headerTransparent: true, title: '' }}
        />
        <Stack.Screen
          name="StaticMaps"
          component={StaticMapsScreen}
          options={{ title: 'Static Maps', headerTransparent: true }}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
