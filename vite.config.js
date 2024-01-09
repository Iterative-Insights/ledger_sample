import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import fs from 'fs/promises';
import environment from 'vite-plugin-environment';
import dotenv from 'dotenv';

dotenv.config();

export default defineConfig({
  plugins: [react(),
    environment('all', { prefix: 'CANISTER_' }),
    environment('all', { prefix: 'DFX_' }),
    environment({ LEDGER_SAMPLE_BACKEND_CANISTER_ID: '' }),],
  // esbuild: {
  //   loader: "jsx",
  //   include: /src\/.*\.jsx?$/,
  //   // loader: "tsx",
  //   // include: /src\/.*\.[tj]sx?$/,
  //   exclude: [],
  // },
  root: 'src/ledger_sample_frontend',
  build: {
    outDir: '../../dist',
    emptyOutDir: true
  },
  optimizeDeps: {
    esbuildOptions: {
      plugins: [
        {
          name: "load-js-files-as-jsx",
          setup(build) {
            // build.onLoad({ filter: /src\/.*\.js$/ }, async (args) => ({
            //   loader: "jsx",
            //   contents: await fs.readFile(args.path, "utf8"),
            // }));
          },
        },
      ],
    },
  },
});
