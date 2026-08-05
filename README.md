# tuist-plugin-detect-imports

[![CI](https://github.com/ryanmeisters/tuist-plugin-detect-imports/actions/workflows/ci.yml/badge.svg)](https://github.com/ryanmeisters/tuist-plugin-detect-imports/actions/workflows/ci.yml)

A [Tuist](https://tuist.dev) plugin that generates target dependencies from the `import` statements in your source files.

Your Swift files already declare what they depend on. This plugin reads those declarations at `tuist generate` time, so you never hand-maintain a dependencies array again. Add `import SomeModule` to a file and the dependency shows up in your project on the next generate.

## Installation

Register the plugin in your `Tuist.swift`:

```swift
import ProjectDescription

let config = Config(
  project: .tuist(
    plugins: [
      .git(
        url: "https://github.com/ryanmeisters/tuist-plugin-detect-imports.git",
        sha: "<commit-sha>"
      ),
    ]
  )
)
```

> [!NOTE]
> This plugin doesn't publish versioned releases. Pin the latest commit SHA from `main`, and update by bumping the `sha` value.

## Usage

The plugin exposes two helpers to your manifests:

- **`ImportsDetector.getImports(at:exclude:)`**: recursively scans a directory for `.swift` files and returns the set of imported module names.
- **`kAppleFrameworks`**: a list of Apple system frameworks, useful for deciding whether an import is an SDK framework or an external package.

A typical setup maps each detected import to the right kind of `TargetDependency`:

```swift
import DetectImportsPlugin
import Foundation
import ProjectDescription

// The modules that make up this project. Each module lives with its tests
// under a feature directory: Modules/FeatureA/FeatureA,
// Modules/FeatureA/FeatureATests, etc.
let projectModules: Set<String> = [
  "CoreKit",
  "CoreKitTests",
  "FeatureA",
  "FeatureATests",
]

let project = Project(
  name: "Example",
  targets: projectModules.sorted().map(makeModuleTarget)
)

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

// Map detected imports to Tuist dependencies:
// - another module in this project -> .target
// - an Apple framework            -> .sdk
// - anything else                 -> .external (SPM package)
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
```

With that in place, `Modules/FeatureA/FeatureA/FeatureA.swift` starting with:

```swift
import CoreKit
import Foundation
```

gives the `FeatureA` target a `.target(name: "CoreKit")` dependency and links `Foundation`. No manual bookkeeping.

> [!NOTE]
> Tuist caches manifest results and won't notice changes to your source files on its own. After adding an import for a dependency that isn't already linked (or a new module directory, if you autodetect modules), run `tuist clean manifests` to tell tuist to rerun the manifest files. You may want to make a habit of `tuist clean manifests && tuist generate`. (Don't run a full `tuist clean` or you will have to reinstall dependencies.)

## Examples

Two complete, working projects live in [`Examples/`](Examples). Each includes a small SwiftUI app target whose dependencies are detected the same way as the modules'.

- [`Examples/Basic`](Examples/Basic): the setup shown above, with modules listed by hand and dependencies detected from imports.
- [`Examples/Advanced`](Examples/Advanced): modules are autodetected by scanning the `Modules/` directory, so adding a module is just adding a directory. It also shows a realistic module convention: an interface module (`ModuleA`), its implementation (`ModuleAImpl`), shared mocks (`ModuleATestHelpers`), and tests. The app acts as the composition root: it is the only target that imports `ModuleAImpl`, injecting it into features that only know the interface. Everything is wired purely from import statements.

Try one out:

```sh
cd Examples/Basic
tuist generate
```

## How it works

`ImportsDetector` reads only the leading import block of each file and stops at the first non-import line, so scanning stays fast even in large projects. The parser:

- handles `@testable import` and `@preconcurrency import`
- normalizes targeted/submodule imports (`import os.log` → `os`)
- skips comments and preprocessor lines, so imports inside `#if canImport(...)` blocks are still detected

Since it stops at the first non-import line, imports need to appear at the top of the file (the standard style) to be detected.

Use the `exclude:` parameter to skip subdirectories by name, such as embedded test folders:

```swift
ImportsDetector.getImports(at: moduleURL, exclude: ["Tests"])
```

### Tips

- Some importable modules aren't linkable frameworks (e.g. `os`, `ObjectiveC`). Keep a small ignore set and filter those out before mapping to dependencies.
- `.external` dependencies must be declared in your Tuist package setup as usual. The plugin only detects the import; it doesn't fetch anything.

## Development

The detector is developed and tested with the Xcode project at the repo root:

- `ProjectDescriptionHelpers/`: the plugin source that Tuist compiles into your manifests
- `ImportsPlugin.xcodeproj`: a test harness that builds the same sources as the `ImportsPluginCore` framework, plus unit tests with fixtures

Run the tests:

```sh
xcodebuild test \
  -project ImportsPlugin.xcodeproj \
  -scheme ImportsPluginCore \
  -destination 'platform=macOS'
```

CI runs the tests and builds both example projects on every PR and push to `main`.

## Apps using this plugin

<table>
  <tr>
    <td align="center">
      <a href="https://apps.apple.com/app/id1519679458">
        <img src=".github/assets/fretpro.png" width="80" alt="FretPro app icon"><br>
        <b>FretPro</b>
      </a>
    </td>
    <td align="center">
      <a href="https://apps.apple.com/app/id1260842311">
        <img src=".github/assets/bird.png" width="80" alt="Bird app icon"><br>
        <b>Bird</b>
      </a>
    </td>
  </tr>
</table>

Using it in your app? Open a PR to add it here.

## Support Tuist

Tuist is the absolute best way to do mobile app development. If you're using it, please support them by using their [cloud services](https://tuist.dev) (you need these features!) and consider [sponsoring](https://github.com/sponsors/tuist).

## Credits

The Apple frameworks list is based on [@MarcoEidinger's appleframeworks](https://github.com/MarcoEidinger/appleframeworks).

## License

[MIT](LICENSE)
