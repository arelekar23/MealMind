//
//  RecipeLoader.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/9/26.
//

import Foundation

class RecipeLoader {
    
    static func load() -> [Recipe] {
        guard let url = Bundle.main.url(forResource: "recipes", withExtension: "json") else {
            print("❌ recipes.json not found")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let recipes = try JSONDecoder().decode([Recipe].self, from: data)
            print("✅ Loaded \(recipes.count) recipes")
            return recipes
        } catch {
            print("❌ Failed to decode recipes: \(error)")
            return []
        }
    }
}
