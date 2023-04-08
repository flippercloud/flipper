import { describe, test, expect } from 'vitest'
import { Constant, schema } from '../lib'

describe('Constant', () => {
  describe('validator', () => {
    test('returns Constant validator', () => {
      expect(new Constant('string').validator.schema.title).toEqual('Constant')
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
  })

  describe('matches', () => {
    test('returns true for matching validator', () => {
      const validator = schema.get('#/definitions/constant/anyOf/0')
      expect(new Constant('string').matches(validator)).toBe(true)
    })

    test('returns false for different schema', () => {
      const validator = schema.get('#/definitions/constant/anyOf/0')
      expect(new Constant(true).matches(validator)).toBe(false)
    })
  })
})
