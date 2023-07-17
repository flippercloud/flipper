import { describe, test, expect } from 'vitest'
import { examples, Schema, Expression } from '../lib'

describe('schema.json', () => {
  for (const [name, example] of Object.entries(examples)) {
    describe(name, () => {
      describe('valid', () => {
        example.valid.forEach(({ expression }) => {
          test(JSON.stringify(expression), () => {
            const { valid, errors } = Expression.build(expression).validate()
            expect(errors).toBe(null)
            expect(valid).toBe(true)
          })
        })
      })

      describe('invalid', () => {
        example.invalid.forEach(expression => {
          test(JSON.stringify(expression), () => {
            try {
              const { valid, errors } = Expression.build(expression).validate()
              expect(errors).not.toEqual(null)
              expect(valid).toBe(false)
            } catch (error) {
              if (error instanceof TypeError) {
                // ok
              } else {
                throw error
              }
            }
          })
        })
      })
    })
  }

  describe('resolve', () => {
    test('returns a schema', () => {
      const ref = Schema.resolve('#/definitions/constant')
      expect(ref.title).toEqual('Constant')
      expect(ref.validate(true)).toEqual({ valid: true, errors: null })
    })

    test('resolves refs', () => {
      expect(Schema.resolve('#/definitions/function/properties/Any').title).toEqual('Any')
      expect(Schema.resolve('#').definitions.function.properties.Any.title).toEqual('Any')
    })

    test('returns array values', () => {
      const expected = ['seconds', 'minutes', 'hours', 'days', 'weeks', 'months', 'years']
      expect(Schema.resolve('Duration.schema.json#/items/1/anyOf/0').enum).toEqual(expected)
    })
  })

  describe('resolveAnyOf', () => {
    test('returns nested anyOf', () => {
      const ref = Schema.resolve('#')
      expect(ref.resolveAnyOf()).toHaveLength(5)
    })

    test('returns array of schemas', () => {
      const ref = Schema.resolve('#/definitions/constant')
      expect(ref.resolveAnyOf()).toHaveLength(4)
      expect(ref.resolveAnyOf()).toEqual(ref.anyOf)
    })
  })

  describe('arrayItem', () => {
    test('returns schema for repeated array item', () => {
      const any = Schema.resolve('Any.schema.json')
      expect(any.arrayItem(0).title).toEqual('Expression')
      expect(any.arrayItem(99).title).toEqual('Expression')
    })

    test('returns schema for tuple', () => {
      const duration = Schema.resolve('Duration.schema.json')
      expect(duration.arrayItem(0).$id).toMatch('schema.json#/definitions/number')
      expect(duration.arrayItem(1).$id).toMatch('Duration.schema.json#/items/1')
      expect(duration.arrayItem(2)).toBe(undefined)
    })
  })
})
