export type ReadbackLine = { label: string; text: string }

declare module 'claude-code' {
  interface PluginState {
    'pinned-notes': { lines: ReadbackLine[] }
  }
}
