import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

const repoName = process.env.GITHUB_REPOSITORY
  ? process.env.GITHUB_REPOSITORY.split('/')[1]
  : '';

// Local dev/preview serve from /; Pages serves from /<repo>/.
// VITE_BASE overrides both. See ADR-021.
export default defineConfig({
  plugins: [react()],
  base: process.env.VITE_BASE || (repoName ? '/' + repoName + '/' : '/'),
  publicDir: 'public',
  server: { port: 3000, open: true },
  preview: { port: 4173 }
});
