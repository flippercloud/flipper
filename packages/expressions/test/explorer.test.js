import { describe, test, expect } from 'vitest'
import { explorer } from '../lib'

describe('explorer', () => {
  test('resolves refs', () => {
    const schema = explorer.get('#')
    expect(schema.anyOf).not.toBeUndefined()
  })

  describe('functions', () => {
    test('returns all functions with their schemas', () => {
      expect(Object.keys(explorer.functions)).toEqual(expect.arrayContaining([
        'All', 'Any', 'Boolean', 'Time'
      ]))
      expect(explorer.functions.All.title).toEqual('All')
    })
  })
})
