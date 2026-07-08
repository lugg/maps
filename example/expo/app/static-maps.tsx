import { useRouter } from 'expo-router';
import { useHeaderHeight } from 'expo-router/react-navigation';
import { StaticMapsScreen } from '@lugg/shared-example';

export default function StaticMaps() {
  const router = useRouter();
  const headerHeight = useHeaderHeight();

  return (
    <StaticMapsScreen
      topInset={headerHeight}
      onSelect={(place) =>
        router.push({ pathname: '/detail', params: { name: place.name } })
      }
    />
  );
}
