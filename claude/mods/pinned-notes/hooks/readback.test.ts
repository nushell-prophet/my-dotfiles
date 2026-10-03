import { expect, test } from 'claude-code/testing'

import { italicPieces, mergeLines, parseReadback } from './readback'

test('keeps Guessed, Said properly and the closing ASSUMED list, drops You asked', () => {
  const answer = [
    '**You asked:** Build the band mod.',
    '**Guessed:** a guess',
    '**Said properly:** "That *is* cool, go" (spelling only)',
    '',
    'Work report, with an ASSUMED claim inline.',
    '',
    'ASSUMED:',
    '- the band fills after the first step',
    '- the mark is 4 cells wide',
    '',
    'Trailing line.',
  ].join('\n')

  expect(parseReadback(answer)).toEqual([
    { label: 'Guessed', text: 'a guess' },
    { label: 'Said properly', text: '"That *is* cool, go" (spelling only)' },
    { label: 'ASSUMED', text: 'the band fills after the first step\nthe mark is 4 cells wide' },
  ])
})

test('an answer with neither gives nothing', () => {
  expect(parseReadback('**You asked:** only a readback\n\ndone')).toEqual([])
})

test('a later step adds ASSUMED without dropping Said properly', () => {
  const said = { label: 'Said properly', text: 'x' }
  const assumed = { label: 'ASSUMED', text: 'y' }
  expect(mergeLines([said], [assumed])).toEqual([said, assumed])
  expect(mergeLines([assumed], [said])).toEqual([said, assumed])
})

test('italic words land on the odd pieces', () => {
  expect(italicPieces('a *b* c *d*')).toEqual(['a ', 'b', ' c ', 'd', ''])
})
