//
//  GroceryItem.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/15/26.
//

import Foundation
import SwiftData

@Model
class GroceryItem {
    var id: UUID
    var name: String
    var totalQuantity: Double
    var unit: String
    var categoryRaw: String
    var typeRaw: String
    var isChecked: Bool
    var isRemoved: Bool
    var pantryCount: Int
    var netQuantity: Double
    
    var category: IngredientCategory {
        get { IngredientCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    
    var type: IngredientType {
        get { IngredientType(rawValue: typeRaw) ?? .bulk }
        set { typeRaw = newValue.rawValue }
    }
    
    var displayQuantity: String {
        if netQuantity <= 0 { return "In stock" }
        let rounded = netQuantity.truncatingRemainder(dividingBy: 1) == 0
        ? String(format: "%.0f", netQuantity)
        : String(format: "%.1f", netQuantity)
        return unit.isEmpty ? rounded : "\(rounded) \(unit)"
    }
    
    var isFullyCovered: Bool { netQuantity <= 0 }
    
    init(
        name: String,
        totalQuantity: Double,
        unit: String,
        category: IngredientCategory,
        type: IngredientType,
        pantryCount: Int,
        netQuantity: Double
    ) {
        self.id = UUID()
        self.name = name
        self.totalQuantity = totalQuantity
        self.unit = unit
        self.categoryRaw = category.rawValue
        self.typeRaw = type.rawValue
        self.isChecked = false
        self.isRemoved = false
        self.pantryCount = pantryCount
        self.netQuantity = netQuantity
    }
}


struct GroceryListBuilder {
    static func rebuild(
        meals: [PlannedMeal],
        pantry: [KitchenItem],
        existing: [GroceryItem],
        startDate: Date,
        endDate: Date,
        context: ModelContext
    ) {
        let fresh = buildFresh(meals: meals, pantry: pantry, startDate: startDate, endDate: endDate)
        
        var freshNames = Set<String>()
        
        for item in fresh {
            let key = item.name.lowercased()
            freshNames.insert(key)
            if let existing = existing.first(where: { IngredientMatcher.matches($0.name, item.name) })  {
                existing.totalQuantity = item.totalQuantity
                existing.unit = item.unit
                existing.category = item.category
                existing.type = item.type
                existing.pantryCount = item.pantryCount
                existing.netQuantity = item.netQuantity
            } else {
                context.insert(item)
            }
        }
        
        for item in existing {
            if !fresh.contains(where: { IngredientMatcher.matches($0.name, item.name) }) {
                context.delete(item)
            }
        }
    }
    
    private static func buildFresh(
        meals: [PlannedMeal],
        pantry: [KitchenItem],
        startDate: Date,
        endDate: Date
    ) -> [GroceryItem] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: startDate)
        let end = cal.startOfDay(for: endDate)
        
        let relevantMeals = meals.filter { meal in
            let mealDate = cal.startOfDay(for: meal.date)
            return mealDate >= start && mealDate <= end && !meal.isCooked
        }
        
        let allRecipes = RecipeLoader.load()
        let recipeLookup = Dictionary(uniqueKeysWithValues: allRecipes.map { ($0.id, $0) })
        
        var aggregated: [String: (quantity: Double, unit: String, category: IngredientCategory, type: IngredientType)] = [:]
        
        for meal in relevantMeals {
            guard let recipe = recipeLookup[meal.recipeId] else { continue }
            let ratio = meal.recipeServings > 0
            ? Double(meal.servingsPlanned) / Double(meal.recipeServings)
            : 1.0
            
            let skipIngredients: Set<String> = ["water", "ice", "hot water", "cold water", "warm water", "boiling water"]
            
            for ingredient in recipe.ingredients {
                let key = ingredient.name.lowercased()
                if skipIngredients.contains(key) { continue }
                let scaledQty = ingredient.quantity * ratio
                if let existing = aggregated[key] {
                    aggregated[key] = (
                        quantity: existing.quantity + scaledQty,
                        unit: existing.unit,
                        category: existing.category,
                        type: existing.type
                    )
                } else {
                    aggregated[key] = (
                        quantity: scaledQty,
                        unit: ingredient.unit,
                        category: ingredient.category,
                        type: ingredient.type
                    )
                }
            }
        }
        
        return aggregated.map { key, value in
            let pantryItem = pantry.first(where: { IngredientMatcher.matches($0.name, key) })
            var pantryCount = 0
            var netQty = value.quantity
            
            if let item = pantryItem {
                if item.type == .countable {
                    pantryCount = item.count
                    netQty = max(0, value.quantity - Double(item.count))
                } else {
                    switch item.stockLevel {
                    case .full: netQty = 0
                    case .low: netQty = max(0, value.quantity * 0.5)
                    case .out: break
                    }
                }
            }
            
            return GroceryItem(
                name: key.capitalized,
                totalQuantity: value.quantity,
                unit: value.unit,
                category: value.category,
                type: value.type,
                pantryCount: pantryCount,
                netQuantity: netQty
            )
        }
    }
}
