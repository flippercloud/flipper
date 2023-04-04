import schemas, { BaseURI } from '../schemas'
import pointer from 'json-pointer'

export class Explorer {
  constructor (schemas, baseURI) {
    this.schemas = schemas
    this.baseURI = baseURI
  }

  // Get a ref from the schema
  get (ref, baseURI = this.baseURI) {
    const uri = new URL(ref, baseURI).href
    const [$id, path] = uri.split('#')
    const schema = this.schemas[$id]
    return this.proxy(path ? pointer.get(schema, path) : schema, uri)
  }

  // Returns a proxy to the schema that resolves $refs
  proxy (schema, uri) {
    const self = this
    return new Proxy(schema, {
      get (target, property, receiver) {
        const value = target[property]

        if (value !== null && typeof value === 'object') {
          // Schema returns an object for this property, proxy it as well
          return new Proxy(value, this)
        } else if (value !== undefined) {
          // Schema returns a value for this property, return it
          return value
        } else if (target.$ref) {
          // Schema includes a ref, so delegate to it
          return self.get(target.$ref, uri)[property]
        }
      }
    })
  }

  // Returns a list of the functions defined in the schema
  get functions () {
    return this.get('#/definitions/function/properties')
  }
}

export default new Explorer(schemas, BaseURI)
