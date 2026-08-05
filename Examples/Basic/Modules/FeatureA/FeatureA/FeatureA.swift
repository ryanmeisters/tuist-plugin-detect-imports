import CoreKit
import Foundation

public struct FeatureA {
  public init() {}

  public func welcome() -> String {
    Greeter().greet("FeatureA")
  }
}
