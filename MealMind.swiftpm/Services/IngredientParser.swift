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
    
    private static let wordNumbers: [String: Int] = [
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4,
        "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9,
        "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13,
        "fourteen": 14, "fifteen": 15, "sixteen": 16, "seventeen": 17,
        "eighteen": 18, "nineteen": 19, "twenty": 20, "thirty": 30,
        "forty": 40, "fifty": 50
    ]
    
    private static func parseNumber(_ word: String) -> Int? {
        if let num = Int(word) { return num }
        return wordNumbers[word.lowercased()]
    }
    
    static func parse(_ input: String) -> ParsedResult {
        var result = ParsedResult()
        let cleaned = input.lowercased().trimmingCharacters(in: .whitespaces)
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = cleaned
        var numbers: [Int] = []
        var nouns: [String] = []
        
        tagger.enumerateTags(in: cleaned.startIndex..<cleaned.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            let word = String(cleaned[range])
            if let tag = tag {
                switch tag {
                case .number:
                    if let num = parseNumber(word) { numbers.append(num) }
                case .noun:
                    nouns.append(word)
                default:
                    if let num = wordNumbers[word.lowercased()] { numbers.append(num) }
                }
            }
            return true
        }
        
        if nouns.isEmpty { nouns = extractWordsSimple(from: cleaned) }
        if let firstNumber = numbers.first { result.count = firstNumber }
        let ingredientName = nouns.last ?? nouns.joined(separator: " ")
        let lemmatized = lemmatize(ingredientName)
        result.name = lemmatized
        let classified = IngredientClassifier.classify(lemmatized)
        result.category = classified.category
        result.type = classified.type
        if result.type == .bulk { result.stockLevel = .full; result.count = 0 }
        return result
    }
    
    private static func lemmatize(_ text: String) -> String {
        let sentence = "I bought some \(text) today"
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = sentence
        if let targetRange = sentence.range(of: text) {
            let tag = tagger.tag(at: targetRange.lowerBound, unit: .word, scheme: .lemma)
            if let lemma = tag.0?.rawValue, !lemma.isEmpty { return lemma }
        }
        return stripPlural(text)
    }
    
    private static func stripPlural(_ word: String) -> String {
        let text = word.lowercased()
        let irregulars: [String: String] = [
            "potatoes": "potato", "tomatoes": "tomato", "mangoes": "mango",
            "chillies": "chili", "chilies": "chili", "leaves": "leaf",
            "knives": "knife", "bananas": "banana", "apples": "apple",
            "oranges": "orange", "onions": "onion", "lemons": "lemon",
            "eggs": "egg", "carrots": "carrot", "capsicums": "capsicum",
            "cucumbers": "cucumber",
        ]
        if let irregular = irregulars[text] { return irregular }
        if text.hasSuffix("ies") && text.count > 4 { return String(text.dropLast(3)) + "y" }
        if text.hasSuffix("ves") && text.count > 4 { return String(text.dropLast(3)) + "f" }
        if text.hasSuffix("oes") && text.count > 4 { return String(text.dropLast(2)) }
        if text.hasSuffix("es") && text.count > 3 {
            let stem = String(text.dropLast(2))
            if IngredientClassifier.classify(stem).category != .other { return stem }
            let stemS = String(text.dropLast(1))
            if IngredientClassifier.classify(stemS).category != .other { return stemS }
            return stem
        }
        if text.hasSuffix("s") && !text.hasSuffix("ss") && text.count > 2 { return String(text.dropLast(1)) }
        return text
    }
    
    private static func extractWordsSimple(from text: String) -> [String] {
        let skipWords = Set(["add", "i", "want", "to", "need", "get", "buy", "have", "got", "bought", "some", "a", "an", "the", "of", "few", "kg", "gm", "ml", "ltr", "packet", "packets", "pack", "packs", "piece", "pieces", "bunch", "can", "cans", "bottle", "bottles", "bag", "bags", "box", "boxes", "carton", "cartons", "jar", "jars", "tin", "tins", "cup", "cups", "glass", "glasses"])
        return text.components(separatedBy: .whitespaces).filter {
            !$0.isEmpty && Int($0) == nil && !wordNumbers.keys.contains($0) && !skipWords.contains($0)
        }
    }
}
