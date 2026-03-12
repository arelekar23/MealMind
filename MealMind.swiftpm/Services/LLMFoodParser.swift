//
//  LLMFoodParser.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/22/26.
//

import Foundation
import FoundationModels

@MainActor
class LLMFoodParser {
    private let model = SystemLanguageModel.default
    
    var isAvailable: Bool {
        if case .available = model.availability { return true }
        return false
    }
    
    func parse(_ input: String) async -> [ParsedVoiceItem]? {
        guard isAvailable else { return nil }
        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: """
            Extract ONLY food or kitchen items from this speech-to-text input. \
            If the sentence is not meaningful, respond with NONE. \
            Do not hallucinate. Do not make up factual information. \
            If there are NO food items, respond with exactly: NONE \
            Otherwise list each item on a new line as: NAME|QUANTITY \
            NAME is singular lowercase. QUANTITY is a number (0 if not specified). \
            Do not include anything else. \
            Input: "\(input)"
            """)
            
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.uppercased().contains("NONE") || text.isEmpty { return [] }
            
            var allLines: [String] = []
            for line in text.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty || trimmed.uppercased().contains("NONE") { continue }
                let segments = trimmed.components(separatedBy: " ")
                var currentItem = ""
                for segment in segments {
                    if segment.contains("|") && !currentItem.isEmpty && currentItem.contains("|") {
                        allLines.append(currentItem.trimmingCharacters(in: .whitespaces))
                        currentItem = segment
                    } else {
                        currentItem += (currentItem.isEmpty ? "" : " ") + segment
                    }
                }
                if !currentItem.isEmpty && currentItem.contains("|") {
                    allLines.append(currentItem.trimmingCharacters(in: .whitespaces))
                }
            }
            
            var items: [ParsedVoiceItem] = []
            let unitWords: Set<String> = [
                "tsp", "tbsp", "cup", "cups", "ml", "ltr", "gm", "kg",
                "gallon", "gallons", "litre", "litres", "liter", "liters",
                "ounce", "ounces", "oz", "pound", "pounds", "lb", "lbs",
                "pinch", "handful", "bunch", "slice", "slices",
                "piece", "pieces", "pcs", "packet", "packets", "bottle", "bottles",
                "can", "cans", "bag", "bags", "box", "boxes", "dozen"
            ]
            
            for line in allLines {
                let parts = line.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                var name = ""
                var qty = 0
                for part in parts {
                    let words = part.components(separatedBy: " ")
                    var partIsQty = false
                    for word in words {
                        if let num = Int(word) { qty = num; partIsQty = true }
                        else if unitWords.contains(word) { partIsQty = true }
                    }
                    if !partIsQty {
                        if name.isEmpty { name = part } else { name += " " + part }
                    }
                }
                guard !name.isEmpty, name.count > 1 else { continue }
                let cleanName: String
                if name.contains(" ") {
                    cleanName = name.prefix(1).uppercased() + name.dropFirst()
                } else {
                    let parsed = IngredientParser.parse(name)
                    let raw = parsed.name.isEmpty ? name : parsed.name
                    cleanName = raw.prefix(1).uppercased() + raw.dropFirst()
                }
                let classified = IngredientClassifier.classify(cleanName)
                guard classified.category != .other else { continue }
                let type: IngredientType = qty > 1 ? .countable : classified.type
                
                let lower = input.lowercased()
                let action: PantryAction
                if lower.contains("spoiled") || lower.contains("expired") || lower.contains("rotten") || lower.contains("went bad") || lower.contains("gone bad") {
                    action = qty > 0 ? .remove : .out
                } else if lower.contains("out of") || lower.contains("no more") || lower.contains("don't have") || lower.contains("ran out") {
                    action = .out
                } else if lower.contains("low on") || lower.contains("running low") || lower.contains("almost out") {
                    action = .low
                } else if lower.hasPrefix("used ") || lower.contains(" used ") ||
                            lower.hasPrefix("ate ") || lower.contains(" ate ") ||
                            lower.hasPrefix("had ") || lower.contains(" had ") ||
                            lower.contains("cooked") || lower.contains("consumed") ||
                            lower.contains("eaten") || lower.contains("finished") ||
                            lower.contains("threw") || lower.contains("wasted") ||
                            lower.contains("made ") {
                    action = .remove
                } else {
                    action = .add
                }
                let isAll = lower.contains("all ") || lower.contains("all the")
                let finalQty = isAll ? -1 : qty
                
                items.append(ParsedVoiceItem(
                    rawText: cleanName, name: cleanName,
                    category: classified.category, type: classified.type,
                    count: classified.type == .countable ? max(finalQty, 1) : 0, stockLevel: classified.type == .bulk ? .full : .out,
                    action: action
                ))
            }
            return items
        } catch { return nil }
    }
}
