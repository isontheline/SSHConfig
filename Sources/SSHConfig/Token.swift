import Foundation

enum TokenType {
  case error, eof, emptyLine, comment, key, equals, string
}

struct Position {
  let line: Int
  let col: Int

  func invalid() -> Bool {
    line <= 0 || col <= 0
  }

  func string() -> String {
    "\(line), \(col)"
  }
}

struct Token {
  let position: Position
  let type: TokenType
  let value: String

  func string() -> String {
    switch type {
    case .eof: return "EOF"
    default: return value
    }
  }
}
