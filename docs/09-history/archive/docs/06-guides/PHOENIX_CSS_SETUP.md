# Phoenix CSS Setup with Tailwind

A comprehensive guide for setting up and organizing custom CSS in Phoenix applications with Tailwind CSS.

## 📁 CSS File Organization

In Phoenix with Tailwind, custom CSS is organized as follows:

```
assets/
├── css/
│   ├── app.css           # Main entry point - imports everything
│   ├── components.css    # Custom component classes
│   ├── utilities.css      # Custom utility classes
│   └── animations.css     # Custom animations
├── js/
│   └── app.js            # JavaScript entry point
└── tailwind.config.js    # Tailwind configuration
```

## 🎨 Main CSS File Structure (assets/css/app.css)

The `app.css` file is your main entry point for all CSS:

```css
/* assets/css/app.css */

/* Import Tailwind's base styles */
@import "tailwindcss/base";
@import "tailwindcss/components";
@import "tailwindcss/utilities";

/* Import custom CSS files */
@import "./components.css";
@import "./utilities.css";
@import "./animations.css";

/* ============================================================================
   BASE CUSTOMIZATIONS
   Override Tailwind's base styles or add custom resets
   ============================================================================ */

@layer base {
  /* Custom font families */
  @font-face {
    font-family: 'CustomFont';
    src: url('/fonts/custom-font.woff2') format('woff2');
  }
  
  /* Override default styles */
  h1 {
    @apply text-4xl font-bold mb-4;
  }
  
  h2 {
    @apply text-3xl font-semibold mb-3;
  }
  
  h3 {
    @apply text-2xl font-medium mb-2;
  }
  
  /* Custom focus styles */
  *:focus {
    @apply outline-none ring-2 ring-blue-500 ring-offset-2;
  }
}

/* ============================================================================
   COMPONENT CLASSES
   Reusable component styles using Tailwind's @apply directive
   ============================================================================ */

@layer components {
  /* Button variants */
  .btn {
    @apply px-4 py-2 rounded-lg font-medium transition-all duration-200;
    @apply focus:outline-none focus:ring-2 focus:ring-offset-2;
  }
  
  .btn-primary {
    @apply bg-blue-600 text-white hover:bg-blue-700;
    @apply focus:ring-blue-500;
  }
  
  .btn-secondary {
    @apply bg-gray-200 text-gray-800 hover:bg-gray-300;
    @apply focus:ring-gray-500;
  }
  
  .btn-danger {
    @apply bg-red-600 text-white hover:bg-red-700;
    @apply focus:ring-red-500;
  }
  
  /* Card components */
  .card {
    @apply bg-white rounded-lg shadow-md p-6;
    @apply border border-gray-200;
  }
  
  .card-header {
    @apply text-xl font-semibold mb-4 pb-2 border-b border-gray-200;
  }
  
  .card-body {
    @apply space-y-4;
  }
  
  /* Form components */
  .form-input {
    @apply w-full px-3 py-2 border border-gray-300 rounded-md;
    @apply focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent;
    @apply placeholder-gray-400;
  }
  
  .form-label {
    @apply block text-sm font-medium text-gray-700 mb-1;
  }
  
  .form-error {
    @apply text-red-600 text-sm mt-1;
  }
  
  /* Table styles */
  .table-auto-styled {
    @apply min-w-full divide-y divide-gray-200;
  }
  
  .table-auto-styled thead {
    @apply bg-gray-50;
  }
  
  .table-auto-styled th {
    @apply px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider;
  }
  
  .table-auto-styled td {
    @apply px-6 py-4 whitespace-nowrap text-sm text-gray-900;
  }
  
  /* Badge/Tag styles */
  .badge {
    @apply inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium;
  }
  
  .badge-success {
    @apply bg-green-100 text-green-800;
  }
  
  .badge-warning {
    @apply bg-yellow-100 text-yellow-800;
  }
  
  .badge-danger {
    @apply bg-red-100 text-red-800;
  }
  
  .badge-info {
    @apply bg-blue-100 text-blue-800;
  }
}

/* ============================================================================
   UTILITY CLASSES
   Custom utility classes that extend Tailwind
   ============================================================================ */

@layer utilities {
  /* Text gradients */
  .text-gradient {
    @apply bg-gradient-to-r from-blue-600 to-purple-600;
    @apply bg-clip-text text-transparent;
  }
  
  /* Custom animations */
  .animate-fade-in {
    animation: fadeIn 0.5s ease-in;
  }
  
  .animate-slide-up {
    animation: slideUp 0.3s ease-out;
  }
  
  .animate-pulse-slow {
    animation: pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite;
  }
  
  /* Scrollbar customization */
  .scrollbar-thin {
    scrollbar-width: thin;
    scrollbar-color: theme('colors.gray.400') theme('colors.gray.100');
  }
  
  .scrollbar-thin::-webkit-scrollbar {
    width: 8px;
    height: 8px;
  }
  
  .scrollbar-thin::-webkit-scrollbar-track {
    @apply bg-gray-100;
  }
  
  .scrollbar-thin::-webkit-scrollbar-thumb {
    @apply bg-gray-400 rounded-full;
  }
  
  /* Glassmorphism effect */
  .glass {
    @apply bg-white bg-opacity-60 backdrop-blur-lg;
    @apply border border-white border-opacity-20;
  }
  
  /* Neon glow effect */
  .neon-glow {
    @apply shadow-lg;
    box-shadow: 
      0 0 20px theme('colors.blue.400'),
      0 0 40px theme('colors.blue.600'),
      0 0 60px theme('colors.blue.800');
  }
  
  /* Truncate with lines */
  .line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
  
  .line-clamp-3 {
    display: -webkit-box;
    -webkit-line-clamp: 3;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
}

/* ============================================================================
   ANIMATIONS
   Custom keyframe animations
   ============================================================================ */

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@keyframes slideUp {
  from {
    transform: translateY(20px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

@keyframes bounceIn {
  0% {
    transform: scale(0.3);
    opacity: 0;
  }
  50% {
    transform: scale(1.05);
  }
  70% {
    transform: scale(0.9);
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}

/* ============================================================================
   DARK MODE SUPPORT
   Custom dark mode overrides using Tailwind's dark variant
   ============================================================================ */

@layer components {
  .dark .card {
    @apply bg-gray-800 border-gray-700;
  }
  
  .dark .form-input {
    @apply bg-gray-700 border-gray-600 text-white;
    @apply placeholder-gray-400;
  }
  
  .dark .form-label {
    @apply text-gray-200;
  }
  
  .dark .table-auto-styled thead {
    @apply bg-gray-700;
  }
  
  .dark .table-auto-styled th {
    @apply text-gray-300;
  }
  
  .dark .table-auto-styled td {
    @apply text-gray-100;
  }
}
```

