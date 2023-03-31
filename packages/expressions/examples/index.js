import { basename } from 'path'

const modules = import.meta.glob('./*.json', { eager: true, import: 'default' })

export default Object.fromEntries(Object.entries(modules).map(([path, module]) => {
  return [basename(path, '.json'), module]
}))
