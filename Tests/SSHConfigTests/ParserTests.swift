import XCTest
@testable import struct SSHConfig.Pattern
@testable import class SSHConfig.Host
@testable import class SSHConfig.Parser

final class ParserTests: XCTestCase {
  func testMatches() throws {
    let identities = Bundle.module.url(forResource: "identities", withExtension: nil, subdirectory: "testdata")!
    let content = try! String(contentsOf: identities)
    let config = try! Parser(input: content).parse()
    
    
    XCTAssertEqual(config.hosts.count, 4)
    
    let files = try config.getAll(alias: "has2identity", key: "IdentityFile")
    
    XCTAssertEqual(["f1", "f2"], files)
    
    let cfg = try config.resolve(alias: "has2identity")
    XCTAssertEqual(cfg.count, 1)
    XCTAssertEqual(cfg["identityfile"] as! [String], ["f1", "f2"])
    
    config.hosts[1].set("yes", forKey: "Compression")
    config.hosts[1].set("no", forKey: "Compression")
    
    print(config.string())
  }
}
