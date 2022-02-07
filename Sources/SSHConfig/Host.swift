import Foundation

class Host {
  var patterns = [Pattern]()
  var nodes = [Node]()
  var hasEquals = false
  var leadingSpace = 0
  var implicit = false
  var eolComment = ""
  
  init(patterns: [Pattern], implicit: Bool = false) {
    self.patterns = patterns
    self.implicit = implicit
  }
  
  func matches(alias: String) -> Bool {
    patterns.matches(alias: alias)
  }
  
  func removeValue(forKey key: String) {
    let lkey = key.lowercased()
    nodes.removeAll { n in
      if let kv = n as? KV {
        return lkey == kv.key.lowercased()
      }
      return false
    }
  }
  
  func set(_ value: String, forKey key: String) {
    let lkey = key.lowercased()
    if !Validators.pluralDirectives.contains(lkey) {
      for (i, n) in nodes.enumerated() {
        if var kv = n as? KV {
          if lkey == kv.key.lowercased() {
            kv.value = value
            nodes[i] = kv
            return
          }
        }
      }
    }
    
    let kv = KV(
      key: key,
      value: value,
      comment: "",
      hasEquals: false,
      leadingSpace: leadingSpace + 2,
      position: Position(line: 1, col: 1)
    )
    
    if nodes.isEmpty {
      nodes.append(kv)
      return
    }
    
    var lastNonEmpty = -1
    for n in nodes {
      if let _ = n as? Empty {
        continue
      }
      lastNonEmpty += 1
    }
    
    nodes.insert(kv, at: lastNonEmpty + 1)
  }
  
  func string() -> String {
    var result = ""
    
    if !implicit {
      result += String(repeating: " ", count: leadingSpace)
      result += "Host"
      if hasEquals {
        result += " = "
      } else {
        result += " "
      }
      result += patterns.map(\.str).joined(separator: " ")
      
      if !eolComment.isEmpty {
        result += " #\(eolComment)"
      }
      result += "\n"
    }
    
    for n in nodes {
      result += n.string()
      result += "\n"
    }
    
    return result
  }
}
