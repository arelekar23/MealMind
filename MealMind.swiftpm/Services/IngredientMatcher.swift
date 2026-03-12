//
//  IngredientMatcher.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/16/26.
//

import Foundation

struct IngredientMatcher {
    static func canonicalKey(for name: String) -> String {
        var result = name.lowercased().trimmingCharacters(in: .whitespaces)
        result = applyAliases(result)
        result = stripDescriptors(result)
        result = singularize(result)
        result = result
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return result
    }
    
    static func matches(_ a: String, _ b: String) -> Bool {
        canonicalKey(for: a) == canonicalKey(for: b)
    }
    
    static func findMatch(for ingredientName: String, in pantryItems: [KitchenItem]) -> KitchenItem? {
        let key = canonicalKey(for: ingredientName)
        return pantryItems.first { canonicalKey(for: $0.name) == key }
    }
    
    private static let aliases: [(patterns: [String], canonical: String)] = [
        (["jeera", "jira"], "cumin"),
        (["dhania powder", "dhania"], "coriander"),
        (["haldi"], "turmeric"),
        (["rai", "sarson"], "mustard seeds"),
        (["methi leaves", "methi"], "fenugreek"),
        (["hing"], "asafoetida"),
        (["imli"], "tamarind"),
        (["gur", "jaggery powder"], "jaggery"),
        (["besan"], "chickpea flour"),
        (["maida"], "all purpose flour"),
        (["atta", "gehun ka atta"], "whole wheat flour"),
        (["paneer cheese"], "paneer"),
        (["dahi", "curd"], "yogurt"),
        (["ghee", "clarified butter"], "ghee"),
        (["amchur", "amchoor", "dry mango powder"], "mango powder"),
        (["capsicum", "green pepper", "red pepper", "yellow pepper"], "bell pepper"),
        (["spring onion", "scallion", "green onion"], "green onion"),
        (["coriander leaves", "cilantro leaves", "fresh cilantro", "fresh coriander"], "cilantro"),
        (["garbanzo beans", "chickpea", "chole", "chana"], "chickpeas"),
        (["aubergine", "brinjal", "baingan"], "eggplant"),
        (["lady finger", "bhindi"], "okra"),
        (["courgette"], "zucchini"),
        (["rocket"], "arugula"),
        (["double cream", "heavy whipping cream"], "heavy cream"),
        (["bicarbonate of soda", "baking soda", "soda bicarb"], "baking soda"),
        (["corn flour", "corn starch"], "cornstarch"),
        (["plain flour"], "all purpose flour"),
        (["granulated sugar", "white sugar", "castor sugar", "caster sugar"], "sugar"),
        (["sea salt", "rock salt", "table salt", "kosher salt", "pink salt"], "salt"),
        (["groundnut oil", "peanut oil"], "peanut oil"),
        (["rapeseed oil", "canola oil"], "canola oil"),
        (["vegetable oil", "cooking oil", "neutral oil"], "oil"),
        (["lemon juice", "lime juice", "nimbu"], "lemon juice"),
    ]
    
    private static func applyAliases(_ input: String) -> String {
        for entry in aliases {
            for pattern in entry.patterns {
                if input == pattern { return entry.canonical }
            }
        }
        return input
    }
    
    private static let strippableWords: Set<String> = [
        "fresh", "dried", "dry", "frozen", "canned", "tinned", "raw",
        "chopped", "diced", "sliced", "minced", "grated", "shredded",
        "crushed", "ground", "powdered", "whole", "halved", "quartered",
        "peeled", "deseeded", "seeded", "pitted", "trimmed", "torn",
        "julienned", "cubed", "mashed", "pureed", "roasted", "toasted",
        "blanched", "soaked", "rinsed", "drained", "thawed",
        "small", "medium", "large", "big", "thin", "thick", "fine", "coarse",
        "warm", "hot", "cold", "room", "temperature", "lukewarm",
        "optional", "to", "taste", "for", "garnish", "garnishing",
        "as", "needed", "required", "about", "approximately",
        "loosely", "packed", "firmly", "lightly", "roughly",
        "seeds", "seed", "leaves", "leaf", "cloves", "clove",
        "stalks", "stalk", "stems", "stem", "sprigs", "sprig",
        "florets", "floret", "pods", "pod", "bulb", "bulbs",
        "pieces", "piece",
    ]
    
    private static func stripDescriptors(_ input: String) -> String {
        let words = input.split(separator: " ").map(String.init)
        let filtered = words.filter { !strippableWords.contains($0) }
        return filtered.isEmpty ? input : filtered.joined(separator: " ")
    }
    
    private static func singularize(_ input: String) -> String {
        let word = input
        let exceptions: Set<String> = ["hummus", "couscous", "asparagus", "molasses", "chickpeas", "lentils", "oats", "greens", "herbs"]
        if exceptions.contains(word) { return word }
        let irregulars: [String: String] = [
            "tomatoes": "tomato", "potatoes": "potato", "mangoes": "mango",
            "chillies": "chilli", "chilies": "chili", "anchovies": "anchovy",
            "berries": "berry", "cherries": "cherry", "strawberries": "strawberry",
            "blueberries": "blueberry", "raspberries": "raspberry", "cranberries": "cranberry",
        ]
        if let irregular = irregulars[word] { return irregular }
        if word.hasSuffix("ies") && word.count > 4 { return String(word.dropLast(3)) + "y" }
        if word.hasSuffix("ves") { return String(word.dropLast(3)) + "f" }
        if word.hasSuffix("oes") && word.count > 4 { return String(word.dropLast(2)) }
        if word.hasSuffix("ses") || word.hasSuffix("ches") || word.hasSuffix("shes") || word.hasSuffix("xes") || word.hasSuffix("zes") { return String(word.dropLast(2)) }
        if word.hasSuffix("s") && !word.hasSuffix("ss") && word.count > 3 { return String(word.dropLast(1)) }
        return word
    }
}
