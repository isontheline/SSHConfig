//
//  File.swift
//  
//
//  Created by Yury Korolev on 24.06.2021.
//

import Foundation
import CloudKit

protocol Node {
  var position: Position { get }
  func string() -> String
}

struct Empty: Node {
  let comment: String
  let leadingSpace: Int
  let position: Position
  
  func string() -> String {
    if comment.isEmpty {
      return ""
    }
    
    return "\(String(repeating: " ", count: leadingSpace))#\(comment)"
  }
}


struct KV: Node {
  let key: String
  var value: String
  let comment: String
  let hasEquals: Bool
  let leadingSpace: Int
  let position: Position
  
  func string() -> String {
    if key.isEmpty {
      return ""
    }
    
    let equals = hasEquals ? " = " : " "
    
    var line = "\(String(repeating: " ", count: leadingSpace))\(key)\(equals)\(value)"
    if !comment.isEmpty {
      line += " #\(comment)"
    }
    
    return line
  }
}

struct Include: Node {
  var comment: String
  var directives: [String]
  var position: Position
  var matches: [String]
  var files: [String: SSHConfig]
  var leadingSpace: Int
  var depth: UInt8
  var hasEquals: Bool
  
  func string() -> String {
    let equals = hasEquals ? " = " : " "
    var line = "\(String(repeating: " ", count: leadingSpace))Include\(equals)\(directives.joined(separator: " "))"
    
    if !comment.isEmpty {
      line += " #\(comment)"
    }
    return line
  }
  
  static let maxRecurseDepth = 5
  
  init(baseURL: URL, directives: [String], hasEquals: Bool, position: Position, comment: String, system: Bool, depth: UInt8) throws {
    if depth > Include.maxRecurseDepth {
      throw SSHConfig.Err.includeDepthExceeded
    }
    
    self.comment = comment
    self.directives = directives
    self.hasEquals = hasEquals
    self.position = position
    self.leadingSpace = position.col - 1
    self.depth = depth
    self.hasEquals = hasEquals
    
    var matchesSet = Set<String>()
    for direcitive in directives {
      let path: String
      if direcitive.starts(with: "/") {
        // abs
        path = direcitive
      } else if system {
        path = "~/.ssh/" + direcitive
      } else {
        path = baseURL.deletingLastPathComponent().path + "/" + direcitive
      }
      
      let m = __glob(pattern: path)
      matchesSet.formUnion(m)
    }
    self.matches = Array(matchesSet).sorted()
    self.files = [:]
    
    for m in matches {
      let cfg = try Parser(url: URL(fileURLWithPath: m)).parse()
      files[m] = cfg
    }
  }
  
  func get(alias: String, key: String) throws -> String {
    for m in matches {
      if let cfg = files[m] {
        let v = try cfg.get(alias: alias, key: key)
        if !v.isEmpty {
          return v
        }
      }
    }
    return ""
  }
  
  func getAll(alias: String, key: String) throws -> [String] {
    var all: [String] = []
    for m in matches {
      if let cfg = files[m] {
        let v = try cfg.get(alias: alias, key: key)
        if !v.isEmpty {
          all.append(v)
        }
      }
    }
    return all
  }
  
  func resolve(alias: String) throws -> [String: Any] {
    var resolved = [String: Any]()
    
    for m in matches {
      if let cfg = files[m] {
        resolved.addValues(from: try cfg.resolve(alias: alias))
      }
    }
    
    return resolved
  }
  
}

fileprivate func __glob(pattern: String) -> [String] {
  var result = [String]()
  var g: glob_t = glob_t()
  glob(pattern, 0, nil, &g)
  defer {
    globfree(&g)
  }
  
  for i in 0..<g.gl_pathc {
    if let cString = g.gl_pathv[i] {
      let str = String(cString: cString)
      result.append(str)
    }
  }
  
  return result
}

extension Dictionary where Key == String, Value == Any {
  mutating func addValues(from dict: Dictionary) {
    let validators = Validators()
    
    for (k, v) in dict {
      let plural = validators.pluralDirectives.contains(k)
      if plural {
        if let currentValue = self[k] as? [String] {
          if let arr = v as? [String] {
            self[k] = currentValue + arr
          } else if let str = v as? String {
            self[k] = currentValue + [str]
          }
        } else {
          self[k] = v
        }
        
        continue
      }
      
      if let _ = self[k] {
        continue
      }
      
      self[k] = v
    }
  }
}
