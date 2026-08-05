import Foundation
import ModuleA

public struct FeatureA {
  let client: ModuleAClient

  public init(client: ModuleAClient) {
    self.client = client
  }

  public func summary() -> String {
    "Value: \(client.fetchValue())"
  }
}
