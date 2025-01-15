//
//  ImportsDetector.swift
//  ImportsPluginCore
//
//  Created by Ryan Meisters on 4/24/24.
//

import Foundation

private extension String {
  var isSwift: Bool {
    return hasSuffix(".swift")
  }
}

public final class ImportsDetector {
  nonisolated(unsafe) private static let fileManager = FileManager.default

  public static func getImports(
    at url: URL,
    exclude: Set<String> = []
  ) -> Set<String> {
    var detected: Set<String> = []
    enumerateSwiftFiles(
      at: url,
      directoryFilter: { name, _ in !exclude.contains(name) }
    ) { name, path in
      detected = detected.union(imports(atPath: path.path))
    }
    return detected
  }

  // MARK: - File Parsing

  /// Parse imports in a swift file
  private static func imports(atPath path: String) -> Set<String> {
    guard let lineReader = LineReader(path: path) else {
      return []
    }

    var results: Set<String> = []
    for line in lineReader {
      let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

      // Ignore initial comments and empty lines
      if cleanLine.hasPrefix("/") || cleanLine.count == 0 {
        continue
      }

      // Stop searching at first non-import line
      if !cleanLine.hasPrefix("import"), !cleanLine.hasPrefix("@testable import") {
        return results
      }

      if let imported = cleanLine.components(separatedBy: " ").last {
        results.insert(imported)
      }
    }

    return results
  }
}


private func enumerateSwiftFiles(
  at url: URL,
  directoryFilter: (_ name: String, _ url: URL) -> Bool,
  execute: (_ name: String, _ path: URL) throws -> Void
) {
  let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .nameKey]
  let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsSubdirectoryDescendants]

  do {
    let enumerator = FileManager.default.enumerator(
      at: url,
      includingPropertiesForKeys: resourceKeys,
      options: options,
      errorHandler: handleEnumeratorError
    )!

    for case let url as URL in enumerator {
      let resourceValues = try url.resourceValues(forKeys: Set(resourceKeys))

      guard let isDir = resourceValues.isDirectory, let name = resourceValues.name else {
        continue
      }

      if isDir, directoryFilter(name, url) {
        enumerateSwiftFiles(at: url, directoryFilter: directoryFilter, execute: execute)
      }

      guard name.hasSuffix(".swift") else { continue }

      try execute(name, url)
    }
  } catch {
    print(error)
  }
}

private func handleEnumeratorError(url: URL, error: Error) -> Bool {
  print("directoryEnumerator error at \(url): ", error)
  return true
}
