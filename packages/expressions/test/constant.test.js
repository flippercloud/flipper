import { describe, test, expect } from 'vitest'
import { Constant, Schema } from '../lib'

describe('Constant', () => {
  describe('schema', () => {
    test('defaults to expression schema', () => {
      expect(new Constant('string').schema.title).toEqual('Expression')
    })

    test('uses provided schema', () => {
      const schema = Schema.resolve('#/definitions/number')
      const number = new Constant(42, { schema })
      expect(number.schema).toEqual(schema)
      expect(number.clone(99).schema).toEqual(schema)
    })
  })

  describe('validate', () => {
    test('returns true for valid value', () => {
      expect(new Constant(true).validate().valid).toBe(true)
      expect(new Constant(false).validate().valid).toBe(true)
      expect(new Constant('string').validate().valid).toBe(true)
      expect(new Constant(42).validate().valid).toBe(true)
      expect(new Constant(3.14).validate().valid).toBe(true)
    })

    test('returns false for invalid value', () => {
      expect(new Constant(['array']).validate().valid).toBe(false)
    })

    test('uses provided schema', () => {
      const schema = Schema.resolve('#/definitions/number')
      expect(new Constant(42, { schema }).validate().valid).toBe(true)
      expect(new Constant(42).validate(schema).valid).toBe(true)

      expect(new Constant('nope', { schema }).validate().valid).toBe(false)
      expect(new Constant('nope').validate(schema).valid).toBe(false)
    })
  })

  describe('matches', () => {
    test('returns true for matching validator', () => {
      const schema = Schema.resolve('#/definitions/constant/anyOf/0')
      expect(new Constant('string').matches(schema)).toBe(true)
    })

    test('returns false for different schema', () => {
      const schema = Schema.resolve('#/definitions/constant/anyOf/0')
      expect(new Constant(true).matches(schema)).toBe(false)
    })
  })
})
