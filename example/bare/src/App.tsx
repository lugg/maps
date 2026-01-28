import { Home, type VehicleImages } from '@lugg/shared-example';

const vehicleImages: VehicleImages = {
  driving: require('./assets/pickup_default.png'),
  loaded: require('./assets/pickup_loaded.png'),
};

export default function App() {
  return <Home vehicleImages={vehicleImages} />;
}
