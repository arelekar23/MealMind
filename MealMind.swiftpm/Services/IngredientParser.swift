//
//  IngredientParser.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/12/26.
//

import Foundation
import NaturalLanguage

struct IngredientParser {
    
    struct ParsedResult {
        var name: String = ""
        var count: Int = 1
        var category: IngredientCategory = .other
        var type: IngredientType = .countable
        var stockLevel: StockLevel = .full
    }
    
    // MARK: - Parse free-form text like "Add 5 bananas" or "I want to add 5 apples"
    static func parse(_ input: String) -> ParsedResult {
        var result = ParsedResult()
        
        let cleaned = input
            .lowercased()
            .trimmingCharacters(in: .whitespaces)
        
        // Extract number and ingredient name using NLP
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = cleaned
        
        var numbers: [Int] = []
        var nouns: [String] = []
        
        tagger.enumerateTags(in: cleaned.startIndex..<cleaned.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            let word = String(cleaned[range])
            
            if let tag = tag {
                switch tag {
                case .number:
                    if let num = Int(word) {
                        numbers.append(num)
                    }
                case .noun:
                    nouns.append(word)
                default:
                    break
                }
            }
            return true
        }
        
        // If NLP didn't find nouns, fallback to simple parsing
        if nouns.isEmpty {
            nouns = extractWordsSimple(from: cleaned)
        }
        
        // Set count from extracted number
        if let firstNumber = numbers.first {
            result.count = firstNumber
        }
        
        // Build ingredient name from nouns (last noun is usually the ingredient)
        let ingredientName = nouns.last ?? nouns.joined(separator: " ")
        
        // Lemmatize to handle plurals
        let lemmatized = lemmatize(ingredientName)
        
        print("🔍 Input: \(input)")
        print("🔍 Nouns found: \(nouns)")
        print("🔍 Raw: \(ingredientName) → Lemmatized: \(lemmatized)")
        
        result.name = lemmatized
        
        // Use classifier to determine category and type
        let classified = IngredientClassifier.classify(lemmatized)
        
        print("🔍 Classified: \(classified.category) / \(classified.type)")
        
        result.category = classified.category
        result.type = classified.type
        
        // If bulk item, set stock level instead of count
        if result.type == .bulk {
            result.stockLevel = .full
            result.count = 0
        }
        
        return result
    }
    
    // MARK: - Lemmatize to handle plurals
    private static func lemmatize(_ text: String) -> String {
        // Try NLP lemmatization with sentence context
        let sentence = "I bought some \(text) today"
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = sentence
        
        // Find the lemma of our target word
        let targetRange = sentence.range(of: text)
        if let targetRange = targetRange {
            let tag = tagger.tag(at: targetRange.lowerBound, unit: .word, scheme: .lemma)
            if let lemma = tag.0?.rawValue, !lemma.isEmpty {
                print("🔍 NLP lemma for '\(text)': '\(lemma)'")
                return lemma
            }
        }
        
        // Fallback: manual plural stripping
        let stripped = stripPlural(text)
        print("🔍 Manual strip for '\(text)': '\(stripped)'")
        return stripped
    }
    
    // MARK: - Manual plural handling
    private static func stripPlural(_ word: String) -> String {
        let text = word.lowercased()
        
        // Special cases
        let irregulars: [String: String] = [
            "potatoes": "potato",
            "tomatoes": "tomato",
            "mangoes": "mango",
            "chillies": "chili",
            "chilies": "chili",
            "leaves": "leaf",
            "knives": "knife",
            "bananas": "banana",
            "apples": "apple",
            "oranges": "orange",
            "onions": "onion",
            "lemons": "lemon",
            "eggs": "egg",
            "carrots": "carrot",
            "capsicums": "capsicum",
            "cucumbers": "cucumber",
        ]
        
        if let irregular = irregulars[text] {
            return irregular
        }
        
        // Common plural rules
        if text.hasSuffix("ies") && text.count > 4 {
            return String(text.dropLast(3)) + "y"
        }
        if text.hasSuffix("ves") && text.count > 4 {
            return String(text.dropLast(3)) + "f"
        }
        if text.hasSuffix("oes") && text.count > 4 {
            return String(text.dropLast(2))
        }
        if text.hasSuffix("es") && text.count > 3 {
            let stem = String(text.dropLast(2))
            // Check if stem is a known word
            if IngredientClassifier.classify(stem).category != .other {
                return stem
            }
            // Try dropping just "s"
            let stemS = String(text.dropLast(1))
            if IngredientClassifier.classify(stemS).category != .other {
                return stemS
            }
            return stem
        }
        if text.hasSuffix("s") && !text.hasSuffix("ss") && text.count > 2 {
            return String(text.dropLast(1))
        }
        
        return text
    }
    
    // MARK: - Simple fallback parser (remove numbers, keep words)
    private static func extractWordsSimple(from text: String) -> [String] {
        let components = text.components(separatedBy: .whitespaces)
        var words: [String] = []
        
        let skipWords = Set(["add", "i", "want", "to", "need", "get", "buy", "have", "got", "bought", "some", "a", "an", "the", "of", "few", "kg", "gm", "ml", "ltr", "packet", "packets", "pack", "packs", "piece", "pieces", "bunch", "can", "cans", "bottle", "bottles", "bag", "bags", "box", "boxes", "carton", "cartons", "jar", "jars", "tin", "tins", "cup", "cups", "glass", "glasses"])
        
        for component in components {
            if Int(component) != nil { continue }
            if skipWords.contains(component) { continue }
            if component.isEmpty { continue }
            words.append(component)
        }
        
        return words
    }
}
