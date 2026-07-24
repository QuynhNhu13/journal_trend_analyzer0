/** @type {import('tailwindcss').Config} */
// Design tokens mirrored 1:1 from the Flutter app's lib/theme/app_theme.dart
// (AppColors / AppGradients / AppRadius / AppShadows) so the web admin reads as
// the same product as the mobile app. Do not invent new brand colors here —
// change app_theme.dart first, then reflect the value below.
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // Brand — rose / pink family
        brand: {
          DEFAULT: '#DB2777', // AppColors.primary  (pink-600)
          bright: '#EC4899', // AppColors.primaryBright (pink-500)
          soft: '#FCE7F3', // AppColors.primarySoft (pink-100)
        },
        // Text
        ink: '#111827', // AppColors.ink   — headings
        body: '#374151', // AppColors.body  — body text
        muted: '#6B7280', // AppColors.muted — secondary
        faint: '#9CA3AF', // AppColors.faint — tertiary / hints
        // Surfaces
        canvas: '#F7F8FB', // AppColors.background
        card: '#FFFFFF', // AppColors.card
        hairline: '#EDEFF3', // AppColors.border
        // Accents (KPIs, charts, badges)
        indigo: '#6366F1',
        amber: '#F59E0B',
        emerald: '#10B981',
        violet: '#8B5CF6',
        sky: '#0EA5E9',
        danger: '#EF4444',
      },
      borderRadius: {
        // AppRadius
        sm: '12px',
        md: '16px',
        lg: '20px',
        xl: '28px',
      },
      boxShadow: {
        // AppShadows.soft — Color(0x0F101828), blur 24, offset (0,8)
        soft: '0 8px 24px rgba(16, 24, 40, 0.06)',
        // AppShadows.brand — brand tint
        brand: '0 8px 18px rgba(219, 39, 119, 0.30)',
      },
      backgroundImage: {
        // AppGradients.brand — topLeft #F472B6 -> bottomRight #DB2777
        brand: 'linear-gradient(135deg, #F472B6 0%, #DB2777 100%)',
      },
      fontFamily: {
        sans: [
          'Inter',
          'system-ui',
          '-apple-system',
          'Segoe UI',
          'Roboto',
          'Helvetica',
          'Arial',
          'sans-serif',
        ],
      },
    },
  },
  plugins: [],
};
