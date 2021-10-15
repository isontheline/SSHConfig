import XCTest
@testable import struct SSHConfig.Pattern
@testable import class SSHConfig.Host
@testable import class SSHConfig.Parser
@testable import class SSHConfig.SSHConfig


final class ParserTests: XCTestCase {
  func testBaseParse() throws {
    
    let config = try! SSHConfig.parse(url: fixtureURL("identities"))
    
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
  
  func testInclude() throws {
    let config = try! Parser(url: fixtureURL("include")).parse()
    let cfg = try! config.resolve(alias: "wap")
    
    debugPrint(cfg)
    print(config.string())
  }
  
  func testThrowsOnMatch() throws {
    let expectCatch = expectation(description: "catch")
    do {
      _ = try Parser(url: fixtureURL("match-directive")).parse()
    } catch SSHConfig.Err.matchIsUnsupported {
      expectCatch.fulfill()
    }
    wait(for: [expectCatch], timeout: 0)
  }
  
  func testDosLinesEndingDecode() throws {
    let config = try Parser(url: fixtureURL("dos-lines")).parse()
    
    XCTAssertEqual("root", try config.get(alias: "wap", key: "user"))
  }
  
  func testNoTrailingNewline() throws {
    let config = try Parser(url: fixtureURL("config-no-ending-newline")).parse()
    let port = try config.get(alias: "example", key: "Port")
    
    XCTAssertEqual(port, "4242")
  }
}
