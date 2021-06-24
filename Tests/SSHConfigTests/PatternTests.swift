import XCTest
@testable import struct SSHConfig.Pattern
@testable import class SSHConfig.Host

final class PatternTests: XCTestCase {
  func testMatches() throws {

    let matchTests = [
      (["*"], "any.test", true),
      (["a", "b", "*", "c"], "any.test", true),
      (["a", "b", "c"], "any.test", false),
      (["any.test"], "any1test", false),
      (["192.168.0.?"], "192.168.0.1", true),
      (["192.168.0.?"], "192.168.0.10", false),
      (["*.co.uk"], "bbc.co.uk", true),
      (["*.co.uk"], "subdomain.bbc.co.uk", true),
      (["*.*.co.uk"], "bbc.co.uk", false),
      (["*.*.co.uk"], "subdomain.bbc.co.uk", true),
      (["*.example.com", "!*.dialup.example.com", "foo.dialup.example.com"], "foo.dialup.example.com", false),
      (["test.*", "!test.host"], "test.host", false)
    ]
    
    for tt in matchTests {
      var patterns = [Pattern]()
      for i in tt.0 {
        let pat = try Pattern(str: i)
        patterns.append(pat)
      }
      
      let host = Host(patterns: patterns)
      let got = host.matches(alias: tt.1)
      
      XCTAssertEqual(got, tt.2, "Failed with: \(tt)")
    }
  }
}
