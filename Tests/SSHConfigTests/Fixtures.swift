//
//  File.swift
//  
//
//  Created by Yury Korolev on 15.10.2021.
//

import Foundation

func fixtureURL(_ name: String) -> URL {
  Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "testdata")!
}

