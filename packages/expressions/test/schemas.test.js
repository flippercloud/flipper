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

  describe('get', () => {
    test('returns a validator', () => {
      const ref = schema.get('#')
      expect(ref.schema.title).toEqual('Expression')
    })

    test('resolves refs', () => {
      const ref = schema.get('#/definitions/function/properties/Any')
      expect(ref.schema.title).toEqual('Any')
    })
  })
})
