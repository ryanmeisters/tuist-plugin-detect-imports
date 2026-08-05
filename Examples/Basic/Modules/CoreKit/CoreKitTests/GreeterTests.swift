import XCTest

@testable import CoreKit

final class GreeterTests: XCTestCase {
  func testGreet() {
    XCTAssertEqual(Greeter().greet("Tuist"), "Hello, Tuist!")
  }
}
