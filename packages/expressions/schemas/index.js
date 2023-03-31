const modules = import.meta.glob('./*.json', { eager: true, import: 'default' })
const schemas = Object.fromEntries(Object.entries(modules).map(([path, module]) => {
  const name = path.split('/').pop().split('.').shift()
  return [name === 'schema' ? 'default' : name, module]
}))

export default schemas
