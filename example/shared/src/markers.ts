import type { MarkerData } from './components';

export const MARKER_COLORS = [
  '#EA4335',
  '#4285F4',
  '#34A853',
  '#FBBC05',
  '#9C27B0',
  '#FF5722',
];
export const AVATAR_URLS = Array.from(
  { length: 5 },
  (_, i) => `https://i.pravatar.cc/100?img=${i + 1}`
);
export const MARKER_TYPES: MarkerData['type'][] = [
  'basic',
  'icon',
  'text',
  'image',
  'custom',
];

// Sorted to create a logical route path (southwest to northeast loop)
export const INITIAL_MARKERS: MarkerData[] = [
  {
    id: '3',
    name: 'marker-3',
    coordinate: { latitude: 37.775, longitude: -122.443 },
    type: 'basic',
  },
  {
    id: '4',
    name: 'marker-4',
    coordinate: { latitude: 37.775, longitude: -122.44 },
    type: 'basic',
    anchor: { x: 0.5, y: 1 },
  },
  {
    id: '7',
    name: 'marker-text-a',
    coordinate: { latitude: 37.772, longitude: -122.425 },
    type: 'text',
    text: 'A',
  },
  {
    id: '1',
    name: 'sf-marker',
    coordinate: { latitude: 37.78, longitude: -122.43 },
    type: 'basic',
    title: 'San Francisco',
    description: 'The Golden Gate City',
  },
  {
    id: '10',
    name: 'marker-simple',
    coordinate: { latitude: 37.784, longitude: -122.423 },
    type: 'custom',
    anchor: { x: 0.5, y: 0.5 },
    color: 'red',
  },
  {
    id: '2',
    name: 'marker-2',
    coordinate: { latitude: 37.785, longitude: -122.42 },
    type: 'basic',
    anchor: { x: 0.5, y: 1 },
  },
  {
    id: '9',
    name: 'marker-image',
    coordinate: { latitude: 37.782, longitude: -122.415 },
    type: 'image',
    imageUrl: 'https://i.pravatar.cc/100',
  },
  {
    id: '6',
    name: 'marker-icon',
    coordinate: { latitude: 37.788, longitude: -122.41 },
    type: 'icon',
  },
  {
    id: '8',
    name: 'marker-text-b',
    coordinate: { latitude: 37.795, longitude: -122.42 },
    type: 'text',
    text: 'B',
    color: '#4285F4',
  },
  {
    id: '5',
    name: 'marker-5',
    coordinate: { latitude: 37.79, longitude: -122.435 },
    type: 'basic',
    anchor: { x: 0.5, y: 1 },
  },
];
