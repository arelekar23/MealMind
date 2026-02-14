//
//  InventoryViewModel.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/12/26.
//

import Foundation

@MainActor
class InventoryViewModel: ObservableObject {
    @Published var allKitchenItems: [KitchenItem] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: IngredientCategory? = nil
    init() {
        
    }
    var filteredKitchenItems: [KitchenItem] {
        var result = allKitchenItems
        //Filter by category
        if let category = selectedCategory {
            result = result.filter {
                $0.category == category
            }
        }
        // Filter by search text
        if(!searchText.isEmpty) {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query)
            }
        }
        return result
    }
    var availableCount: Int {
        allKitchenItems.filter {
            $0.isAvailable
        }.count
    }
    
    // MARK: - Reset filter
    func clearFilter() {
        searchText = ""
        selectedCategory = nil
    }
    
    // MARK: - Add item
    func addItem(_ item: KitchenItem) -> Bool {
        let key = item.name.lowercased()
        if allKitchenItems.contains(where: { $0.name.lowercased() == key }) {
            return false
        }
        allKitchenItems.append(item)
        return true
    }
    
    // MARK: - Remove item
    func removeItem(_ item: KitchenItem) {
        if let index = allKitchenItems.firstIndex(of: item) {
            allKitchenItems.remove(at: index)
        }
    }
    
    // MARK: - Increment countable item
    func incrementCount(for item: KitchenItem) {
        guard let index = allKitchenItems.firstIndex(of: item) else { return }
        allKitchenItems[index].count += 1
    }
    
    // MARK: - Decrement countable item
    func decrementCount(for item: KitchenItem) {
        guard let index = allKitchenItems.firstIndex(of: item) else { return }
        allKitchenItems[index].count -= 1
    }
    
    // MARK: - Set stock level for bulk item
    func setStockLevel(for item: KitchenItem, level: StockLevel) {
        guard let index = allKitchenItems.firstIndex(of: item) else { return }
        allKitchenItems[index].stockLevel = level
    }
    
    // MARK: - Check if an ingredient is available by name
    func isAvailable(_ ingredientName: String) -> Bool {
        let key = ingredientName.lowercased()
        guard let item = allKitchenItems.first(where: { $0.name.lowercased() == key }) else {
            return false
        }
        return item.isAvailable
    }
}

