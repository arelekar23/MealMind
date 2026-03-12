//
//  KitchenInventory.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/10/26.
//

import Foundation
import SwiftData

@Model
class KitchenItem {
    var id: UUID
    var name: String
    var categoryRaw: String
    var typeRaw: String
    var count: Int
    var stockLevelRaw: String
    
    var category: IngredientCategory {
        get { IngredientCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    
    var type: IngredientType {
        get { IngredientType(rawValue: typeRaw) ?? .bulk }
        set { typeRaw = newValue.rawValue }
    }
    
    var stockLevel: StockLevel {
        get { StockLevel(rawValue: stockLevelRaw) ?? .out }
        set { stockLevelRaw = newValue.rawValue }
    }
    
    var isAvailable: Bool {
        if type == .countable {
            return count > 0
        } else {
            return stockLevel != .out
        }
    }
    
    init(name: String, category: IngredientCategory, type: IngredientType, count: Int = 0, stockLevel: StockLevel = .out) {
        self.id = UUID()
        self.name = name
        self.categoryRaw = category.rawValue
        self.typeRaw = type.rawValue
        self.count = count
        self.stockLevelRaw = stockLevel.rawValue
    }
}

enum StockLevel: String, Codable, CaseIterable {
    case full = "full"
    case low = "low"
    case out = "out"
    
    var displayName: String {
        switch self {
        case .full: return "Have it"
        case .low: return "Running low"
        case .out: return "Out"
        }
    }
}
