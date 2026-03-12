//
//  RecipeLoader.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/9/26.
//

import Foundation

class RecipeLoader {
    static func load() -> [Recipe] {
        guard let url = Bundle.main.url(forResource: "recipes", withExtension: "json") else { return [] }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Recipe].self, from: data)
        } catch { return [] }
    }
}
