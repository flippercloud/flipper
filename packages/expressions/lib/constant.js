import { v4 as uuidv4 } from 'uuid'
import { Schema } from './schemas'

// Public: A constant value like a "string", number (1, 3.5), or boolean (true, false).
//
// Implements the same interface as Expression
export class Constant {
  constructor (value, { id = uuidv4(), schema = Schema.resolve('#') } = {}) {
    this.value = value
    this.id = id
    this.schema = schema
  }

  clone (value, { id = this.id, schema = this.schema } = {}) {
    return new Constant(value, { id, schema })
  }

  get args () {
    return [this.value]
  }

  validate (schema = this.schema) {
    return schema.validate(this.value)
  }

  matches (schema = this.schema) {
    return schema.validate(this.value).valid
  }
}
