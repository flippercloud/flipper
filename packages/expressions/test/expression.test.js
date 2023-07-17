import { describe, test, expect } from 'vitest'
import { Expression, Constant, Schema } from '../lib'

describe('Expression', () => {
  describe('build', () => {
    test('builds an expression from an object', () => {
      const expression = Expression.build({ All: [true] })
      expect(expression.name).toEqual('All')
      expect(expression.args[0]).toBeInstanceOf(Constant)
      expect(expression.args[0].value).toEqual(true)
      expect(expression.value).toEqual({ All: [true] })
    })

    test('builds an expression from a boolean constant', () => {
      const expression = Expression.build(true)
      expect(expression).toBeInstanceOf(Constant)
      expect(expression.value).toEqual(true)
    })

    test('builds an expression from a string constant', () => {
      const expression = Expression.build('hello')
      expect(expression).toBeInstanceOf(Constant)
      expect(expression.value).toEqual('hello')
    })

    test('builds an expression from a null constant', () => {
      const expression = Expression.build(null)
      expect(expression).toBeInstanceOf(Constant)
      expect(expression.value).toEqual(null)
    })

    test('throws error on invalid expression', () => {
      expect(() => Expression.build([])).toThrowError(TypeError)
      expect(() => Expression.build(new Date())).toThrowError(TypeError)
      expect(() => Expression.build({ All: [], Any: [] })).toThrowError(TypeError)
    })

    test('sets schema for constant args', () => {
      const expression = Expression.build({ Duration: [5, 'minutes'] })
      const schema = Schema.resolve('Duration.schema.json')
      expect(expression.schema).toEqual(schema)
      expect(expression.args[0].schema).toEqual(schema.items[0])
      expect(expression.args[1].schema).toEqual(schema.items[1])
    })

    test('sets schema for constant', () => {
      const expression = Expression.build(false)
      expect(expression.schema.$id).toEqual(Schema.resolve('#').$id)
    })

    test('each subexpression uses its own schema', () => {
      const expression = Expression.build({ GreaterThan: [{ Now: [] }, { Property: ['released_at'] }] })
      expect(expression.schema).toEqual(Schema.resolve('GreaterThan.schema.json'))
      expect(expression.args[0].schema).toEqual(Schema.resolve('Now.schema.json'))
      expect(expression.args[1].schema).toEqual(Schema.resolve('Property.schema.json'))
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
