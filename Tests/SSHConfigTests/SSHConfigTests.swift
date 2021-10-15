import XCTest
@testable import class SSHConfig.SSHConfig

final class SSHConfigTests: XCTestCase {
  func testAddHosts() throws {
    
    let config = SSHConfig()
    try config.add(alias: "office", cfg: [
      ("Hostname", "192.168.135.2"),
      ("user", "yury"),
      ("port", 33),
      ("Compression", true)
    ],
    comment: " Blink Host"
    )
    
    try config.add(alias: "office2", cfg: [
      ("Hostname", "192.168.135.3"),
      ("user", "yury"),
      ("identityfile", "id_rsa")
    ],
    comment: " Blink Host"
    )
    
    let str = config.string()
    
    XCTAssertEqual(str,
"""
Host office # Blink Host
  Hostname 192.168.135.2
  user yury
  port 33
  Compression yes

Host office2 # Blink Host
  Hostname 192.168.135.3
  user yury
  identityfile id_rsa


"""
    )
  }
  
  func testResolve() {
    let config = try! SSHConfig.parse(url: fixtureURL("include"))
    var resolved = try! config.resolve(alias: "10.0.0.1")
    XCTAssertEqual(resolved["port"] as! String, "23")
    
    resolved = try! config.resolve(alias: "wap")
    XCTAssertEqual(resolved["user"] as! String, "root")
    XCTAssertEqual(resolved["kexalgorithms"] as! String, "diffie-hellman-group1-sha1")
  }
}

