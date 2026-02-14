//
//  KitchenViewModel.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/11/26.
//

import Foundation

@MainActor
class RecipeViewModel: ObservableObject {
    
    @Published var allRecipes: [Recipe] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: MealCategory? = nil
    @Published var selectedDifficulty: Difficulty? = nil
    
    init() {
        allRecipes = RecipeLoader.load()
    }
    
    // MARK: - Filtered recipes based on search and filters
    var filteredRecipes: [Recipe] {
        var results = allRecipes
        
        // Filter by category
        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }
        
        // Filter by difficulty
        if let difficulty = selectedDifficulty {
            results = results.filter { $0.difficulty == difficulty }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            results = results.filter {
                $0.name.lowercased().contains(query) ||
                $0.cuisine.lowercased().contains(query) ||
                $0.tags.contains(where: { $0.lowercased().contains(query) })
            }
        }
        
        return results
    }
    
    // MARK: - Quick filter helpers
    var quickRecipes: [Recipe] {
        allRecipes.filter { $0.isQuick }
    }
    
    var breakfastRecipes: [Recipe] {
        allRecipes.filter { $0.category == .breakfast }
    }
    
    var mainMealRecipes: [Recipe] {
        allRecipes.filter { $0.category == .mainMeal }
    }
    
    // MARK: - Reset all filters
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedDifficulty = nil
    }
}
