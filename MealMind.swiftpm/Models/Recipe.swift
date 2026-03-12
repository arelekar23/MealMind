//
//  Recipe.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/9/26.
//

import Foundation

struct Recipe: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let cuisine: String
    let category: MealCategory
    let difficulty: Difficulty
    let prepTime: Int
    let cookTime: Int
    let servings: Int
    let tags: [String]
    let ingredients: [Ingredient]
    let steps: [String]
    let tips: String
    let image: String?
    
    var totalTime: Int { prepTime + cookTime }
    var isQuick: Bool { totalTime <= 20 }
}

struct Ingredient: Codable, Hashable {
    let name: String
    let quantity: Double
    let unit: String
    let category: IngredientCategory
    let type: IngredientType
}

enum MealCategory: String, Codable, CaseIterable, Hashable {
    case breakfast = "breakfast"
    case mainMeal = "main meal"
    case snack = "snack"
    case dessert = "dessert"
    
    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .mainMeal: return "Main Meal"
        case .snack: return "Snack"
        case .dessert: return "Dessert"
        }
    }
}

enum Difficulty: String, Codable, CaseIterable, Hashable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
}

enum IngredientType: String, Codable, Hashable {
    case countable = "countable"
    case bulk = "bulk"
}

enum IngredientCategory: String, Codable, CaseIterable, Hashable {
    case vegetable = "vegetable"
    case fruit = "fruit"
    case dairy = "dairy"
    case pantry = "pantry"
    case spice = "spice"
    case herb = "herb"
    case protein = "protein"
    case condiment = "condiment"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .vegetable: return "🥬 Vegetables"
        case .fruit: return "🍋 Fruits"
        case .dairy: return "🥛 Dairy"
        case .pantry: return "🏪 Pantry"
        case .spice: return "🌶️ Spices"
        case .herb: return "🌿 Herbs"
        case .protein: return "🥚 Protein"
        case .condiment: return "🫒 Oil & Condiments"
        case .other: return "📦 Other"
        }
    }
}
