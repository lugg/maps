import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { MarkerDetailScreen } from '@lugg/shared-example';

import type { RootStackParamList } from '../App';

type Props = NativeStackScreenProps<RootStackParamList, 'Detail'>;

export function DetailScreen({ route }: Props) {
  const { bottom } = useSafeAreaInsets();

  return <MarkerDetailScreen name={route.params.name} bottomInset={bottom} />;
}
