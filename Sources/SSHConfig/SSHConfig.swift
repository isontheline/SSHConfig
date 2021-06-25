import Foundation

class SSHConfig {
  enum Err: Error {
    case emptyPattern
    case unexpected(token: Token)
    case expectedToken
    case matchIsUnsupported
    case mustBeYesOrNo(key: String, value: String)
    case mustBeUInt(key: String, value: String)
    case includeDepthExceeded
  }
  
  var hosts = [Host(patterns: [.matchAll()], implicit: true)]
  var depth = 0
  var position = Position(line: 1, col: 1)
  
  func get(alias: String, key: String) throws -> String {
    
    let lowerKey = key.lowercased()
    for host in hosts where host.matches(alias: alias) {
      for node in host.nodes {
        if let kv = node as? KV {
          let lkey = kv.key.lowercased()
          if lkey == "matches" {
            throw SSHConfig.Err.matchIsUnsupported
          }
          
          if lkey == lowerKey {
            return kv.value
          }
        }
        else if let inc = node as? Include {
          let v = try inc.get(alias:alias, key: key)
          if !v.isEmpty {
            return v
          }
        }
      }
    }
    return ""
  }
  
  func getAll(alias: String, key: String) throws -> [String] {
    let lowerKey = key.lowercased()
    var all = [String]()
    
    for host in hosts where host.matches(alias: alias) {
      for node in host.nodes {
        if let kv = node as? KV {
          let lkey = kv.key.lowercased()
          if lkey == "matches" {
            throw SSHConfig.Err.matchIsUnsupported
          }
          
          if lkey == lowerKey {
            all.append(kv.value)
          }
        }
        else if let inc = node as? Include {
          let v = try inc.getAll(alias:alias, key: key)
          all.append(contentsOf: v)
        }
      }
    }
    return all
  }
  
  func resolve(alias: String) throws -> [String: Any] {
    let validators = Validators()

    var resolved = [String: Any] ()
    for host in hosts where host.matches(alias: alias) {
      for node in host.nodes {
        if let kv = node as? KV {
          let lkey = kv.key.lowercased()
          
          if var v = resolved[lkey] as? [String] {
            v.append(kv.value)
            resolved[lkey] = v
          } else {
            if validators.pluralDirectives.contains(lkey) {
              resolved[lkey] = [kv.value]
            } else {
              resolved[lkey] = kv.value
            }
          }
        }
        else if let inc = node as? Include {
          let res = try inc.resolve(alias: alias)
          resolved.addValues(from: res)
        }
      }
    }
    return resolved
  }
  
  func string() -> String {
    hosts.map{ $0.string() }.joined(separator: "")
  }
}
