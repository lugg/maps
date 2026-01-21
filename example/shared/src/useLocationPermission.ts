import { useEffect, useState } from 'react';
import { Platform, PermissionsAndroid } from 'react-native';

export function useLocationPermission() {
  const [granted, setGranted] = useState(false);

  useEffect(() => {
    const request = async () => {
      if (Platform.OS === 'ios') {
        setGranted(true);
        return;
      }

      const result = await PermissionsAndroid.request(
        PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION
      );
      setGranted(result === PermissionsAndroid.RESULTS.GRANTED);
    };

    request();
  }, []);

  return granted;
}
