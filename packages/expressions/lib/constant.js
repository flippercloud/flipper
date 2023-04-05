import { useValidator } from './validate'

// Public: A constant value like a "string", number (1, 3.5), or boolean (true, false).
//
// Implements the same interface as Expression
export class Constant {
  constructor (value) {
    this.value = value
  }

  get args () {
    return [this.value]
  }

  get schema () {
    return { type: typeof this.value }
  }

  validate(schema = this.schema) {
    const validator = useValidator()
    const data = this.value
    const valid = validator.validate(schema, data)
    const errors = validator.errors
    return { valid, errors, data }
  }

  matches(schema) {
    const { valid } = this.validate(schema)
    return valid
  }
}