## 🎯 Tailwind Configuration (tailwind.config.js)

Customize Tailwind for your Phoenix app:

```javascript
// assets/tailwind.config.js
module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex",
    "../lib/*_web/**/*.heex"  // Include HEEx templates
  ],
  darkMode: 'class', // Enable dark mode with class strategy
  theme: {
    extend: {
      // Custom colors
      colors: {
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          // ... full palette
          900: '#1e3a8a',
        },
        brand: {
          light: '#3fbaeb',
          DEFAULT: '#0fa9e6',
          dark: '#0c87b8',
        },
      },
      
      // Custom fonts
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'sans-serif'],
        display: ['Lexend', 'sans-serif'],
        mono: ['Fira Code', 'monospace'],
      },
      
      // Custom spacing
      spacing: {
        '88': '22rem',
        '128': '32rem',
      },
      
      // Custom animations
      animation: {
        'fade-in': 'fadeIn 0.5s ease-in',
        'slide-up': 'slideUp 0.3s ease-out',
        'bounce-in': 'bounceIn 0.5s ease-out',
      },
      
      // Custom breakpoints
      screens: {
        '3xl': '1920px',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/aspect-ratio'),
  ],
};
```

## 🚀 Best Practices

### 1. Use Tailwind's @layer Directive
Always wrap custom styles in the appropriate layer:
- `@layer base` - For resetting or overriding default element styles
- `@layer components` - For reusable component classes
- `@layer utilities` - For single-purpose utility classes

