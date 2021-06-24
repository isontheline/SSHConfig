import Foundation

class Config {
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
      }
    }
    return all
  }
  
  func resolve(alias: String) throws -> [String: Any] {
    let pluralDirectives = Set(
      [
        "CertificateFile",
        "IdentityFile",
        "DynamicForward",
        "RemoteForward",
        "SendEnv",
        "SetEnv"
      ].map { $0.lowercased() }
    )

    var resolved = [String: Any] ()
    for host in hosts where host.matches(alias: alias) {
      for node in host.nodes {
        if let kv = node as? KV {
          let lkey = kv.key.lowercased()
          
          if var v = resolved[lkey] as? [String] {
            v.append(kv.value)
            resolved[lkey] = v
          } else {
            if pluralDirectives.contains(lkey) {
              resolved[lkey] = [kv.value]
            } else {
              resolved[lkey] = kv.value
            }
          }
        }
      }
    }
    return resolved
  }
  
  func string() -> String {
    hosts.map{ $0.string() }.joined(separator: "")
  }
}
