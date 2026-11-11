import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// GitHub Pages project sites serve from /<repo>/.
// The workflow sets VITE_BASE; local dev/preview uses '/'.
export default defineConfig({
  plugins: [react()],
  base: process.env.VITE_BASE || '/',
  publicDir: 'public',
  server: { port: 3000, open: true },
  preview: { port: 4173 }
});
