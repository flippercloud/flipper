// Public: A constant value like a "string", number (1, 3.5), or boolean (true, false).
//
// Implements the same interface as Expression
export class Constant {
  constructor (value) {
    this.value = value
  }

  get args () {
    return [this.value]
  }
}
