const modules = import.meta.glob('./*.json', { eager: true, import: 'default' })

export default Object.fromEntries(Object.entries(modules).map(([path, module]) => {
  const name = path.split('/').pop().split('.').shift()
  return [name, module]
}))
