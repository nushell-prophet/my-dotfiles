import type { ReadbackLine } from '../types'

const OPENING = /^\*\*(Guessed|Said properly):\*\*\s*(.*)$/
const ASSUMED = /^\**ASSUMED:\**\s*$/
const BULLET = /^[-*]\s+(.*)$/

// Why: the band holds only what the user needs while the agent works on —
// the guess, the English fix and the claims nobody could check; the
// "You asked" readback is too big for it.
export function parseReadback(answer: string): ReadbackLine[] {
  const rows = answer.split('\n').map(raw => raw.trim())
  const lines: ReadbackLine[] = []

  // First match of each label wins: these lines open the reply, a later one is a quote.
  for (const match of rows.map(row => row.match(OPENING))) {
    if (match && !lines.some(line => line.label === match[1])) {
      lines.push({ label: match[1], text: match[2] })
    }
  }

  // Last block wins: the ASSUMED list closes the reply.
  const start = rows.findLastIndex(row => ASSUMED.test(row))
  if (start !== -1) {
    const items = rows
      .slice(start + 1)
      .filter(row => row !== '')
      .map(row => row.match(BULLET))
    const end = items.findIndex(match => !match)
    const bullets = (end === -1 ? items : items.slice(0, end)).map(match => match![1])
    if (bullets.length > 0) {
      lines.push({ label: 'ASSUMED', text: bullets.join('\n') })
    }
  }
  return lines
}

// A step's lines replace the same labels from earlier steps and keep the rest:
// the opening lines come in the first step, ASSUMED in the last.
export function mergeLines(shown: ReadbackLine[], found: ReadbackLine[]): ReadbackLine[] {
  return [...shown.filter(old => !found.some(line => line.label === old.label)), ...found]
    .sort((a, b) => (a.label === 'ASSUMED' ? 1 : 0) - (b.label === 'ASSUMED' ? 1 : 0))
}

// Odd pieces are the *italic* words: in "Said properly:" they mark the fixes.
export function italicPieces(text: string): string[] {
  return text.split(/\*([^*]+)\*/)
}
