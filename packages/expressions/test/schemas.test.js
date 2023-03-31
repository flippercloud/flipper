import { describe, test, expect } from 'vitest'
import { validator } from '../lib'
import examples from './examples'

const expressionsValidator = validator()

expect.extend({
  toBeValid (received, validate = expressionsValidator) {
    return {
      pass: validate(received),
      message: () => JSON.stringify(validate.errors, null, 2)
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
