import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import { italicPieces, mergeLines, parseReadback } from './readback'

const lines = atom({ plugin: 'pinned-notes', key: 'lines' } as const, [])

export const register: Register = on => {
  // Why: lines from the previous prompt would pass for the answer to the new one.
  on('prompt.submit', async ($, e, next) => {
    await update($, lines, () => [])
    return next(e)
  })

  on('turn.step', async function* ($, e, next) {
    const result = yield* next(e)
    const found = parseReadback(result.answer)
    // Why: a subagent's reply carries no readback for the user.
    if (e.agentId === undefined && found.length > 0) {
      await update($, lines, shown => mergeLines(shown, found))
    }
    return result
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const shown = await read($, lines)
    if (e.props.hasSurvey || shown.length === 0) {
      return next(e)
    }

    const { Box, Text } = $.ui.resolve(e)

    // Why: the engine draws its `[-]` collapse mark over the band's top-right
    // cells; without the gutter it hides the last letters of the first row.
    return (
      <Box flexDirection="column" paddingRight={4}>
        {shown.map(line => (
          <Text key={line.label}>
            <Text bold>{line.label}: </Text>
            {italicPieces(line.text).map((piece, i) =>
              i % 2 === 1 ? <Text key={i} italic color="cyan">{piece}</Text> : piece,
            )}
          </Text>
        ))}
      </Box>
    )
  })
}
