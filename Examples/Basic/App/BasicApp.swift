import FeatureA
import SwiftUI

@main
struct BasicApp: App {
  var body: some Scene {
    WindowGroup {
      Text(FeatureA().welcome())
    }
  }
}
