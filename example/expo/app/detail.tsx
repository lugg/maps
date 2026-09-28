import { useLocalSearchParams } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { MarkerDetailScreen } from '@lugg/shared-example';

export default function DetailScreen() {
  const { name } = useLocalSearchParams<{ name: string }>();
  const { bottom } = useSafeAreaInsets();

  return <MarkerDetailScreen name={name ?? ''} bottomInset={bottom} />;
}
