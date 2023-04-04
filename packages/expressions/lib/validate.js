import Ajv from 'ajv'
import addFormats from 'ajv-formats'
import schemas, { BaseURI } from '../schemas'

const ajv = new Ajv({
  schemas: Object.values(schemas),
  useDefaults: true,
  allErrors: true,
  strict: true
})
addFormats(ajv)
const validator = ajv.getSchema(BaseURI)

function coerceArgsToArray (object) {
  if (object && typeof object === 'object') {
    return Object.fromEntries(Object.entries(object).map(([key, value]) => {
      if (value === null) {
        value = []
      } else if (!Array.isArray(value)) {
        value = [value]
      }

      return [key, value.map(coerceArgsToArray)]
    }))
  } else {
    return object
  }
}

export default (input) => {
  const result = coerceArgsToArray(input)
  const valid = validator(result)
  const errors = validator.errors
  return { valid, errors, result }
}
