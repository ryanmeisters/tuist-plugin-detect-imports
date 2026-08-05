import DetectImportsPlugin
import Foundation
import ProjectDescription

// Unlike the Basic example, modules are not listed by hand. Any directory
// two levels deep under Modules/ becomes a target, so adding a module is
// just adding a directory:
//
//   Modules/
//     ModuleA/
//       ModuleA/             interface (protocols, models)
//       ModuleAImpl/         implementation, only the app links it
//       ModuleATestHelpers/  mocks, shared by test targets
//       ModuleATests/
//     FeatureA/
//       FeatureA/
//       FeatureATests/

let modules = detectModules()
let moduleNames = Set(modules.map(\.name))

let project = Project(
  name: "Advanced",
  targets: [makeAppTarget()] + modules
    .sorted { $0.name < $1.name }
    .map(makeModuleTarget)
)

func makeAppTarget() -> Target {
  let appURL = URL(filePath: FileManager.default.currentDirectoryPath)
    .appending(path: "App")
  let imports = ImportsDetector.getImports(at: appURL)

  return .target(
    name: "AdvancedApp",
    destinations: .iOS,
    product: .app,
    bundleId: "com.example.AdvancedApp",
    infoPlist: .default,
    sources: ["App/**"],
    dependencies: makeDependencies(imports: imports)
  )
}

struct Module {
  let name: String
  let path: String
}

/// Discover modules by scanning two directory levels under `Modules/`.
func detectModules() -> [Module] {
  let root = URL(filePath: FileManager.default.currentDirectoryPath)
    .appending(path: "Modules")

  func subdirectories(of url: URL) -> [URL] {
    let contents = (try? FileManager.default.contentsOfDirectory(
      at: url,
      includingPropertiesForKeys: [.isDirectoryKey],
      options: .skipsHiddenFiles
    )) ?? []
    return contents.filter(\.hasDirectoryPath)
  }

  return subdirectories(of: root).flatMap(subdirectories(of:)).map { url in
    Module(
      name: url.lastPathComponent,
      path: "Modules/\(url.deletingLastPathComponent().lastPathComponent)/\(url.lastPathComponent)"
    )
  }
}

func makeModuleTarget(_ module: Module) -> Target {
  let moduleURL = URL(filePath: FileManager.default.currentDirectoryPath)
    .appending(path: module.path)
  let imports = ImportsDetector.getImports(at: moduleURL)

  return .target(
    name: module.name,
    destinations: .iOS,
    product: module.name.hasSuffix("Tests") ? .unitTests : .framework,
    bundleId: "com.example.\(module.name)",
    infoPlist: .default,
    sources: ["\(module.path)/**"],
    dependencies: makeDependencies(imports: imports)
  )
}

/// Map detected imports to Tuist dependencies:
/// - another module in this project -> .target
/// - an Apple framework            -> .sdk
/// - anything else                 -> .external (SPM package)
func makeDependencies(imports: Set<String>) -> [TargetDependency] {
  imports.map { name in
    if moduleNames.contains(name) {
      .target(name: name)
    } else if kAppleFrameworks.contains(name) {
      .sdk(name: name, type: .framework)
    } else {
      .external(name: name)
    }
  }
}
