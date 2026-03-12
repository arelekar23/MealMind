//
//  EditRecipeView.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/23/26.
//

import SwiftUI

struct EditRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    
    let recipe: Recipe
    var onSave: (Recipe) -> Void
    
    @State private var name: String
    @State private var cuisine: String
    @State private var category: MealCategory
    @State private var difficulty: Difficulty
    @State private var prepTime: Int
    @State private var cookTime: Int
    @State private var servings: Int
    @State private var tags: [String]
    @State private var ingredients: [Ingredient]
    @State private var steps: [String]
    @State private var tips: String
    
    @State private var ingredientText = ""
    @State private var stepText = ""
    @State private var tagText = ""
    @State private var editingIngredientIndex: Int? = nil
    
    init(recipe: Recipe, onSave: @escaping (Recipe) -> Void) {
        self.recipe = recipe
        self.onSave = onSave
        _name = State(initialValue: recipe.name)
        _cuisine = State(initialValue: recipe.cuisine)
        _category = State(initialValue: recipe.category)
        _difficulty = State(initialValue: recipe.difficulty)
        _prepTime = State(initialValue: recipe.prepTime)
        _cookTime = State(initialValue: recipe.cookTime)
        _servings = State(initialValue: recipe.servings)
        _tags = State(initialValue: recipe.tags)
        _ingredients = State(initialValue: recipe.ingredients)
        _steps = State(initialValue: recipe.steps)
        _tips = State(initialValue: recipe.tips)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe Name") {
                    TextField("Recipe name", text: $name)
                }
                
                Section {
                    ForEach(Array(ingredients.enumerated()), id: \.offset) { i, ing in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(ing.name.capitalized)
                                    .font(.body)
                                Text("\(formatQty(ing.quantity)) \(ing.unit)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(ing.category.displayName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                ingredients.remove(at: i)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                ingredientText = "\(formatQty(ing.quantity)) \(ing.name)"
                                ingredients.remove(at: i)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                    
                    HStack {
                        TextField("e.g. 2 tomatoes", text: $ingredientText)
                            .onSubmit { addIngredient() }
                        Button {
                            addIngredient()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .disabled(ingredientText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Ingredients")
                } footer: {
                    Text("Swipe right to edit, left to delete")
                }
                
                Section("Details") {
                    TextField("Cuisine", text: $cuisine)
                    
                    Picker("Category", selection: $category) {
                        ForEach(MealCategory.allCases, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(Difficulty.allCases, id: \.self) { diff in
                            Text(diff.displayName).tag(diff)
                        }
                    }
                    
                    Stepper("Prep: \(prepTime) min", value: $prepTime, in: 0...180, step: 5)
                    Stepper("Cook: \(cookTime) min", value: $cookTime, in: 0...180, step: 5)
                    Stepper("Servings: \(servings)", value: $servings, in: 1...20)
                }
                
                Section {
                    ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .top) {
                            Text("\(i + 1).")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                            Text(step)
                                .font(.body)
                        }
                    }
                    .onDelete { steps.remove(atOffsets: $0) }
                    
                    HStack {
                        TextField("Add a step...", text: $stepText)
                            .onSubmit { addStep() }
                        Button {
                            addStep()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .disabled(stepText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Steps")
                }
                
                Section {
                    FlowLayout(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                Button {
                                    tags.removeAll { $0 == tag }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption2)
                                }
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    
                    HStack {
                        TextField("Add tag", text: $tagText)
                            .onSubmit { addTag() }
                        Button {
                            addTag()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .disabled(tagText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Tags")
                }
                
                Section("Tips") {
                    TextField("Cooking tips...", text: $tips, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveRecipe() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || ingredients.isEmpty)
                }
            }
        }
    }
    
    private func addIngredient() {
        let text = ingredientText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let parsed = IngredientParser.parse(text)
        let ingName = parsed.name.isEmpty ? text : parsed.name
        
        if let existingIndex = ingredients.firstIndex(where: {
            $0.name.lowercased() == ingName.lowercased() ||
            IngredientMatcher.matches($0.name, ingName)
        }) {
            let existing = ingredients[existingIndex]
            ingredients[existingIndex] = Ingredient(
                name: existing.name,
                quantity: existing.quantity + Double(parsed.count),
                unit: existing.unit,
                category: existing.category,
                type: existing.type
            )
        } else {
            ingredients.append(Ingredient(
                name: ingName,
                quantity: Double(parsed.count),
                unit: parsed.type == .bulk ? "as needed" : "pcs",
                category: parsed.category,
                type: parsed.type
            ))
        }
        ingredientText = ""
    }
    
    private func addStep() {
        let text = stepText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        steps.append(text)
        stepText = ""
    }
    
    private func addTag() {
        let text = tagText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !text.isEmpty, !tags.contains(text) else { return }
        tags.append(text)
        tagText = ""
    }
    
    private func saveRecipe() {
        let updated = Recipe(
            id: recipe.id,
            name: name.trimmingCharacters(in: .whitespaces),
            cuisine: cuisine.isEmpty ? "Homemade" : cuisine,
            category: category,
            difficulty: difficulty,
            prepTime: prepTime,
            cookTime: cookTime,
            servings: servings,
            tags: tags,
            ingredients: ingredients,
            steps: steps,
            tips: tips,
            image: recipe.image
        )
        onSave(updated)
        dismiss()
    }
    
    private func formatQty(_ qty: Double) -> String {
        qty == floor(qty) ? "\(Int(qty))" : "\(qty)"
    }
}
