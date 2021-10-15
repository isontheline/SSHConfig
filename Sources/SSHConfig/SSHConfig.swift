import Foundation

public class SSHConfig {
  public enum Err: Error {
    case emptyPattern
    case unexpected(token: Token)
    case expectedToken
    case matchIsUnsupported
    case mustBeYesOrNo(key: String, value: String)
    case mustBeUInt(key: String, value: String)
    case includeDepthExceeded
  }
  
  internal var hosts = [Host(patterns: [.matchAll()], implicit: true)]
  internal var depth = 0
  internal var position = Position(line: 1, col: 1)
  
  public init() {
    
  }
  
  public static func parse(url: URL) throws -> SSHConfig {
    try Parser(url: url).parse()
  }
  
  public func add(alias: String, cfg: [(String, Any)], comment: String = "") throws {
    let pattern = try Pattern(str: alias)
    let host = Host(patterns: [pattern])
    host.nodes.append(Empty(comment: "", leadingSpace: 2, position: position))
    
    host.eolComment = comment
    for (key, value) in cfg {
      if let v = value as? String {
        host.set(v, forKey: key)
      }
      else if let arr = value as? [String] {
        for v in arr {
          host.set(v, forKey: key)
        }
      }
      else if let bool = value as? Bool {
        host.set(bool ? "yes" : "no", forKey: key)
      }
      else if let uint = value as? UInt {
        host.set(String(uint), forKey: key)
      }
      else if let int = value as? Int {
        host.set(String(int), forKey: key)
      }
    }
    
    hosts.append(host)
  }
  
  public func get(alias: String, key: String) throws -> String {
    
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
  
  public func getAll(alias: String, key: String) throws -> [String] {
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
  
  public func resolve(alias: String) throws -> [String: Any] {
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
            } else if resolved[lkey] == nil {
              resolved[lkey] = kv.value
            }
          }
        }
        else if let inc = node as? Include {
          let res = try inc.resolve(alias: alias)
          resolved.mergeWithSSHConfigRules(res)
        }
      }
    }
    return resolved
  }
  
  public func string() -> String {
    hosts.map{ $0.string() }.joined(separator: "")
  }
}
