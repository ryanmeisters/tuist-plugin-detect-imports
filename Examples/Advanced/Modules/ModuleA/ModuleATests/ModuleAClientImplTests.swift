import ModuleAImpl
import XCTest

final class ModuleAClientImplTests: XCTestCase {
  func testFetchValue() {
    XCTAssertEqual(ModuleAClientImpl().fetchValue(), 42)
  }
}
