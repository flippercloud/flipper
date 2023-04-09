import { describe, test, expect } from 'vitest'
import { examples, schema, Expression } from '../lib'

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
      const ref = schema.resolve('#/definitions/constant')
      expect(ref.title).toEqual('Constant')
      expect(ref.validate(true)).toEqual({ valid: true, errors: null })
    })

    test('resolves refs', () => {
      expect(schema.resolve('#/definitions/function/properties/Any').title).toEqual('Any')
      expect(schema.definitions.function.properties.Any.title).toEqual('Any')
    })
  })

  describe('resolveAnyOf', () => {
    test('returns nested anyOf', () => {
      expect(schema.resolveAnyOf()).toHaveLength(4)
    })

    test('returns array of schemas', () => {
      const ref = schema.resolve('#/definitions/constant')
      expect(ref.resolveAnyOf()).toHaveLength(3)
      expect(ref.resolveAnyOf()).toEqual(ref.anyOf)
    })
  })

  describe('arrayItem', () => {
    test('returns schema for repeated array item', () => {
      const any = schema.resolve("Any.schema.json")
      expect(any.arrayItem(0).title).toEqual('Expression')
      expect(any.arrayItem(99).title).toEqual('Expression')
    })

    test('returns schema for tuple', () => {
      const duration = schema.resolve("Duration.schema.json")
      expect(duration.arrayItem(0).title).toEqual('Number')
      expect(duration.arrayItem(1).title).toEqual('Unit')
      expect(duration.arrayItem(2)).toBe(undefined)
    })
  })
})
