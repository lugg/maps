# Examples

This directory contains example apps demonstrating `@lugg/maps`.

## Structure

```
example/
├── bare/     # Bare React Native (react-native-community/cli)
├── expo/     # Expo managed workflow
└── shared/   # Shared components used by both examples
```

## Setup

Copy the example env file and add your Google Maps API key:

```sh
cp bare/.env.example bare/.env
cp expo/.env.example expo/.env
```

Edit both `.env` files with your API key:

```
GOOGLE_MAPS_API_KEY=your_api_key_here
```

The Expo `.env` also exposes the key to the web example:

```sh
EXPO_PUBLIC_GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY}
```

## Running

From the repo root:

```sh
# Install dependencies
yarn

# Run bare example
yarn bare ios
yarn bare android

# Run expo example
yarn expo ios
yarn expo android

# Run web example
yarn expo web
```

## Shared Components

The `shared/` directory contains reusable components and utilities used by both example apps. This ensures consistent behavior across different React Native environments.
