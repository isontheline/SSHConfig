import Foundation

final class Lexer {

  private struct State  {
    let fn: (() -> State)?
  }

  private var _inputIdx = 0
  private var _input = [Character]()
  private var _buffer = [Character]()
  private var _pos = Position(line: 1, col: 1)
  private var _endBufferPos = Position(line: 1, col: 1)
  private var _state: State? = nil
  
  private var _emittedTokens = [Token]()
  
  init(input: String) {
    _input = Array(input)
    _state = State(fn: _lexVoid)
  }
  
  private func _lexComment(previosState: State) -> State {
    State { [self] in
      var growingChars = [Character]()
      
      var next = _peek()
      while let n = next, !n.isNewline {
        growingChars.append(n)
        _ = _next()
        next = _peek()
      }
      
      _emit(tokenType: .comment, withValue: growingChars)
      _skip()
      
      return previosState
    }
  }
  
  private func _lexVoid() -> State {
    while true {
      guard let next = _peek()
      else {
        _ = _next()
        break
      }
      switch next {
      case "#":
        _skip()
        return _lexComment(previosState: State(fn: _lexVoid))
      case "\r\n":
        fallthrough
      case "\n":
        _emit(tokenType: .emptyLine)
        _skip()
        continue
      default: break
      }

      if next.isWhitespace {
        _skip()
      }
      
      if next.isSSHKeyStartChar {
        return State(fn: _lexKey)
      }
      
    }

    _emit(tokenType: .eof)
    return State(fn: nil)
  }

  private func _lexKey() -> State {
    State { [self] in
      var growingChars = [Character]()
      
      var ch = _peek()
      while let c = ch, c.isSSHKeyChar {
        if c.isWhitespace || c == "=" {
          _emit(tokenType: .key, withValue: growingChars)
          _skip()
          return State(fn: _lexEquals)
        }
        
        growingChars.append(c)
        _ = _next()
        ch = _peek()
      }
      _emit(tokenType: .key, withValue: growingChars)
      return State(fn: _lexEquals)
    }
  }
  
  private func _lexEquals() -> State {
    while let next = _peek() {
      if next == "=" {
        _emit(tokenType: .equals)
        _skip()
        return State(fn: _lexRSpace)
      }
      
      if next.isWhitespace == false {
        break
      }
      
      _skip()
    }
    
    return State(fn: _lexRValue)
  }
  
  private func _lexRValue() -> State {
    var growingChars = [Character]()
    while true {
      guard let next = _peek()
      else {
        _ = _next()
        break
      }
      
      switch next {
      case "\r\n":
        fallthrough
      case "\n":
        _emit(tokenType: .string, withValue: growingChars)
        _skip()
        return State(fn: _lexVoid)
      case "#":
        _emit(tokenType: .string, withValue: growingChars)
        _skip()
        return _lexComment(previosState: State(fn: _lexVoid))
      case _:
        break
      }
      
      growingChars.append(next)
      _ = _next()
    }
    
    
    _emit(tokenType: .eof)
    return State(fn: nil)
  }
  
  private func _lexRSpace() -> State {
    while let next = _peek(), next.isWhitespace {
      _skip()
    }
    
    return State(fn: _lexRValue)
  }
  
}

// MARK: - Tools

extension Lexer {
  
  private func _peek() -> Character? {
    guard _inputIdx < _input.count
    else {
      return nil
    }

    return _input[_inputIdx]
  }

  private func _read() -> Character? {
    let ch = _peek()
    if ch == "\n" {
      _endBufferPos.line += 1
      _endBufferPos.col = 1
    } else {
      _endBufferPos.col += 1
    }

    _inputIdx += 1
    return ch
  }

  private func _next() -> Character? {
    let ch = _read()

    if let ch = ch {
      _buffer.append(ch)
    }

    return ch
  }

  private func _ignore() {
    _buffer = []
    _pos = _endBufferPos
  }

  private func _skip() {
    _ = _next()
    _ignore()
  }

  private func _emit(tokenType: TokenType) {
    _emit(tokenType: tokenType, withValue: _buffer)
  }

  private func _emit(tokenType: TokenType, withValue value: [Character]) {
    let token = Token(
      position: _pos,
      type: tokenType,
      value: String(value)
    )

    _emittedTokens.append(token)
    _ignore()
  }
  
  public func tokens() -> [Token] {
    _emittedTokens.removeAll()
    while let next = _state?.fn?() {
      _state = next
      if !_emittedTokens.isEmpty {
        return _emittedTokens
      }
    }
    _state = nil
    
    return _emittedTokens
  }
}


fileprivate extension Character {
  var isSSHKeyStartChar: Bool {
    !(isWhitespace || self == "\r" || self == "\n")
  }
  
  var isSSHKeyChar: Bool {
    !(self == "\r" || self == "\n" || self == "=")
  }
}
