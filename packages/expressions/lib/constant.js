import { v4 as uuidv4 } from 'uuid'
import { Schema } from './schemas'

// Public: A constant value like a "string", number (1, 3.5), or boolean (true, false).
//
// Implements the same interface as Expression
export class Constant {
  constructor (value, id = uuidv4()) {
    this.value = value
    this.id = id
  }

  clone (value, id = this.id) {
    return new Constant(value, id)
  }

  get args () {
    return [this.value]
  }

  get schema () {
    return Schema.resolve('#/definitions/constant')
  }

  validate (schema = this.schema) {
    return schema.validate(this.value)
  }

  matches (schema = this.schema) {
    return schema.validate(this.value).valid
  }
}
