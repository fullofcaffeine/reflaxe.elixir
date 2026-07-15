import path from "node:path"
import {fileURLToPath} from "node:url"
import react from "@vitejs/plugin-react"
import {defineConfig} from "vite"
import liveReactPlugin from "live_react/vite-plugin"

const projectRoot = path.dirname(fileURLToPath(import.meta.url))
const assetRoot = path.join(projectRoot, "assets")

export default defineConfig(({command}) => ({
  root: assetRoot,
  base: command === "build" ? "/assets/" : undefined,
  publicDir: false,
  plugins: [react(), liveReactPlugin()],
  server: {
    host: "127.0.0.1",
    port: 5173,
    strictPort: true,
  },
  resolve: {
    dedupe: ["react", "react-dom"],
  },
  optimizeDeps: {
    include: ["live_react", "phoenix", "phoenix_html", "phoenix_live_view"],
  },
  build: {
    commonjsOptions: {transformMixedEsModules: true},
    target: "es2020",
    outDir: path.join(projectRoot, "priv/static/assets"),
    emptyOutDir: false,
    sourcemap: true,
    manifest: false,
    rollupOptions: {
      input: {
        app: path.join(assetRoot, "js/app.js"),
      },
      output: {
        entryFileNames: "[name].js",
        chunkFileNames: "[name]-[hash].js",
        assetFileNames: "[name][extname]",
      },
    },
  },
}))
