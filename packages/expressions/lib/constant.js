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

  get validator () {
    return schema.get('#/definitions/constant')
  }

  validate (validator = this.validator) {
    return schema.validate(this.value, validator)
  }

  matches (localSchema) {
    return this.validate(localSchema).valid
  }
}
