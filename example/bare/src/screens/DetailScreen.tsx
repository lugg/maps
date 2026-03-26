import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { MarkerDetailScreen } from '@lugg/shared-example';

import type { RootStackParamList } from '../App';

type Props = NativeStackScreenProps<RootStackParamList, 'Detail'>;

export function DetailScreen({ route }: Props) {
  return <MarkerDetailScreen name={route.params.name} />;
}
