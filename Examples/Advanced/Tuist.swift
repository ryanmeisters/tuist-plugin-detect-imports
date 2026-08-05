import ProjectDescription

let config = Config(
  project: .tuist(
    plugins: [
      // In your project, use:
      // .git(url: "https://github.com/ryanmeisters/tuist-plugin-detect-imports.git", sha: "<sha>")
      .local(path: .relativeToRoot("../..")),
    ]
  )
)
