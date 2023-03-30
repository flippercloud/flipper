// vite.config.js
import { resolve } from 'path'
import { defineConfig } from 'vite'

export default defineConfig({
  build: {
    lib: {
      entry: resolve(__dirname, 'lib/index.js'),
      name: '@flippercloud.io/expressions'
    },
    rollupOptions: {
      external: [
        'ajv',
        'ajv-formats'
      ],
      output: {}
    }
  }
})
