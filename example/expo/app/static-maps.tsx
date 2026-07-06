import { useRouter } from 'expo-router';
import { StaticMapsScreen } from '@lugg/shared-example';

export default function StaticMaps() {
  const router = useRouter();

  return (
    <StaticMapsScreen
      onSelect={(place) =>
        router.push({ pathname: '/detail', params: { name: place.name } })
      }
    />
  );
}
