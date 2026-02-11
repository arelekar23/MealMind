//
//  KitchenInventory.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/10/26.
//

import Foundation

struct KitchenItem: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let category: IngredientCategory
    let type: IngredientType
    var count: Int
    var stockLevel: StockLevel
    
    var isAvailable: Bool {
        switch type {
        case .countable:
            return count > 0
        case .bulk:
            return stockLevel != .out
        }
    }
    init(name: String, category: IngredientCategory, type: IngredientType, count: Int = 0, stockLevel: StockLevel = .out) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.type = type
        self.count = count
        self.stockLevel = stockLevel
    }
}

// MARK: - Stock Level (for bulk items like rice, oil, spices)
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
