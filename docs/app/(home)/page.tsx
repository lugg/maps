import Link from 'next/link';
import {
  ArrowRight,
  Camera,
  Globe,
  Image as ImageIcon,
  Layers,
  LayoutGrid,
  MapPin,
  Rows3,
  Route,
  Zap,
} from 'lucide-react';
import { CodeSample } from '@/components/code-sample';
import { GithubIcon } from '@/components/github-icon';
import { InstallCommand } from '@/components/install-command';
import { Logo } from '@/components/logo';
import { MapIllustration } from '@/components/map-illustration';
import { GITHUB_URL } from '@/lib/layout.shared';
import {
  createMetadata,
  SITE_DESCRIPTION,
  SITE_NAME,
  SITE_URL,
} from '@/lib/metadata';
import pkg from '../../../package.json';

const HOME_TITLE = `${SITE_NAME} · Universal maps for React Native`;

export const metadata = {
  ...createMetadata({
    title: HOME_TITLE,
    description: SITE_DESCRIPTION,
    path: '/',
  }),
  title: { absolute: HOME_TITLE },
};

const JSON_LD = [
  {
    '@context': 'https://schema.org',
    '@type': 'WebSite',
    'name': SITE_NAME,
    'url': SITE_URL,
    'description': SITE_DESCRIPTION,
  },
  {
    '@context': 'https://schema.org',
    '@type': 'SoftwareSourceCode',
    'name': SITE_NAME,
    'description': SITE_DESCRIPTION,
    'url': SITE_URL,
    'codeRepository': GITHUB_URL,
    'programmingLanguage': ['TypeScript', 'Kotlin', 'Objective-C'],
    'runtimePlatform': 'React Native',
    'license': 'https://opensource.org/licenses/MIT',
    'version': pkg.version,
    'author': { '@type': 'Organization', 'name': 'Lugg', 'url': GITHUB_URL },
  },
];

const USAGE = `import { MapView, Marker, Polyline } from '@lugg/maps';

export function Map() {
  return (
    <MapView
      style={{ flex: 1 }}
      provider="google"
      initialCoordinate={{ latitude: 37.7749, longitude: -122.4194 }}
      initialZoom={12}
    >
      <Marker
        coordinate={{ latitude: 37.7749, longitude: -122.4194 }}
        title="San Francisco"
      />
      <Polyline
        coordinates={route}
        strokeWidth={4}
        strokeColors={['#4285F4', '#34A853']}
        animated
      />
    </MapView>
  );
}`;

const FEATURES = [
  {
    icon: Layers,
    title: 'Two providers, one API',
    description:
      'Apple Maps or Google Maps on iOS. Google Maps on Android and the web. Switch with a single prop.',
  },
  {
    icon: Zap,
    title: 'Built for Fabric',
    description:
      'New Architecture from day one. Codegen specs, direct C++ communication, no bridge.',
  },
  {
    icon: MapPin,
    title: 'Markers, your way',
    description:
      'Native pins or any React view. Callouts, drag gestures, rotation, scaling, and z-ordering.',
  },
  {
    icon: Route,
    title: 'Lines and shapes',
    description:
      'Polylines with gradient strokes and snake animation. Polygons with holes. Circles.',
  },
  {
    icon: Globe,
    title: 'GeoJSON',
    description:
      'Drop in a FeatureCollection. Styled with simplestyle-spec, customizable per feature.',
  },
  {
    icon: ImageIcon,
    title: 'Overlays',
    description:
      'Ground image overlays pinned to geographic bounds and custom tile layers from any server.',
  },
  {
    icon: Rows3,
    title: 'Static maps for lists',
    description:
      'Snapshot maps rendered off the main thread and cached, so long lists stay smooth.',
  },
  {
    icon: Camera,
    title: 'Camera control',
    description:
      'moveCamera, fitCoordinates, and setEdgeInsets with animation. Camera events as you pan.',
  },
];

const COMPONENTS = [
  {
    name: 'MapView',
    href: '/docs/components/map-view',
    description: 'The map itself. Providers, camera, gestures, static mode.',
  },
  {
    name: 'Marker',
    href: '/docs/components/marker',
    description: 'Pins with custom views, callouts, and dragging.',
  },
  {
    name: 'Polyline',
    href: '/docs/components/polyline',
    description: 'Lines with gradient strokes and animation.',
  },
  {
    name: 'Polygon',
    href: '/docs/components/polygon',
    description: 'Filled shapes with optional holes.',
  },
  {
    name: 'Circle',
    href: '/docs/components/circle',
    description: 'Radius-based circular overlays.',
  },
  {
    name: 'GeoJson',
    href: '/docs/components/geojson',
    description: 'Render GeoJSON features directly.',
  },
  {
    name: 'GroundOverlay',
    href: '/docs/components/ground-overlay',
    description: 'Images stretched over geographic bounds.',
  },
  {
    name: 'TileOverlay',
    href: '/docs/components/tile-overlay',
    description: 'Custom raster tile layers.',
  },
];

