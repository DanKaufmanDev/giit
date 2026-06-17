import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  // Custom-domain GitHub Pages sites are served from the domain root.
  base: '/giit/',
  // Honor a PORT override when one is provided by the environment.
  server: process.env.PORT ? { port: Number(process.env.PORT) } : undefined,
})
