import schemas, { BaseURI } from '../schemas'
import { Explorer } from './explorer'

export const explorer = new Explorer(schemas, BaseURI)
export { schemas }
export { default as examples } from '../examples'
export { default as validate } from './validate'
