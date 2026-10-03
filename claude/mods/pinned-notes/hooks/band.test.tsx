import { expect, test } from 'claude-code/testing'

const BAND = { component: 'AbovePrompt', props: { hasSurvey: false, isWorking: true } } as const
const ANSWER = '**You asked:** Build the band mod.\n**Said properly:** "That *is* cool"\n\nWork report.\n\nASSUMED:\n- the mark is 4 cells wide'
const STEP = { turnId: 't1', index: 0, model: 'm', messageCount: 1 }

// The tests stand for the engine: a step whose reply is `answer`, and a band of its own.
function engine(on: Parameters<Parameters<typeof test>[1]>[1], answer: string) {
  on('turn.step', async function* (_$, e) {
    return { turnId: e.turnId, index: e.index, answer, toolUses: [], stopReason: 'end_turn', usage: null }
  })
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text key="engine">engine band</Text>
  })
}

async function step($: Parameters<Parameters<typeof test>[1]>[0], extra: object = {}) {
  const stream = $.turn.step({ ...STEP, ...extra })
  for await (const _ of stream) {}
  return stream.result
}

test('Said properly and ASSUMED are pinned, the readback is not', async ($, on) => {
  engine(on, ANSWER)
  await step($)
  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({ plugin: 'pinned-notes', surface, ...BAND })
    expect(await ui.find({ type: 'Text', text: /4 cells wide/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /^is$/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /Build the band mod/ })).toBeUndefined()
    await ui.unmount()
  }
})

test('a subagent readback is not pinned', async ($, on) => {
  engine(on, ANSWER)
  await step($, { agentId: 'a1' })
  const ui = await $.ui.mount({ plugin: 'pinned-notes', surface: 'terminal', ...BAND })
  expect(await ui.find({ type: 'Text', text: /engine band/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /4 cells wide/ })).toBeUndefined()
})

test('a new prompt clears the pinned readback', async ($, on) => {
  engine(on, ANSWER)
  on('prompt.submit', (_$, e) => e)
  await step($)
  await $.prompt.submit({ text: 'next' } as never)
  const ui = await $.ui.mount({ plugin: 'pinned-notes', surface: 'terminal', ...BAND })
  expect(await ui.find({ type: 'Text', text: /4 cells wide/ })).toBeUndefined()
})
