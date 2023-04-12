import { v4 as uuidv4 } from 'uuid'
import { Constant } from './constant'
import { Schema } from './schemas'

function toArray (arg) {
  if (Array.isArray(arg)) {
    return arg
  } else if (arg === null) {
    return []
  } else {
    return [arg]
  }
}

// Simple model to transform this: `{ All: [{ Boolean: [true] }]`
// into this: `{ id: uuidv4(), name: 'All', args: [{ id: uuidv4(), name: 'Boolean', args: [true] }] }`
export class Expression {
  static build (expression, schema = undefined) {
    if (expression instanceof Expression || expression instanceof Constant) {
      return expression
    }

    if (typeof expression === 'object') {
      if (Object.keys(expression).length !== 1) {
        throw new TypeError(`Invalid expression: ${JSON.stringify(expression)}`)
      }
      const name = Object.keys(expression)[0]
      return new Expression({ name, args: expression[name] })
    } else if (['number', 'string', 'boolean'].includes(typeof expression)) {
      return new Constant(expression, { schema })
    } else {
      throw new TypeError(`Invalid expression: ${JSON.stringify(expression)}`)
    }
  }

  constructor ({ name, args, id = uuidv4() }) {
    this.id = id
    this.name = name
    this.schema = Schema.resolve(`${name}.schema.json`)
    this.args = toArray(args).map((arg, i) => Expression.build(arg, this.schema.arrayItem(i)))
  }

  clone ({ id = this.id, name = this.name, args = this.args } = {}) {
    return new Expression({ id, name, args })
  }

  get value () {
    return { [this.name]: this.args.map(arg => arg.value) }
  }

  validate (schema = this.schema) {
    return schema.validate(this.args.map(arg => arg.value))
  }

  matches (schema) {
    return this.validate(schema).valid
  }
}
