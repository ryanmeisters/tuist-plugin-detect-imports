import ModuleA

public struct ModuleAClientMock: ModuleAClient {
  public var value: Int

  public init(value: Int) {
    self.value = value
  }

  public func fetchValue() -> Int {
    value
  }
}
