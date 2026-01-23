import { Polyline } from '@lugg/maps';

const coordinates = [
  { latitude: 37.785, longitude: -122.44 },
  { latitude: 37.7848, longitude: -122.4395 },
  { latitude: 37.7846, longitude: -122.439 },
  { latitude: 37.7844, longitude: -122.4385 },
  { latitude: 37.7842, longitude: -122.438 },
  { latitude: 37.784, longitude: -122.4375 },
  { latitude: 37.7838, longitude: -122.437 },
  { latitude: 37.7836, longitude: -122.4365 },
  { latitude: 37.7834, longitude: -122.436 },
  { latitude: 37.7832, longitude: -122.4355 },
  { latitude: 37.783, longitude: -122.435 },
  { latitude: 37.7828, longitude: -122.4345 },
  { latitude: 37.7826, longitude: -122.434 },
  { latitude: 37.7824, longitude: -122.4335 },
  { latitude: 37.7822, longitude: -122.433 },
  { latitude: 37.782, longitude: -122.4325 },
  { latitude: 37.7818, longitude: -122.432 },
  { latitude: 37.7816, longitude: -122.4315 },
  { latitude: 37.7814, longitude: -122.431 },
  { latitude: 37.7812, longitude: -122.4305 },
  { latitude: 37.781, longitude: -122.43 },
  { latitude: 37.7808, longitude: -122.4295 },
  { latitude: 37.7806, longitude: -122.429 },
  { latitude: 37.7804, longitude: -122.4285 },
  { latitude: 37.7802, longitude: -122.428 },
  { latitude: 37.78, longitude: -122.4275 },
  { latitude: 37.7798, longitude: -122.427 },
  { latitude: 37.7796, longitude: -122.4265 },
  { latitude: 37.7794, longitude: -122.426 },
  { latitude: 37.7792, longitude: -122.4255 },
  { latitude: 37.779, longitude: -122.425 },
  { latitude: 37.7788, longitude: -122.4245 },
  { latitude: 37.7786, longitude: -122.424 },
  { latitude: 37.7784, longitude: -122.4235 },
  { latitude: 37.7782, longitude: -122.423 },
  { latitude: 37.778, longitude: -122.4225 },
  { latitude: 37.7778, longitude: -122.422 },
  { latitude: 37.7776, longitude: -122.4215 },
  { latitude: 37.7774, longitude: -122.421 },
  { latitude: 37.7772, longitude: -122.4205 },
  { latitude: 37.777, longitude: -122.42 },
  { latitude: 37.7772, longitude: -122.4195 },
  { latitude: 37.7774, longitude: -122.419 },
  { latitude: 37.7776, longitude: -122.4185 },
  { latitude: 37.7778, longitude: -122.418 },
  { latitude: 37.778, longitude: -122.4175 },
  { latitude: 37.7782, longitude: -122.417 },
  { latitude: 37.7784, longitude: -122.4165 },
  { latitude: 37.7786, longitude: -122.416 },
  { latitude: 37.7788, longitude: -122.4155 },
];

export const Route = () => (
  <Polyline
    strokeColors={['#FF5733', '#FFBD33']}
    coordinates={coordinates}
    strokeWidth={6}
    animated
  />
);
