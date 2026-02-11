import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("MealMind")
            .onAppear {
                let recipes = RecipeLoader.load()
                for r in recipes {
                    print("- \(r.name) (\(r.category.displayName)): \(r.ingredients.count) ingredients")
                }
            }
    }
}
