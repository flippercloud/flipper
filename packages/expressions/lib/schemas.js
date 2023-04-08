import Ajv from 'ajv'
import addFormats from 'ajv-formats'

const modules = import.meta.glob('../schemas/*.json', { eager: true, import: 'default' })
export const schemas = Object.values(modules)
export const BaseURI = modules['../schemas/schema.json'].$id

class Schema {
  constructor (schemas, baseURI) {
    this.baseURI = baseURI

    this.ajv = new Ajv({
      schemas,
      useDefaults: true,
      allErrors: true,
      strict: true
    })
    addFormats(this.ajv)
  }

  get (ref, baseURI = this.baseURI) {
    return this.ajv.getSchema(new URL(ref, baseURI).href)
  }

  validate (data, validator = this.get('#')) {
    const valid = validator(data, schema)
    const errors = validator.errors
    return { valid, errors }
  }
}

export const schema = new Schema(schemas, BaseURI)
