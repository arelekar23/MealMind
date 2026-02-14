import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Recipes", systemImage: "book") {
                RecipeListView()
            }
            
            Tab("Weekly Plan", systemImage: "calendar") {
                // TODO: WeeklyPlanView()
                Text("Weekly Plan")
            }
            
            Tab("Grocery", systemImage: "cart") {
                // TODO: GroceryListView()
                Text("Grocery List")
            }
            
            Tab("Pantry", systemImage: "refrigerator") {
                InventoryView()
            }
        }
    }
}
