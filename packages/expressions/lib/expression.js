import { v4 as uuidv4 } from 'uuid'
import { Constant } from './constant'
import { schema } from './schemas'

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
  static build (expression) {
    if (expression instanceof Expression || expression instanceof Constant) {
      return expression
    }

    if (typeof expression === 'object') {
      if (Object.keys(expression).length !== 1) {
        throw new TypeError(`Invalid expression: ${JSON.stringify(expression)}`)
      }
      const name = Object.keys(expression)[0]
      const args = toArray(expression[name]).map(Expression.build)

      return new Expression({ name, args })
    } else if (['number', 'string', 'boolean'].includes(typeof expression)) {
      return new Constant(expression)
    } else {
      throw new TypeError(`Invalid expression: ${JSON.stringify(expression)}`)
    }
  }

  constructor ({ name, args, id = uuidv4() }) {
    Object.assign(this, { name, args, id })
  }

  clone ({ id = this.id, name = this.name, args = this.args } = {}) {
    return new Expression({ id, name, args: args.map(Expression.build) })
  }

  get value () {
    return { [this.name]: this.args.map(arg => arg.value) }
  }

  get validator () {
    return schema.get('#')
  }

  validate (validator = this.validator) {
    return schema.validate(this.value, validator)
  }

  matches (localSchema) {
    return this.validate(localSchema).valid
  }
}
