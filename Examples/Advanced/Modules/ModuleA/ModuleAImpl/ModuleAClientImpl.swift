import Foundation
import ModuleA

public struct ModuleAClientImpl: ModuleAClient {
  public init() {}

  public func fetchValue() -> Int {
    42
  }
}
