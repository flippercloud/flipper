import { schema } from './schemas'

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
    return schema.resolve('#/definitions/constant')
  }

  validate (schema = this.schema) {
    return schema.validate(this.value)
  }

  matches (schema = this.schema) {
    return schema.validate(this.value).valid
  }
}
