import Foundation

fileprivate extension Character {
  var isSSHKeyStartChar: Bool {
    !(isWhitespace || self == "\r" || self == "\n")
  }
  
  var isSSHKeyChar: Bool {
    !(self == "\r" || self == "\n" || self == "=")
  }
}

final class Lexer {

  private struct State  {
    let fn: (() -> State)?
  }

  private var _inputIdx = 0
  private var _input = [Character]()
  private var _buffer = [Character]()
  private var _line = 1
  private var _col = 1
  private var _endBufferLine = 1
  private var _endBufferCol = 1
  private var _state: State? = nil
  
  private var _emittedTokens = [Token]()
  
  init(input: String) {
    _input = Array(input)
    _state = State(fn: _lexVoid)
  }
  
  private func _lexComment(previosState: State) -> State {
    State { [self] in
      var growingString = ""
      
      var next = _peek()
      while let n = next, n != "\n" {
        if n == "\r" && _follow("\r\n") {
          break
        }
        
        growingString += String(n)
        next = _next()
      }
      
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
      case "\r", "\n":
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
      var growingString = ""
      
      var ch = _peek()
      while let c = ch, c.isSSHKeyChar {
        if c.isWhitespace || c == "=" {
          _emitWithValue(tokenType: .key, value: growingString)
          _skip()
          return State(fn: _lexEquals)
        }
        
        growingString += String(c)
        _ = _next()
        ch = _peek()
      }
      _emitWithValue(tokenType: .key, value: growingString)
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
    var growingString = ""
    while true {
      guard let next = _peek()
      else {
        _ = _next()
        break
      }
      
      switch next {
      case "\r":
        if _follow("\r\n") {
          _emitWithValue(tokenType: .string, value: growingString)
          _skip()
          return State(fn: _lexVoid)
        }
      case "\n":
        _emitWithValue(tokenType: .string, value: growingString)
        _skip()
        return State(fn: _lexVoid)
      case "#":
        _emitWithValue(tokenType: .string, value: growingString)
        _skip()
        return _lexComment(previosState: State(fn: _lexVoid))
      case nil:
        _ = _next()
      case _:
        break
      }
      
      growingString += String(next)
      _ = _next()
    }
    
    
    _emit(tokenType: .eof)
    return State(fn: nil)
  }
  
  private func _lexRSpace() -> State {
    while let next = _peek() {
      if !next.isWhitespace {
        break
      }
      
      _skip()
    }
    
    return State(fn: _lexRValue)
  }
  
  private func _follow(_ next: String) -> Bool {
    var idx = _inputIdx
    
    for expectedChar in Array(next) {
      if idx >= _input.count {
        return false
      }
      
      let ch = _input[idx]
      idx += 1
      if ch != expectedChar {
        return false
      }
    }
    return true
  }

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
      _endBufferLine += 1
      _endBufferCol = 1
    } else {
      _endBufferCol += 1
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
    _line = _endBufferLine
    _col = _endBufferCol
  }

  private func _skip() {
    _ = _next()
    _ignore()
  }

  private func _emit(tokenType: TokenType) {
    _emitWithValue(tokenType: tokenType, value: String(_buffer))
  }

  private func _emitWithValue(tokenType: TokenType, value: String) {
    let token = Token(
      position: Position(line: _line, col: _col),
      type: tokenType,
      value: value
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
