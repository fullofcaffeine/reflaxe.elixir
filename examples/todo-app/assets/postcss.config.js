// PostCSS configuration for todo-app
module.exports = {
  plugins: {
    // Import CSS files
    'postcss-import': {},
    
    // Process Tailwind CSS
    tailwindcss: {},
    
    // Add vendor prefixes
    autoprefixer: {},
    
    // Minify CSS in production
    ...(process.env.NODE_ENV === 'production' ? {
      cssnano: {
        preset: 'default',
      }
    } : {})
  }
};