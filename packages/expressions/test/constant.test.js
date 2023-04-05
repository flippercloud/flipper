import { describe, test, expect } from 'vitest'
import { Constant } from '../lib'

describe('Constant', () => {
  describe('schema', () => {
    test('returns `{ type: "string" }` for string value', () => {
      expect(new Constant('string').schema).toEqual({ type: 'string' })
    })

    test('returns `{ type: "boolean" }` for boolean value', () => {
      expect(new Constant(true).schema).toEqual({ type: 'boolean' })
    })

    test('returns `{ type: "number" }` for number value', () => {
      expect(new Constant(42).schema).toEqual({ type: 'number' })
    })
  })

  describe('validate', () => {
    test('returns true for valid value', () => {
      expect(new Constant(true).validate().valid).toBe(true)
    })
  })

  describe('matches', () => {
    test('returns true matching schema', () => {
      expect(new Constant(true).matches({ type: 'boolean' })).toBe(true)
    })

    test('returns false for different schema', () => {
      expect(new Constant('string').matches({ type: 'boolean' })).toBe(false)
    })
  })
})
