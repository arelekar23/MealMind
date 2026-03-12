import SwiftData
import SwiftUI

@main
struct MyApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showSplash = true
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreen {
                        showSplash = false
                    }
                    .transition(.opacity)
                } else if !hasSeenOnboarding {
                    OnboardingView()
                } else {
                    ContentView()
                }
            }
            .animation(.easeOut(duration: 0.8), value: showSplash)
            .modelContainer(for: [KitchenItem.self, PlannedMeal.self, GroceryItem.self])
        }
    }
}

