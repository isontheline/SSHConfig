import Foundation

class Parser {
  
  static var homeURL = URL(string: "~")!
  static var systemURL = URL(string: "/etc/ssh")
  
  private struct State  {
    let fn: (() throws -> State)?
  }
  
  private let _config = SSHConfig()
  private var _tokensBuffer = [Token]()
  private var _state: State? = nil
  private var _lexer: Lexer
  private var _depth: UInt8
  private var _system: Bool
  private let _url: URL
  
  init(url: URL, input: String, depth: UInt8 = 0, system: Bool = false) {
    _url = url
    _lexer = Lexer(input: input)
    _system = system
    _depth = depth
    _state = State(fn: _parseStart)
  }
  
  convenience init(url: URL, depth: UInt8 = 0, system: Bool = false) throws {
    let contents = try String(contentsOf: url)
    self.init(url: url, input: contents, depth: depth, system: system)
  }
  
  private func _parseStart() throws -> State {
    guard
      let tok = _peek()
    else {
      // end of stream, parsing is finished
      return State(fn: nil)
    }
    
    switch tok.type {
    case .comment, .emptyLine:
      return State(fn: _parseComment)
    case .key:
      return State(fn: _parseKV)
    case .eof:
      return State(fn: nil)
    default:
      throw SSHConfig.Err.unexpected(token: tok)
    }
  }
  
  private func _parseKV() throws -> State {
    guard
      let key = _getToken(),
      var val = _getToken()
    else {
      throw SSHConfig.Err.expectedToken
    }
    var hasEquals = false
    
    if case TokenType.equals = val.type {
      guard
        let v = _getToken()
      else {
        throw SSHConfig.Err.expectedToken
      }
      hasEquals = true
      val = v
    }
    
    var comment = ""
    var tok = _peek()
    if tok == nil {
      tok = Token(position: Position(line: 1, col: 1), type: .eof, value: "")
    }
    
    if case TokenType.comment = tok!.type, tok!.position.line == val.position.line {
      tok = _getToken()!
      comment = tok!.value
    }
    
    let value = key.value.lowercased()
    
    if value == "match" {
      throw SSHConfig.Err.matchIsUnsupported
    }
    
    if value == "host" {
      var patterns = [Pattern]()
      let strPatterns = val.value.split(separator: " ").map(String.init)
      for i in strPatterns where !i.isEmpty {
        let pattern = try Pattern(str: i)
        patterns.append(pattern)
      }
      
      let host = Host(patterns: patterns)
      host.eolComment = comment
      host.hasEquals = hasEquals
      
      _config.hosts.append(host)
      
      return State(fn: _parseStart)
    }
    
    let lastHost = _config.hosts.last
    if value == "include" {
      let directives = val.value.split(separator: " ").map(String.init)
      let inc = try Include(
        baseURL: _url,
        directives: directives,
        hasEquals: hasEquals,
        position: key.position,
        comment: comment,
        system: _system,
        depth: _depth + 1
      )
      
      lastHost?.nodes.append(inc)
      return State(fn: _parseStart)
    }
    
    let kv = KV(
      key: key.value,
      value: val.value,
      comment: comment,
      hasEquals: hasEquals,
      leadingSpace: key.position.col - 1,
      position: key.position
    )
    lastHost?.nodes.append(kv)
    
    return State(fn: _parseStart)
  }
  
  private func _parseComment() throws -> State {
    guard let comment = _getToken() else {
      throw SSHConfig.Err.emptyPattern
    }
    let lastHost = _config.hosts.last
    lastHost?.nodes.append(
      Empty(
        comment: comment.value,
        leadingSpace: comment.position.col - 2,
        position: comment.position
      )
    )
    
    return State(fn: _parseStart)
  }
  
  private func _peek() -> Token? {
    if let token = _tokensBuffer.first {
      return token
    }
    
    _tokensBuffer = _lexer.tokens()
    return _tokensBuffer.first
  }
  
  private func _getToken() -> Token? {
    if let token = _tokensBuffer.first {
      _tokensBuffer.removeFirst()
      return token
    }
    
    _tokensBuffer = _lexer.tokens()
    if let token = _tokensBuffer.first {
      _tokensBuffer.removeFirst()
      return token
    }
    return nil
  }
  
  func parse() throws -> SSHConfig {
    while let s = _state {
      _state = try s.fn?()
    }
    
    _state = nil
    
    return _config
  }
  
}
