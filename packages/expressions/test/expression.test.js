import { describe, test, expect } from 'vitest'
import { Expression, Constant } from '../lib'

describe('Expression', () => {
  describe('build', () => {
    test('builds an expression from an object', () => {
      const expression = Expression.build({ All: [true] })
      expect(expression.name).toEqual('All')
      expect(expression.args[0]).toBeInstanceOf(Constant)
      expect(expression.args[0].value).toEqual(true)
      expect(expression.value).toEqual({ All: [true] })
    })

    test('throws error on invalid expression', () => {
      expect(() => Expression.build([])).toThrowError(TypeError)
      expect(() => Expression.build(new Date())).toThrowError(TypeError)
      expect(() => Expression.build({ All: [], Any: [] })).toThrowError(TypeError)
    })
  })

  describe('clone', () => {
    test('returns new expression', () => {
      const expression = Expression.build({ All: [true] })
      const clone = expression.clone()
      expect(clone).not.toBe(expression)
      expect(clone.name).toEqual(expression.name)
      expect(clone.args).toEqual(expression.args)
      expect(clone.id).toEqual(expression.id)
    })

    test('builds args', () => {
      const expression = Expression.build({ All: [] })
      const clone = expression.clone({ args: [true] })
      expect(clone.args[0]).toBeInstanceOf(Constant)
      expect(clone.value).toEqual({ All: [true] })
    })
  })

  describe('validate', () => {
    test('passes for valid expression', () => {
      const expression = Expression.build({ All: [true] })
      expect(expression.validate().valid).toBe(true)
    })

    test('fails for invalid expression', () => {
      const expression = Expression.build({ Duration: [] })
      expect(expression.validate().valid).toBe(false)
    })
  })
})
