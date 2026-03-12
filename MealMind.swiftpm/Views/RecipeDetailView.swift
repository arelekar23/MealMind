//
//  RecipeDetailView.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/12/26.
//

import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    var viewModel: RecipeViewModel?
    var onDelete: (() -> Void)?
    
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var showAddToPlan = false
    @Environment(\.dismiss) private var dismiss
    
    private var isUserRecipe: Bool {
        viewModel?.isUserRecipe(recipe) ?? false
    }
    
    private var gradientColors: [Color] {
        switch recipe.category {
        case .breakfast:
            return [Color("GradientBreakfastStart"), Color("GradientBreakfastEnd")]
        case .mainMeal:
            return [Color("GradientMainStart"), Color("GradientMainEnd")]
        case .snack:
            return [Color("GradientSnackStart"), Color("GradientSnackEnd")]
        case .dessert:
            return [Color("GradientDessertStart"), Color("GradientDessertEnd")]
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recipe.cuisine.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.7))
                        
                        Text(recipe.name)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                        
                        if !recipe.tags.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(recipe.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(.white.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 6)
                    
                    HStack(spacing: 12) {
                        InfoCard(icon: "clock", label: "Time", value: "\(recipe.totalTime) min")
                        InfoCard(icon: "person.2", label: "Servings", value: "\(recipe.servings)")
                        InfoCard(icon: "chart.bar", label: "Level", value: recipe.difficulty.displayName)
                    }
                    .padding(.horizontal, 18)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingredients")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        VStack(spacing: 0) {
                            ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                                HStack(alignment: .firstTextBaseline) {
                                    Text(ingredient.name.capitalized)
                                        .font(.body)
                                        .foregroundStyle(.white)
                                    
                                    Spacer()
                                    
                                    Text(ingredientQuantityText(ingredient))
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                
                                if index != recipe.ingredients.count - 1 {
                                    Divider()
                                        .background(.white.opacity(0.2))
                                }
                            }
                        }
                        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .glassSection()
                    .padding(.horizontal, 18)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Steps")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        if !recipe.steps.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("\(index + 1)")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                            .frame(width: 28, height: 28)
                                            .background(.white.opacity(0.2), in: Circle())
                                            .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                                        
                                        Text(step)
                                            .font(.body)
                                            .foregroundStyle(.white.opacity(0.9))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 2)
                        } else {
                            HStack(spacing: 10) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .foregroundStyle(.white.opacity(0.6))
                                    .font(.title3)
                                Text("No steps added yet. Cook it your way!")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .glassSection()
                    .padding(.horizontal, 18)
                    
                    if !recipe.tips.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tips")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.title3)
                                Text(recipe.tips)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .glassSection()
                        .padding(.horizontal, 18)
                    }
                    
                    Button {
                        showAddToPlan = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "calendar.badge.plus")
                            Text("Add to Meal Plan")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 4)
                    .padding(.bottom, 26)
                }
                .padding(.top, 10)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            if isUserRecipe {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { showEditSheet = true } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) { showDeleteAlert = true } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let viewModel {
                EditRecipeView(recipe: recipe) { updated in
                    viewModel.updateRecipe(updated)
                }
            }
        }
        .sheet(isPresented: $showAddToPlan) {
            QuickAddToPlanSheet(recipe: recipe)
        }
        .alert("Delete Recipe", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel?.deleteRecipe(recipe)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \"\(recipe.name)\"? This can't be undone.")
        }
    }
    
    private func ingredientQuantityText(_ ingredient: Ingredient) -> String {
        let qty = ingredient.quantity
        if qty == floor(qty) {
            return "\(Int(qty)) \(ingredient.unit)"
        }
        return "\(qty) \(ingredient.unit)"
    }
}

struct InfoCard: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
                .padding(10)
                .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct QuickAddToPlanSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe
    @State private var selectedDate = Date()
    @State private var selectedSlotIndex = 0
    @State private var servings = 1
    
    private var selectedWeekday: Weekday {
        let idx = Calendar.current.component(.weekday, from: selectedDate)
        let mapping: [Int: Weekday] = [
            1: .sunday, 2: .monday, 3: .tuesday, 4: .wednesday,
            5: .thursday, 6: .friday, 7: .saturday
        ]
        return mapping[idx] ?? .monday
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    DatePicker("Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                    Picker("Meal", selection: $selectedSlotIndex) {
                        ForEach(0..<MealSlots.defaults.count, id: \.self) { i in
                            Text(MealSlots.defaults[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Servings") {
                    Stepper("\(servings)", value: $servings, in: 1...10)
                }
            }
            .navigationTitle("Add to Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let meal = PlannedMeal(
                            recipeId: recipe.id, recipeName: recipe.name,
                            day: selectedWeekday,
                            mealSlot: MealSlots.defaults[selectedSlotIndex],
                            servingsPlanned: servings, recipeServings: recipe.servings,
                            date: Calendar.current.startOfDay(for: selectedDate)
                        )
                        modelContext.insert(meal)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private extension View {
    func glassSection() -> some View {
        self
            .padding(16)
            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
    }
}

#Preview {
    let recipes = RecipeLoader.load()
    return NavigationStack {
        RecipeDetailView(recipe: recipes[58])
    }
}
