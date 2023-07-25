import { v4 as uuidv4 } from 'uuid'
import { Schema } from './schemas'

export class Expression {
  static build (expression, attrs = {}) {
    if (expression instanceof Function || expression instanceof Constant) {
      return expression.clone(attrs)
    }

    if (['number', 'string', 'boolean'].includes(typeof expression) || expression === null) {
      return new Constant({ value: expression, ...attrs })
    } else if (typeof expression === 'object') {
      if (Object.keys(expression).length !== 1) {
        throw new TypeError(`Invalid expression: ${JSON.stringify(expression)}`)
      }
      const name = Object.keys(expression)[0]
      return new Function({ name, args: expression[name] })
    } else {
      throw new TypeError(`Invalid expression: ${JSON.stringify(expression)}`)
    }
  }

  constructor ({ id = uuidv4(), parent = undefined }) {
    this.id = id
    this.parent = parent
  }

  clone (attrs = {}) {
    return new this.constructor(Object.assign({}, this, attrs))
  }

  matches (schema) {
    return this.validate(schema).valid
  }

  add (expression) {
    if (this.schema.type !== 'array' || this.schema.maxItems) {
      return Expression.build({ All: [this, expression] })
    } else {
      return this.clone({ args: [...this.args, expression] })
    }
  }

  get parents () {
    return this.parent ? [this.parent, ...this.parent.parents] : []
  }

  get depth () {
    return this.parents.length
  }
}

// Public: A function like "All", "Any", "Equal", "Duration", etc.
export class Function extends Expression {
  constructor ({ name, args, ...attrs }) {
    super(attrs)

    this.name = name
    this.schema = Schema.resolve(`${name}.schema.json`)
    this.args = toArray(args).map((arg, i) => Expression.build(arg, {
      schema: this.schema.arrayItem(i),
      parent: this
    }))
  }

  get value () {
    return { [this.name]: this.args.map(arg => arg.value) }
  }

  validate (schema = this.schema) {
    return schema.validate(this.args.map(arg => arg.value))
  }
}

// Public: A constant value like a "string", number (1, 3.5), or boolean (true, false).
export class Constant extends Expression {
  constructor ({ value, schema = Schema.resolve('#'), ...attrs }) {
    super(attrs)
    this.value = value
    this.schema = schema
  }

  get args () {
    return [this.value]
  }

  validate (schema = this.schema) {
    return schema.validate(this.value)
  }
}

function toArray (arg) {
  if (Array.isArray(arg)) return arg
  if (arg === null) return []
  return [arg]
}