### 2. Prefer @apply Over Writing Raw CSS
```css
/* ✅ Good - Uses Tailwind utilities */
.btn-primary {
  @apply bg-blue-600 text-white px-4 py-2 rounded-lg;
}

/* ❌ Avoid - Raw CSS */
.btn-primary {
  background-color: #2563eb;
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
}
```

### 3. Component Composition Pattern
Build complex components from smaller utilities:
```css
.card-featured {
  @apply card;  /* Inherit base card styles */
  @apply border-2 border-blue-500;
  @apply shadow-xl;
}
```

### 4. Organize by Feature
For larger apps, split CSS by feature:
```
assets/css/
├── app.css
├── components/
│   ├── buttons.css
│   ├── forms.css
│   └── cards.css
└── features/
    ├── dashboard.css
    ├── user-profile.css
    └── admin.css
```

### 5. Use CSS Variables for Dynamic Values
```css
@layer base {
  :root {
    --color-primary: theme('colors.blue.600');
    --spacing-unit: 0.25rem;
    --border-radius: 0.5rem;
  }
}

.dynamic-component {
  color: var(--color-primary);
  padding: calc(var(--spacing-unit) * 4);
  border-radius: var(--border-radius);
}
```

## 🔄 Phoenix Integration

### Asset Pipeline Setup
Ensure your `config/config.exs` includes:
```elixir
config :my_app, MyAppWeb.Endpoint,
  # ...
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"assets/css/.*(css)$",  # Watch CSS changes
      ~r"lib/my_app_web/(live|views)/.*(ex|heex)$"
    ]
  ]
```

### Esbuild Configuration
In `config/config.exs`:
```elixir
config :esbuild,
  version: "0.14.29",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]
```

### Tailwind CLI Integration
In `mix.exs`:
```elixir
defp aliases do
  [
    # ...
    "assets.build": ["tailwind default --minify", "esbuild default --minify", "phx.digest"],
    "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
  ]
end
```

## 🎨 Example Usage in HXX Templates

Using your custom CSS classes in Haxe HXX templates:

```haxe
// Using custom component classes
HXX.hxx('<button className="btn btn-primary">
  Save Changes
</button>');

// Using custom utilities
HXX.hxx('<h1 className="text-gradient animate-fade-in">
  Welcome to Phoenix
</h1>');

// Combining Tailwind and custom classes
HXX.hxx('<div className="card glass neon-glow dark:bg-gray-900">
  <div className="card-header">
    Dashboard
  </div>
  <div className="card-body">
    <!-- Content -->
  </div>
</div>');

// Using responsive and state variants
HXX.hxx('<button className="btn btn-primary lg:btn-secondary hover:animate-pulse-slow">
  Responsive Button
</button>');
```

## 📚 Resources

- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [Phoenix Asset Management](https://hexdocs.pm/phoenix/asset_management.html)
- [Tailwind CSS IntelliSense](https://marketplace.visualstudio.com/items?itemName=bradlc.vscode-tailwindcss) - VS Code extension
- [Tailwind UI](https://tailwindui.com/) - Premium component library
- [Headless UI](https://headlessui.dev/) - Unstyled, accessible components

## Summary

The key locations for custom CSS in Phoenix with Tailwind are:
1. **`assets/css/app.css`** - Main entry point and custom styles
2. **`assets/tailwind.config.js`** - Tailwind configuration
3. **Component files** - Organize by feature as your app grows

Use Tailwind's `@layer` directive and `@apply` to create maintainable, reusable styles that integrate seamlessly with Phoenix and HXX templates.