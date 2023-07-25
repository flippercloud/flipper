import { describe, test, expect } from 'vitest'
import { Constant, Schema } from '../lib'

describe('Constant', () => {
  describe('schema', () => {
    test('defaults to expression schema', () => {
      expect(new Constant({ value: 'string' }).schema.title).toEqual('Expression')
    })

    test('uses provided schema', () => {
      const schema = Schema.resolve('#/definitions/number')
      const number = new Constant({ value: 42, schema })
      expect(number.schema).toEqual(schema)
      expect(number.clone({ value: 99 }).schema).toEqual(schema)
    })
  })

  describe('validate', () => {
    test('returns true for valid value', () => {
      expect(new Constant({ value: true }).validate().valid).toBe(true)
      expect(new Constant({ value: false }).validate().valid).toBe(true)
      expect(new Constant({ value: 'string' }).validate().valid).toBe(true)
      expect(new Constant({ value: 42 }).validate().valid).toBe(true)
      expect(new Constant({ value: 3.14 }).validate().valid).toBe(true)
    })

    test('returns false for invalid value', () => {
      expect(new Constant({ value: ['array'] }).validate().valid).toBe(false)
    })

    test('uses provided schema', () => {
      const schema = Schema.resolve('#/definitions/number')
      expect(new Constant({ value: 42, schema }).validate().valid).toBe(true)
      expect(new Constant({ value: 42 }).validate(schema).valid).toBe(true)

      expect(new Constant({ value: 'nope', schema }).validate().valid).toBe(false)
      expect(new Constant({ value: 'nope' }).validate(schema).valid).toBe(false)
    })
  })

  describe('matches', () => {
    test('returns true for matching validator', () => {
      const schema = Schema.resolve('#/definitions/constant/anyOf/0')
      expect(new Constant({ value: 'string' }).matches(schema)).toBe(true)
    })

    test('returns false for different schema', () => {
      const schema = Schema.resolve('#/definitions/constant/anyOf/0')
      expect(new Constant({ value: true }).matches(schema)).toBe(false)
    })
  })
})
