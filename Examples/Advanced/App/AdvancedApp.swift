import FeatureA
import ModuleAImpl
import SwiftUI

// The app is the composition root: it's the only place that imports Impl
// modules, constructing them and injecting them into features that only
// know the interface.
@main
struct AdvancedApp: App {
  var body: some Scene {
    WindowGroup {
      Text(FeatureA(client: ModuleAClientImpl()).summary())
    }
  }
}
