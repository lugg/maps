import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { StaticMapsScreen as SharedStaticMapsScreen } from '@lugg/shared-example';

import type { RootStackParamList } from '../App';

type Props = NativeStackScreenProps<RootStackParamList, 'StaticMaps'>;

export function StaticMapsScreen({ navigation }: Props) {
  return (
    <SharedStaticMapsScreen
      onSelect={(place) => navigation.navigate('Detail', { name: place.name })}
    />
  );
}
