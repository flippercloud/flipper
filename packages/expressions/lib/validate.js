import Ajv from 'ajv'
import addFormats from 'ajv-formats'
import schemas, { BaseURI } from '../schemas'

export function useValidator(schemas = []) {
  const ajv = new Ajv({
    schemas,
    useDefaults: true,
    allErrors: true,
    strict: true
  })
  addFormats(ajv)
  return ajv
}

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

export const validator = useValidator(schemas)

export default (input, validate = validator.getSchema(BaseURI)) => {
  const data = coerceArgsToArray(input)
  const valid = validate(data)
  const errors = validate.errors
  return { valid, errors, data }
}
