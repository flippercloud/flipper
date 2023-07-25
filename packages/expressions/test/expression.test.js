import { describe, test, expect } from 'vitest'
import { Expression, Function, Constant, Schema } from '../lib'

describe('Expression', () => {
  describe('build', () => {
    test('builds an expression from an object', () => {
      const expression = Expression.build({ All: [true] })
      expect(expression).toBeInstanceOf(Function)
      expect(expression.name).toEqual('All')
      expect(expression.args[0]).toBeInstanceOf(Constant)
      expect(expression.args[0].value).toBe(true)
      expect(expression.args[0].parent).toBe(expression)
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

  describe('add', () => {
    test('Any returns new expression with added arg', () => {
      const expression = Expression.build({ Any: [] }).add(true)
      expect(expression.value).toEqual({ Any: [true] })
    })

    test('Max returns new expression with added arg', () => {
      const expression = Expression.build({ Max: [1] }).add(2)
      expect(expression.value).toEqual({ Max: [1, 2] })
    })

    test('Equal returns new expression wrapped in All', () => {
      const expression = Expression.build({ Equal: [1, 1] }).add(false)
      expect(expression.value).toEqual({ All: [{ Equal: [1, 1] }, false] })
    })

    test('Constant returns new expression wrapped in All', () => {
      const expression = Expression.build(true).add(false)
      expect(expression.value).toEqual({ All: [true, false] })
    })
  })
})
