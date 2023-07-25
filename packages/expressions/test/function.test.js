import { describe, test, expect } from 'vitest'
import { Expression, Function, Constant } from '../lib'

describe('Function', () => {
  describe('clone', () => {
    test('returns new expression', () => {
      const expression = Expression.build({ All: [true] })
      const clone = expression.clone()
      expect(clone).not.toBe(expression)
      expect(clone).toBeInstanceOf(Function)
      expect(clone.name).toEqual(expression.name)
      expect(clone.args).toEqual(expression.args)
      expect(clone.id).toEqual(expression.id)
      expect(clone.args[0].parent).toBe(clone)
      expect(clone.args[0].depth).toBe(1)
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
