//
//  RecipeViewModel.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/11/26.
//

import Foundation

class RecipeViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var searchText = ""
    @Published var selectedCategory: MealCategory? = nil
    
    var filteredRecipes: [Recipe] {
        var result = recipes
        if let category = selectedCategory { result = result.filter { $0.category == category } }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.cuisine.lowercased().contains(query) ||
                $0.tags.contains(where: { $0.lowercased().contains(query) })
            }
        }
        return result
    }
    
    init() { loadRecipes() }
    
    func loadRecipes() {
        var all = RecipeLoader.load()
        all.append(contentsOf: loadUserRecipes())
        recipes = all
    }
    
    func addRecipe(_ recipe: Recipe) {
        recipes.append(recipe)
        saveUserRecipe(recipe)
    }
    
    func updateRecipe(_ recipe: Recipe) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) { recipes[index] = recipe }
        var userRecipes = loadUserRecipes()
        if let index = userRecipes.firstIndex(where: { $0.id == recipe.id }) { userRecipes[index] = recipe }
        saveAllUserRecipes(userRecipes)
    }
    
    func deleteRecipe(_ recipe: Recipe) {
        recipes.removeAll { $0.id == recipe.id }
        var userRecipes = loadUserRecipes()
        userRecipes.removeAll { $0.id == recipe.id }
        saveAllUserRecipes(userRecipes)
    }
    
    func isUserRecipe(_ recipe: Recipe) -> Bool {
        !RecipeLoader.load().contains(where: { $0.id == recipe.id })
    }
    
    private func userRecipesFileURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("user_recipes.json")
    }
    
    private func loadUserRecipes() -> [Recipe] {
        let url = userRecipesFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Recipe].self, from: data)
        } catch { return [] }
    }
    
    private func saveUserRecipe(_ recipe: Recipe) {
        var existing = loadUserRecipes()
        existing.append(recipe)
        saveAllUserRecipes(existing)
    }
    
    private func saveAllUserRecipes(_ recipes: [Recipe]) {
        do {
            let data = try JSONEncoder().encode(recipes)
            try data.write(to: userRecipesFileURL())
        } catch { }
    }
    
    func canCookNow(with pantry: [KitchenItem]) -> [Recipe] {
        recipes.filter { recipe in
            let total = recipe.ingredients.count
            guard total > 0 else { return false }
            let matched = recipe.ingredients.filter { ing in
                pantry.contains { item in
                    item.isAvailable && IngredientMatcher.matches(item.name, ing.name)
                }
            }.count
            return Double(matched) / Double(total) >= 0.7
        }
    }
}
