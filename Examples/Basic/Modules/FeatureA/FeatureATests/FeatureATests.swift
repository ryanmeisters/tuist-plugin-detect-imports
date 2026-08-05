import FeatureA
import XCTest

final class FeatureATests: XCTestCase {
  func testWelcome() {
    XCTAssertEqual(FeatureA().welcome(), "Hello, FeatureA!")
  }
}
