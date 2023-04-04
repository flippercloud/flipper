import { v4 as uuidv4 } from 'uuid'
import { Constant } from './constant'
import explorer from './explorer'

// Simple model to transform this: `{ All: [{ Boolean: [true] }]`
// into this: `{ id: uuidv4(), name: 'All', args: [{ id: uuidv4(), name: 'Boolean', args: [true] }] }`
export class Expression {
  static build (expression) {
    if (expression instanceof Expression || expression instanceof Constant) {
      return expression
    }

    if (typeof expression === 'object') {
      const name = Object.keys(expression)[0]
      const args = expression[name].map(Expression.build)
      return new Expression({ name, args })
    } else {
      return new Constant(expression)
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

  get schema () {
    return explorer.functions[this.name]
  }
}
