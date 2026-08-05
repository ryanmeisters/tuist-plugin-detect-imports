import DetectImportsPlugin
import Foundation
import ProjectDescription

/// The modules that make up this project. Each module lives with its tests
/// under a feature directory: `Modules/FeatureA/FeatureA`,
/// `Modules/FeatureA/FeatureATests`, etc.
let projectModules: Set<String> = [
  "CoreKit",
  "CoreKitTests",
  "FeatureA",
  "FeatureATests",
]

let project = Project(
  name: "Basic",
  targets: [makeAppTarget()] + projectModules.sorted().map(makeModuleTarget)
)

func makeAppTarget() -> Target {
  let appURL = URL(filePath: FileManager.default.currentDirectoryPath)
    .appending(path: "App")
  let imports = ImportsDetector.getImports(at: appURL)

  return .target(
    name: "BasicApp",
    destinations: .iOS,
    product: .app,
    bundleId: "com.example.BasicApp",
    infoPlist: .default,
    sources: ["App/**"],
    dependencies: makeDependencies(imports: imports)
  )
}

func makeModuleTarget(name: String) -> Target {
  let isTests = name.hasSuffix("Tests")
  let feature = isTests ? String(name.dropLast("Tests".count)) : name
  let modulePath = "Modules/\(feature)/\(name)"

  let moduleURL = URL(filePath: FileManager.default.currentDirectoryPath)
    .appending(path: modulePath)
  let imports = ImportsDetector.getImports(at: moduleURL)

  return .target(
    name: name,
    destinations: .iOS,
    product: isTests ? .unitTests : .framework,
    bundleId: "com.example.\(name)",
    infoPlist: .default,
    sources: ["\(modulePath)/**"],
    dependencies: makeDependencies(imports: imports)
  )
}

/// Map detected imports to Tuist dependencies:
/// - another module in this project -> .target
/// - an Apple framework            -> .sdk
/// - anything else                 -> .external (SPM package)
func makeDependencies(imports: Set<String>) -> [TargetDependency] {
  imports.map { name in
    if projectModules.contains(name) {
      .target(name: name)
    } else if kAppleFrameworks.contains(name) {
      .sdk(name: name, type: .framework)
    } else {
      .external(name: name)
    }
  }
}
