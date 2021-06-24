//
//  File.swift
//  
//
//  Created by Yury Korolev on 24.06.2021.
//

import Foundation

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
  var files: [String: Config]
  var leadingSpace: Int
  var depth: UInt8
  var hasEquals: Bool
  
  func string() -> String {
    ""
  }
  
  static let maxRecurseDepth = 5
  
  init(directives: [String], hasEquals: Bool, position: Position, comment: String, system: Bool, depth: UInt8) throws {
    if depth > Include.maxRecurseDepth {
      throw SSHConfig.Err.depthExceeded
    }
    
    self.comment = comment
    self.directives = directives
    self.hasEquals = hasEquals
    self.position = position
    self.leadingSpace = position.col - 1
    self.depth = depth
    self.hasEquals = hasEquals
    
    // TODO:
    
    self.matches = []
    self.files = [:]
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
  
}
