// Tailwind CSS configuration for todo-app with Haxe dual-target compilation
module.exports = {
  content: [
    // Phoenix templates
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex",
    "../lib/**/*_html.ex",
    
    // JavaScript files (including generated Haxe code)
    "./js/**/*.js",
    
    // Haxe source files (for HXX templates and className usage)
    "../src_haxe/**/*.hx",
    
    // Static HTML files if any
    "../priv/static/**/*.html"
  ],
  darkMode: 'class', // Enable class-based dark mode
  theme: {
    extend: {
      // Custom colors for todo app
      colors: {
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
        },
        success: {
          50: '#f0fdf4',
          100: '#dcfce7',
          200: '#bbf7d0',
          300: '#86efac',
          400: '#4ade80',
          500: '#22c55e',
          600: '#16a34a',
          700: '#15803d',
          800: '#166534',
          900: '#14532d',
        },
        danger: {
          50: '#fef2f2',
          100: '#fee2e2',
          200: '#fecaca',
          300: '#fca5a5',
          400: '#f87171',
          500: '#ef4444',
          600: '#dc2626',
          700: '#b91c1c',
          800: '#991b1b',
          900: '#7f1d1d',
        }
      },
      
      // Custom fonts
      fontFamily: {
        'inter': ['Inter', 'system-ui', 'sans-serif'],
        'mono': ['JetBrains Mono', 'Monaco', 'Cascadia Code', 'Roboto Mono', 'monospace'],
      },
      
      // Custom animations for todo interactions
      animation: {
        'fade-in': 'fadeIn 0.2s ease-in-out',
        'fade-out': 'fadeOut 0.2s ease-in-out',
        'slide-in': 'slideIn 0.3s ease-out',
        'slide-out': 'slideOut 0.3s ease-in',
        'bounce-soft': 'bounceSoft 0.6s ease-in-out',
        'pulse-soft': 'pulseSoft 2s ease-in-out infinite',
      },
      
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0', transform: 'translateY(-4px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        fadeOut: {
          '0%': { opacity: '1', transform: 'translateY(0)' },
          '100%': { opacity: '0', transform: 'translateY(-4px)' },
        },
        slideIn: {
          '0%': { opacity: '0', transform: 'translateX(-16px)' },
          '100%': { opacity: '1', transform: 'translateX(0)' },
        },
        slideOut: {
          '0%': { opacity: '1', transform: 'translateX(0)' },
          '100%': { opacity: '0', transform: 'translateX(-16px)' },
        },
        bounceSoft: {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-2px)' },
        },
        pulseSoft: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.8' },
        }
      },
      
      // Custom spacing for todo items
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
      },
      
      // Custom shadows
      boxShadow: {
        'soft': '0 2px 4px 0 rgba(0, 0, 0, 0.05)',
        'medium': '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
        'strong': '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
      },
      
      // Custom border radius
      borderRadius: {
        'xl': '0.75rem',
        '2xl': '1rem',
        '3xl': '1.5rem',
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms')({
      strategy: 'class', // Use class-based form styling
    }),
    require('@tailwindcss/typography'),
    
    // Custom plugin for todo-specific utilities
    function({ addUtilities, theme }) {
      const newUtilities = {
        // Todo item states
        '.todo-item': {
          '@apply transition-all duration-200 ease-in-out': {},
          '@apply border border-gray-200 dark:border-gray-700': {},
          '@apply bg-white dark:bg-gray-800': {},
          '@apply rounded-lg shadow-soft hover:shadow-medium': {},
        },
        '.todo-item-completed': {
          '@apply opacity-60 bg-gray-50 dark:bg-gray-900': {},
          '@apply line-through text-gray-500 dark:text-gray-400': {},
        },
        '.todo-item-priority-high': {
          '@apply border-l-4 border-l-danger-500': {},
        },
        '.todo-item-priority-medium': {
          '@apply border-l-4 border-l-primary-500': {},
        },
        '.todo-item-priority-low': {
          '@apply border-l-4 border-l-success-500': {},
        },
        
        // Form utilities
        '.form-input-focus': {
          '@apply focus:ring-2 focus:ring-primary-500 focus:border-primary-500': {},
          '@apply dark:focus:ring-primary-400 dark:focus:border-primary-400': {},
        },
        
        // Button utilities
        '.btn-primary': {
          '@apply bg-primary-600 hover:bg-primary-700 focus:ring-primary-500': {},
          '@apply text-white font-medium py-2 px-4 rounded-lg': {},
          '@apply transition-colors duration-200': {},
        },
        '.btn-secondary': {
          '@apply bg-gray-200 hover:bg-gray-300 focus:ring-gray-500': {},
          '@apply dark:bg-gray-700 dark:hover:bg-gray-600': {},
          '@apply text-gray-900 dark:text-gray-100 font-medium py-2 px-4 rounded-lg': {},
          '@apply transition-colors duration-200': {},
        },
        
        // Status indicators
        '.status-online': {
          '@apply text-success-600 dark:text-success-400': {},
        },
        '.status-offline': {
          '@apply text-danger-600 dark:text-danger-400': {},
        },
        '.status-syncing': {
          '@apply text-primary-600 dark:text-primary-400 animate-pulse-soft': {},
        },
      };
      
      addUtilities(newUtilities);
    }
  ],
};