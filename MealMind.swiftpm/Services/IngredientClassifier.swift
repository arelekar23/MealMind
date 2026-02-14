//
//  IngredientClassifier.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/12/26.
//

import Foundation
import NaturalLanguage
import CoreML

struct IngredientClassifier {
    
    // MARK: - Load model from bundle
    private static func loadModel() -> NLModel? {
        guard let modelURL = Bundle.main.url(forResource: "IngredientCategoryClassifier", withExtension: "mlmodelc"),
              let mlModel = try? MLModel(contentsOf: modelURL),
              let nlModel = try? NLModel(mlModel: mlModel) else {
            print("❌ Failed to load IngredientCategoryClassifier model")
            return nil
        }
        print("✅ IngredientCategoryClassifier loaded")
        return nlModel
    }
    
    // MARK: - Classify ingredient name into category and type
    static func classify(_ name: String) -> (category: IngredientCategory, type: IngredientType) {
        let category = predictCategory(for: name)
        let type = determineType(name: name, category: category)
        return (category, type)
    }
    
    // MARK: - Predict category using CoreML model
    private static func predictCategory(for name: String) -> IngredientCategory {
        guard let model = loadModel(),
              let prediction = model.predictedLabel(for: name.lowercased()) else {
            return .other
        }
        return IngredientCategory(rawValue: prediction) ?? .other
    }
    
    // MARK: - Determine type based on category + known exceptions
    private static func determineType(name: String, category: IngredientCategory) -> IngredientType {
        let key = name.lowercased()
        
        let countableItems: Set<String> = ["egg", "bread", "roti", "pav", "bun", "chapati", "poli", "paratha", "naan", "puri", "bhakri", "phulka", "kulcha", "thepla"]
        if countableItems.contains(key) {
            return .countable
        }
        
        switch category {
        case .vegetable, .fruit:
            return .countable
        case .spice, .pantry, .dairy, .condiment, .herb:
            return .bulk
        case .protein:
            return key == "egg" ? .countable : .bulk
        case .other:
            return .bulk
        }
    }
}
