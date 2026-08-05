import FeatureA
import ModuleATestHelpers
import XCTest

final class FeatureATests: XCTestCase {
  func testSummary() {
    let feature = FeatureA(client: ModuleAClientMock(value: 7))
    XCTAssertEqual(feature.summary(), "Value: 7")
  }
}