const PLATFORMS = [
  { name: 'iOS', providers: 'Apple Maps · Google Maps' },
  { name: 'Android', providers: 'Google Maps' },
  { name: 'Web', providers: 'Google Maps' },
];

export default function HomePage() {
  return (
    <main className="flex flex-1 flex-col">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(JSON_LD) }}
      />
      <section className="hero-bg relative overflow-hidden border-b border-fd-border">
        <div className="relative mx-auto flex w-full max-w-6xl flex-col items-center px-6 pb-20 pt-24 text-center md:pb-28 md:pt-32">
          <Link
            href={`${GITHUB_URL}/releases`}
            className="mb-8 inline-flex items-center gap-2 rounded-full border border-fd-primary/30 bg-fd-primary/10 px-3 py-1 text-xs font-medium text-fd-primary transition-colors hover:bg-fd-primary/15"
          >
            <span className="size-1.5 rounded-full bg-fd-primary" />
            {`v${pkg.version}`}
            <span className="text-fd-primary/60">·</span>
            New Architecture ready
          </Link>

          <Logo className="mb-6 size-16" />

          <h1 className="max-w-3xl text-balance text-4xl font-bold tracking-tight text-fd-foreground sm:text-5xl md:text-6xl">
            Universal maps for{' '}
            <span className="text-fd-primary">React Native</span>
          </h1>

          <p className="mt-6 max-w-2xl text-balance text-lg text-fd-muted-foreground md:text-xl">
            One <code className="font-mono text-fd-foreground">MapView</code>{' '}
            for Apple Maps and Google Maps on iOS, Android, and Web. Markers,
            shapes, overlays, GeoJSON, and static maps, all native.
          </p>

          <div className="mt-10 flex flex-col items-center gap-4 sm:flex-row">
            <Link
              href="/docs"
              className="inline-flex h-11 items-center gap-2 rounded-full bg-fd-primary px-6 text-sm font-semibold text-fd-primary-foreground transition-opacity hover:opacity-90"
            >
              Get started
              <ArrowRight className="size-4" />
            </Link>
            <Link
              href={GITHUB_URL}
              className="inline-flex h-11 items-center gap-2 rounded-full border border-fd-border bg-fd-card/70 px-6 text-sm font-semibold text-fd-foreground backdrop-blur transition-colors hover:bg-fd-accent"
            >
              <GithubIcon className="size-4" />
              GitHub
            </Link>
          </div>

          <div className="mt-6">
            <InstallCommand command="npm install @lugg/maps" />
          </div>

          <dl className="mt-14 grid w-full max-w-2xl grid-cols-1 gap-3 sm:grid-cols-3">
            {PLATFORMS.map((platform) => (
              <div
                key={platform.name}
                className="rounded-2xl border border-fd-border bg-fd-card/60 px-4 py-3 text-left backdrop-blur"
              >
                <dt className="text-sm font-semibold text-fd-foreground">
                  {platform.name}
                </dt>
                <dd className="mt-0.5 text-xs text-fd-muted-foreground">
                  {platform.providers}
                </dd>
              </div>
            ))}
          </dl>
        </div>
      </section>

      <section className="relative overflow-hidden">
        <div
          aria-hidden
          className="map-bg pointer-events-none absolute inset-y-0 right-0 hidden w-[54%] lg:block"
        >
          <MapIllustration className="h-full w-full" />
        </div>
        <div className="relative mx-auto w-full max-w-6xl px-6 py-20 md:py-28">
          <div className="max-w-2xl">
            <p className="text-sm font-semibold uppercase tracking-wider text-fd-primary">
              Declarative
            </p>
            <h2 className="mt-3 text-3xl font-bold tracking-tight text-fd-foreground md:text-4xl">
              Just React. Everything is a child of the map.
            </h2>
            <p className="mt-4 text-fd-muted-foreground">
              Markers, polylines, polygons, and overlays are plain components.
              Update props, and the native map follows. No imperative
              bookkeeping, no ids to track.
            </p>
            <div className="mt-8 text-sm">
              <CodeSample code={USAGE} title="Map.tsx" />
            </div>
          </div>
        </div>
      </section>

      <section className="border-y border-fd-border bg-fd-card/40">
        <div className="mx-auto w-full max-w-6xl px-6 py-20 md:py-28">
          <div className="max-w-2xl">
            <p className="text-sm font-semibold uppercase tracking-wider text-fd-primary">
              Features
            </p>
            <h2 className="mt-3 text-3xl font-bold tracking-tight text-fd-foreground md:text-4xl">
              Everything a map needs. Nothing you have to wire up.
            </h2>
          </div>
          <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {FEATURES.map((feature) => (
              <div
                key={feature.title}
                className="group rounded-2xl border border-fd-border bg-fd-background p-5 transition-colors hover:border-fd-primary/40"
              >
                <div className="mb-4 inline-flex size-10 items-center justify-center rounded-xl bg-fd-primary/10 text-fd-primary">
                  <feature.icon className="size-5" />
                </div>
                <h3 className="font-semibold text-fd-foreground">
                  {feature.title}
                </h3>
                <p className="mt-1.5 text-sm leading-relaxed text-fd-muted-foreground">
                  {feature.description}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="mx-auto w-full max-w-6xl px-6 py-20 md:py-28">
        <div className="flex flex-col gap-6 md:flex-row md:items-end md:justify-between">
          <div className="max-w-2xl">
            <p className="text-sm font-semibold uppercase tracking-wider text-fd-primary">
              Components
            </p>
            <h2 className="mt-3 text-3xl font-bold tracking-tight text-fd-foreground md:text-4xl">
              A small, focused API.
            </h2>
          </div>
          <Link
            href="/docs"
            className="inline-flex items-center gap-1.5 text-sm font-medium text-fd-primary hover:underline"
          >
            Browse the docs
            <ArrowRight className="size-4" />
          </Link>
        </div>
        <div className="mt-10 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {COMPONENTS.map((component) => (
            <Link
              key={component.name}
              href={component.href}
              className="group flex flex-col gap-1 rounded-2xl border border-fd-border p-5 transition-colors hover:border-fd-primary/40 hover:bg-fd-accent/50"
            >
              <span className="inline-flex items-center justify-between font-mono text-sm font-semibold text-fd-foreground">
                {`<${component.name} />`}
                <ArrowRight className="size-4 text-fd-muted-foreground opacity-0 transition-opacity group-hover:opacity-100" />
              </span>
              <span className="text-sm text-fd-muted-foreground">
                {component.description}
              </span>
            </Link>
          ))}
        </div>
      </section>

      <section className="border-t border-fd-border">
        <div className="mx-auto flex w-full max-w-6xl flex-col items-center gap-6 px-6 py-20 text-center md:py-24">
          <div className="inline-flex size-12 items-center justify-center rounded-2xl bg-fd-primary/10 text-fd-primary">
            <LayoutGrid className="size-6" />
          </div>
          <h2 className="text-3xl font-bold tracking-tight text-fd-foreground md:text-4xl">
            Ship a map in minutes.
          </h2>
          <p className="max-w-xl text-fd-muted-foreground">
            Install the package, add your API key with the Expo config plugin,
            and render a map. Works with Expo and bare React Native.
          </p>
          <div className="flex flex-col items-center gap-3 sm:flex-row">
            <Link
              href="/docs/installation"
              className="inline-flex h-11 items-center gap-2 rounded-full bg-fd-primary px-6 text-sm font-semibold text-fd-primary-foreground transition-opacity hover:opacity-90"
            >
              Installation
              <ArrowRight className="size-4" />
            </Link>
            <Link
              href="/docs/usage"
              className="inline-flex h-11 items-center rounded-full border border-fd-border px-6 text-sm font-semibold text-fd-foreground transition-colors hover:bg-fd-accent"
            >
              Usage guide
            </Link>
          </div>
        </div>
      </section>

      <footer className="border-t border-fd-border">
        <div className="mx-auto flex w-full max-w-6xl flex-col gap-4 px-6 py-8 text-sm text-fd-muted-foreground sm:flex-row sm:items-center sm:justify-between">
          <div className="inline-flex items-center gap-2">
            <Logo className="size-4" />
            <span className="font-medium text-fd-foreground">@lugg/maps</span>
            <span>·</span>
            <span>MIT License</span>
          </div>
          <div className="flex items-center gap-5">
            <Link href="/docs" className="hover:text-fd-foreground">
              Docs
            </Link>
            <Link href={GITHUB_URL} className="hover:text-fd-foreground">
              GitHub
            </Link>
            <Link
              href="https://www.npmjs.com/package/@lugg/maps"
              className="hover:text-fd-foreground"
            >
              npm
            </Link>
            <Link
              href="https://github.com/lodev09"
              className="hover:text-fd-foreground"
            >
              Built by Lugg
            </Link>
          </div>
        </div>
      </footer>
    </main>
  );
}
