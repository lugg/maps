import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useHeaderHeight } from '@react-navigation/elements';
import { StaticMapsScreen as SharedStaticMapsScreen } from '@lugg/shared-example';

import type { RootStackParamList } from '../App';

type Props = NativeStackScreenProps<RootStackParamList, 'StaticMaps'>;

export function StaticMapsScreen({ navigation }: Props) {
  const headerHeight = useHeaderHeight();

  return (
    <SharedStaticMapsScreen
      topInset={headerHeight}
      onSelect={(place) => navigation.navigate('Detail', { name: place.name })}
    />
  );
}
