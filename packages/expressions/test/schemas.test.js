import { describe, test, expect } from 'vitest'
import { validate } from '../lib'
import examples from '../examples'

expect.extend({
  toBeValid (received) {
    const { valid, errors } = validate(received)
    return {
      pass: valid,
      message: () => JSON.stringify(errors, null, 2)
    }
  }
})

describe('expressions.schema.json', () => {
  for (const [name, example] of Object.entries(examples)) {
    describe(name, () => {
      describe('valid', () => {
        example.valid.forEach(({ expression }) => {
          test(JSON.stringify(expression), () => {
            expect(expression).toBeValid()
          })
        })
      })

      describe('invalid', () => {
        example.invalid.forEach(expression => {
          test(JSON.stringify(expression), () => {
            expect(expression).not.toBeValid()
          })
        })
      })
    })
  }
})
