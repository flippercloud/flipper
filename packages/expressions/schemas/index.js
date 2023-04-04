const modules = import.meta.glob('./*.json', { eager: true, import: 'default' })
const schemas = Object.fromEntries(Object.values(modules).map(module => {
  return [module.$id, module]
}))

export const BaseURI = modules['./schema.json'].$id
export default schemas
