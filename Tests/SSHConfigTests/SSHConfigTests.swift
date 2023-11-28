import XCTest
@testable import class SSHConfig.SSHConfig

final class SSHConfigTests: XCTestCase {
  func testAddHosts() throws {
    
    let config = SSHConfig()
    try config.add(alias: "office", cfg: [
      ("Hostname", "192.168.135.2"),
      ("user", "yury korolev"),
      ("port", 33),
      ("Compression", true)
    ],
    comment: " Blink Host"
    )
    
    try config.add(alias: "office2", cfg: [
      ("Hostname", "192.168.135.3"),
      ("user", "yury korolev"),
      ("identityfile", "id_rsa")
    ],
    comment: " Blink Host"
    )
    
    let str = config.string()
    
    XCTAssertEqual(str,
"""
Host office # Blink Host
  Hostname 192.168.135.2
  user yury korolev
  port 33
  Compression yes

Host office2 # Blink Host
  Hostname 192.168.135.3
  user yury korolev
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
  
  func testAdd() throws {
    let config = try! SSHConfig.parse(url: fixtureURL("include"))
    try config.add(alias: "192.168.135.2", cfg: [("RemoteForward", "8080:google.com:8080")])
    try config.add(alias: "192.168.135.2", cfg: [("LocalForward", "8080:localhost:8080")])
    try config.add(alias: "192.168.135.2", cfg: [("LocalForward", "8081:localhost:8081")])
    let resolved = try! config.resolve(alias: "192.168.135.2")
    print(resolved)
    let localForwards = resolved["localforward"] as! [String]
    XCTAssertEqual(localForwards.count, 2)
  }

  func testSpecialComments() throws {
    let config = try! SSHConfig.parse(url: fixtureURL("special_comments"))
    let resolved = try! config.resolve(alias: "ANY")

    XCTAssertEqual(resolved["_fontsize"] as! String, "20")
    XCTAssertEqual(resolved["_emptyvalue"] as! String, "")
  }
}