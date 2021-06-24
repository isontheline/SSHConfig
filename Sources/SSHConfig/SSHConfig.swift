struct SSHConfig {
  
  enum Err: Error {
    case emptyPattern
    case unexpected(token: Token)
    case expectedToken
    case matchIsUnsupported
    case mustBeYesOrNo(key: String, value: String)
    case mustBeUInt(key: String, value: String)
  }
  
  var text = "Hello, World!"

  func bla() {
    
    print(Lexer(input: "").tokens())

  }

}
