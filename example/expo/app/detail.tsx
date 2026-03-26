import { useLocalSearchParams } from 'expo-router';
import { MarkerDetailScreen } from '@lugg/shared-example';

export default function DetailScreen() {
  const { name } = useLocalSearchParams<{ name: string }>();
  return <MarkerDetailScreen name={name ?? ''} />;
}
