interface OgImageProps {
  title: string;
  description?: string;
  section?: string;
}

export function OgImage({ title, description, section }: OgImageProps) {
  return (
    <div
      style={{
        width: '100%',
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        padding: 72,
        backgroundColor: '#0B1220',
        color: '#F8FAFC',
        fontFamily: 'sans-serif',
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
        <svg width="56" height="56" viewBox="0 0 32 32" fill="none">
          <path
            d="M16 2C9.925 2 5 6.925 5 13c0 7.5 9.4 15.9 10.3 16.7a1 1 0 0 0 1.4 0C17.6 28.9 27 20.5 27 13c0-6.075-4.925-11-11-11Z"
            fill="#4285F4"
          />
          <circle cx="16" cy="13" r="4.5" fill="white" />
        </svg>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <span style={{ fontSize: 34, fontWeight: 700 }}>@lugg/maps</span>
          {section && (
            <span
              style={{
                fontSize: 24,
                color: '#7AA7FF',
                paddingLeft: 14,
                borderLeft: '2px solid rgba(148, 163, 184, 0.4)',
              }}
            >
              {section}
            </span>
          )}
        </div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
        <div
          style={{
            fontSize: title.length > 28 ? 64 : 80,
            fontWeight: 700,
            lineHeight: 1.05,
            letterSpacing: -2,
          }}
        >
          {title}
        </div>
        {description && (
          <div
            style={{
              fontSize: 30,
              lineHeight: 1.35,
              color: '#A9B4C6',
              maxWidth: 960,
            }}
          >
            {description}
          </div>
        )}
      </div>

      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          fontSize: 24,
          color: '#7A869C',
        }}
      >
        <span>React Native · iOS · Android · Web</span>
        <span>maps.lodev09.com</span>
      </div>
    </div>
  );
}
