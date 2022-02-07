//
//  Dictionary.swift
//  
//
//  Created by Yury Korolev on 15.10.2021.
//

import Foundation

public extension Dictionary where Key == String, Value == Any {
  mutating func mergeWithSSHConfigRules(_ dict: Dictionary) {
    
    for (k, v) in dict {
      let plural = Validators.pluralDirectives.contains(k)
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
