import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Recipes", systemImage: "book") {
                RecipeListView()
            }
            
            Tab("Meal Plan", systemImage: "calendar") {
                MealPlanView()
            }
            
            Tab("Grocery", systemImage: "cart") {
                GroceryListView()
            }
            
            Tab("Pantry", systemImage: "refrigerator") {
                InventoryView()
            }
        }
    }
}
