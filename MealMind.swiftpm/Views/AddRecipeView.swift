//
//  AddRecipeView.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/23/26.
//

import SwiftUI

struct AddRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var onSave: (Recipe) -> Void
    
    @State private var name = ""
    @State private var ingredients: [Ingredient] = []
    @State private var showAddIngredient = false
    @State private var editingIndex: Int? = nil
    
    @State private var showDetails = false
    @State private var cuisine = ""
    @State private var category: MealCategory = .mainMeal
    @State private var difficulty: Difficulty = .easy
    @State private var prepTime = 10
    @State private var cookTime = 15
    @State private var servings = 2
    @State private var tags: [String] = []
    @State private var tagText = ""
    @State private var steps: [String] = []
    @State private var stepText = ""
    @State private var tips = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe Name") {
                    TextField("e.g. Aloo Gobi, Pasta Salad", text: $name)
                }
                
                Section {
                    ForEach(Array(ingredients.enumerated()), id: \.offset) { i, ing in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ing.name.capitalized)
                                    .font(.body.weight(.medium))
                                Text("\(formatQty(ing.quantity)) \(ing.unit)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(ing.category.displayName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { editingIndex = i }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                ingredients.remove(at: i)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    
                    Button {
                        showAddIngredient = true
                    } label: {
                        Label("Add Ingredient", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Ingredients")
                } footer: {
                    if !ingredients.isEmpty {
                        Text("Tap to edit, swipe to delete")
                    }
                }
                
                Section {
                    Toggle("Add more details", isOn: $showDetails.animation())
                } footer: {
                    Text("Optional: cuisine, steps, timing, tags")
                }
                
                if showDetails {
                    Section("Details") {
                        TextField("Cuisine (e.g. Indian, Italian)", text: $cuisine)
                        Picker("Category", selection: $category) {
                            ForEach(MealCategory.allCases, id: \.self) { Text($0.displayName).tag($0) }
                        }
                        Picker("Difficulty", selection: $difficulty) {
                            ForEach(Difficulty.allCases, id: \.self) { Text($0.displayName).tag($0) }
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
                            }
                        }
                        .onDelete { steps.remove(atOffsets: $0) }
                        
                        HStack {
                            TextField("Add a step...", text: $stepText)
                                .onSubmit { addStep() }
                            Button { addStep() } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            .disabled(stepText.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    } header: {
                        Text("Steps (optional)")
                    }
                    
                    Section {
                        FlowLayout(spacing: 6) {
                            ForEach(tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                    Button { tags.removeAll { $0 == tag } } label: {
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
                            TextField("Add tag (e.g. quick, spicy)", text: $tagText)
                                .onSubmit { addTag() }
                            Button { addTag() } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            .disabled(tagText.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    } header: {
                        Text("Tags (optional)")
                    }
                    
                    Section("Tips (optional)") {
                        TextField("Any cooking tips...", text: $tips, axis: .vertical)
                            .lineLimit(2...4)
                    }
                }
            }
            .navigationTitle("Add Recipe")
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
            .sheet(isPresented: $showAddIngredient) {
                IngredientFormSheet { ingredient in
                    ingredients.append(ingredient)
                }
            }
            .sheet(item: $editingIndex) { index in
                IngredientFormSheet(existing: ingredients[index]) { updated in
                    ingredients[index] = updated
                }
            }
        }
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
        let recipe = Recipe(
            id: UUID(),
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
            tips: tips.isEmpty ? "Enjoy your meal!" : tips,
            image: ""
        )
        onSave(recipe)
        dismiss()
    }
    
    private func formatQty(_ qty: Double) -> String {
        qty == floor(qty) ? "\(Int(qty))" : String(format: "%.1f", qty)
    }
}

enum IngredientUnit: String, CaseIterable {
    case pcs = "pcs"
    case tsp = "tsp"
    case tbsp = "tbsp"
    case cup = "cup"
    case ml = "ml"
    case ltr = "ltr"
    case gm = "gm"
    case kg = "kg"
    case pinch = "pinch"
    case asNeeded = "as needed"
    
    var display: String {
        switch self {
        case .pcs: return "Pieces"
        case .tsp: return "Teaspoon"
        case .tbsp: return "Tablespoon"
        case .cup: return "Cup"
        case .ml: return "ml"
        case .ltr: return "Litre"
        case .gm: return "Grams"
        case .kg: return "Kg"
        case .pinch: return "Pinch"
        case .asNeeded: return "As needed"
        }
    }
}

struct IngredientFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var existing: Ingredient? = nil
    var onSave: (Ingredient) -> Void
    
    @State private var name = ""
    @State private var quantity: Double = 1
    @State private var unit: IngredientUnit = .pcs
    @State private var category: IngredientCategory = .vegetable
    @State private var type: IngredientType = .countable
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Ingredient") {
                    TextField("Name (e.g. tomato, cumin)", text: $name)
                        .autocorrectionDisabled()
                        .onChange(of: name) {
                            if existing == nil && !name.isEmpty {
                                let classified = IngredientClassifier.classify(name.lowercased())
                                category = classified.category
                                type = classified.type
                                if type == .bulk && unit == .pcs {
                                    unit = .asNeeded
                                }
                            }
                        }
                }
                
                Section("Quantity") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        HStack(spacing: 16) {
                            Button {
                                if quantity > 0.25 { quantity -= 0.25 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(quantity > 0.25 ? .red : .gray.opacity(0.3))
                            }
                            .buttonStyle(.plain)
                            .disabled(quantity <= 0.25)
                            
                            Text(formatQty(quantity))
                                .font(.headline)
                                .frame(minWidth: 40)
                            
                            Button {
                                quantity += 0.25
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.green)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Picker("Unit", selection: $unit) {
                        ForEach(IngredientUnit.allCases, id: \.self) { u in
                            Text(u.display).tag(u)
                        }
                    }
                }
                
                Section("Classification") {
                    Picker("Category", selection: $category) {
                        ForEach(IngredientCategory.allCases, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    
                    Picker("Type", selection: $type) {
                        Text("Countable").tag(IngredientType.countable)
                        Text("Bulk").tag(IngredientType.bulk)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(existing == nil ? "Add Ingredient" : "Edit Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existing == nil ? "Add" : "Update") {
                        let ingredient = Ingredient(
                            name: name.trimmingCharacters(in: .whitespaces).capitalized,
                            quantity: quantity,
                            unit: unit.rawValue,
                            category: category,
                            type: type
                        )
                        onSave(ingredient)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let existing {
                    name = existing.name
                    quantity = existing.quantity
                    unit = IngredientUnit(rawValue: existing.unit) ?? .pcs
                    category = existing.category
                    type = existing.type
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func formatQty(_ qty: Double) -> String {
        if qty == floor(qty) { return "\(Int(qty))" }
        if qty == 0.25 { return "¼" }
        if qty == 0.5 { return "½" }
        if qty == 0.75 { return "¾" }
        let whole = Int(qty)
        let frac = qty - Double(whole)
        if frac == 0.25 { return "\(whole)¼" }
        if frac == 0.5 { return "\(whole)½" }
        if frac == 0.75 { return "\(whole)¾" }
        return String(format: "%.1f", qty)
    }
}

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (i, pos) in result.positions.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}

#Preview {
    AddRecipeView { recipe in
        print("Saved: \(recipe.name)")
    }
}
