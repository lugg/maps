import { useCallback } from 'react';
import { useColorScheme } from 'react-native';
import { NavigationContainer, DarkTheme, DefaultTheme } from '@react-navigation/native';
import {
  createNativeStackNavigator,
  type NativeStackScreenProps,
} from '@react-navigation/native-stack';
import type { MarkerPressEvent } from '@lugg/maps';
import { HomeScreen, type MarkerData } from '@lugg/shared-example';

import { DetailScreen } from './screens/DetailScreen';

export type RootStackParamList = {
  Home: undefined;
  Detail: { name: string };
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

  return <HomeScreen onMarkerPress={handleMarkerPress} />;
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
        <Stack.Screen name="Detail" component={DetailScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
