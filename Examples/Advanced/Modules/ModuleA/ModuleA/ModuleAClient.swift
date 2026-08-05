import Foundation

/// The interface module: features depend on this protocol, never on the
/// implementation module directly.
public protocol ModuleAClient {
  func fetchValue() -> Int
}
