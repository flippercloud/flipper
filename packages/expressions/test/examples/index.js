import { globSync } from 'glob'
import { readFileSync } from 'fs'
import { basename } from 'path'

const pattern = new URL('./*.json', import.meta.url).pathname

export default Object.fromEntries(globSync(pattern).map(file => {
  const contents = JSON.parse(readFileSync(file, 'utf8'))
  return [basename(file, '.json'), contents]
}))
