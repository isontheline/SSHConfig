import Foundation

struct Pattern {
  let str: String
  let regexp: String
  let not: Bool // true if this is negative match
  
  init(str: String) throws {
    if str.isEmpty {
      throw SSHConfig.Err.emptyPattern
    }
    
    var chars = Array(str)
    
    var negated = false
    if chars[0] == "!" {
      negated = true
      chars.removeFirst()
    }
    
    var buffer = [Character]("^")
    let specialChars = [Character]("\\.+()|[]{}^$")

    for ch in chars {
      switch ch {
      case "*":
        buffer.append(contentsOf: ".*") // or it should be ".+" here?
      case "?":
        buffer.append(contentsOf: ".?")
      default:
        if specialChars.contains(ch) {
          buffer.append("\\")
        }
        buffer.append(ch)
      }
    }
    buffer.append("$")
    // TODO: validatate regexp
    
    self.regexp = String(buffer)
    self.str = str
    self.not = negated
  }
  
  static func matchAll() -> Pattern {
    try! Pattern(str: "*")
  }
}

extension Sequence where Element == Pattern {
  func matches(alias: String) -> Bool {
    var found = false
    for pattern in self where alias.range(of: pattern.regexp, options: [.regularExpression]) != nil {
      if pattern.not {
        return false
      }
      found = true
    }
    return found
  }
}
