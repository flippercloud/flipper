import Ajv from 'ajv'
import addFormats from 'ajv-formats'
import * as schemas from './schemas'

export default function (options = { allErrors: true, verbose: true }) {
  const ajv = new Ajv({ schemas: Object.values(schemas) })
  addFormats(ajv)
  return ajv.getSchema(schemas.default.$id)
}
