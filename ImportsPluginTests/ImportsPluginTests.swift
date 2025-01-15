//
//  ImportsPluginTests.swift
//  ImportsPluginTests
//
//  Created by Ryan Meisters on 4/24/24.
//

import XCTest
@testable import ImportsPluginCore

final class ImportsPluginTests: XCTestCase {
  func testNoExcludes() throws {
    let url = fixtureUrl(for: "ModuleWithEmbeddedTests")
    let imports = ImportsDetector.getImports(at: url)
    XCTAssertEqual(imports, [
        "ModuleA", "TestModuleA",
        "ModuleB", "TestModuleB",
        "ModuleC", "TestModuleC"
    ])
  }

  func testExcludeTests() throws {
    let url = fixtureUrl(for: "ModuleWithEmbeddedTests")
    let imports = ImportsDetector.getImports(at: url, exclude: ["Tests"])
    XCTAssertEqual(imports, ["ModuleA", "ModuleB", "ModuleC"])
  }
}

func fixtureUrl(for fixture: String) -> URL {
  fixturesDirectory().appendingPathComponent(fixture)
}

func fixturesDirectory(path: String = #file) -> URL {
  let url = URL(fileURLWithPath: path)
  let testsDir = url.deletingLastPathComponent()
  let res = testsDir.appendingPathComponent("Fixtures")
  return res
}
