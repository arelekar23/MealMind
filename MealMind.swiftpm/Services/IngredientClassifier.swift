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
    private static func loadModel() -> NLModel? {
        guard let modelURL = Bundle.main.url(forResource: "IngredientCategoryClassifier", withExtension: "mlmodelc"),
              let mlModel = try? MLModel(contentsOf: modelURL),
              let nlModel = try? NLModel(mlModel: mlModel) else { return nil }
        return nlModel
    }
    
    static func classify(_ name: String) -> (category: IngredientCategory, type: IngredientType) {
        let category = predictCategory(for: name)
        let type = determineType(name: name, category: category)
        return (category, type)
    }
    
    private static func predictCategory(for name: String) -> IngredientCategory {
        guard let model = loadModel(),
              let prediction = model.predictedLabel(for: name.lowercased()) else { return .other }
        return IngredientCategory(rawValue: prediction) ?? .other
    }
    
    private static func determineType(name: String, category: IngredientCategory) -> IngredientType {
        switch category {
        case .vegetable, .fruit: return .countable
        case .spice, .pantry, .dairy, .condiment, .herb: return .bulk
        case .protein: return name.lowercased() == "egg" ? .countable : .bulk
        case .other: return .bulk
        }
    }
}
