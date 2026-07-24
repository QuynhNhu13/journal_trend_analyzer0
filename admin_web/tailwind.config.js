/** @type {import('tailwindcss').Config} */
// Central design tokens for the admin console. Pink theme matching the app.
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // Brand — rose / pink family (matching Flutter app_theme.dart)
        brand: {
          DEFAULT: '#DB2777', // pink-600 (Primary)
          bright: '#EC4899', // pink-500 (Hover / Gradient)
          light: '#F472B6', // pink-400 (Light accent gradient)
          deep: '#BE185D', // pink-700 (Active / Emphasis)
          soft: '#FCE7F3', // pink-100 (Chips / Badges)
          tint: '#FDF2F8', // pink-50 (Subtle active nav / hover background)
          glow: 'rgba(219, 39, 119, 0.25)',
        },

        // Surface / Background scale — clean warm pinkish neutral canvas matching mobile app
        canvas: '#FAF7F9', // subtle warm pink background
        card: '#FFFFFF', // surfaces
        subtle: '#FFF5F8', // soft hover rows, raised chips, table headers
        hairline: '#F3E8EE', // 1px borders / dividers
        ink: '#111827', // primary text / headings
        body: '#374151', // body text
        muted: '#6B7280', // secondary text / labels
        faint: '#9CA3AF', // tertiary / placeholders

        // Semantic
        success: '#10B981', // emerald-500
        warning: '#F59E0B', // amber-500
        danger: '#EF4444', // red-500

        // Back-compat aliases
        emerald: '#10B981',
        amber: '#F59E0B',
        indigo: '#6366F1',
        violet: '#8B5CF6',
        sky: '#0EA5E9',
      },

      borderRadius: {
        sm: '8px',
        md: '12px',
        lg: '16px',
        xl: '20px',
        '2xl': '24px',
        '3xl': '32px',
      },

      boxShadow: {
        xs: '0 1px 3px 0 rgba(219, 39, 119, 0.05)',
        soft: '0 8px 24px -4px rgba(219, 39, 119, 0.07), 0 2px 6px -1px rgba(0, 0, 0, 0.03)',
        card: '0 4px 16px -2px rgba(219, 39, 119, 0.06), 0 1px 3px 0 rgba(0, 0, 0, 0.02)',
        brand: '0 8px 20px -4px rgba(219, 39, 119, 0.35)',
        glow: '0 0 25px 0 rgba(236, 72, 153, 0.25)',
        pop: '0 12px 32px -8px rgba(219, 39, 119, 0.20), 0 4px 12px -2px rgba(0, 0, 0, 0.08)',
      },

      fontFamily: {
        sans: [
          'Plus Jakarta Sans',
          'Inter',
          'system-ui',
          '-apple-system',
          'Segoe UI',
          'Roboto',
          'sans-serif',
        ],
      },

      fontSize: {
        title: ['1.25rem', { lineHeight: '1.75rem', fontWeight: '700' }],
        metric: ['1.875rem', { lineHeight: '2.25rem', fontWeight: '800' }],
        label: ['0.6875rem', { lineHeight: '1rem', letterSpacing: '0.05em', fontWeight: '700' }],
      },
    },
  },
  plugins: [],
};
