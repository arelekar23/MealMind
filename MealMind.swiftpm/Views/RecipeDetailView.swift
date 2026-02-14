//
//  RecipeDetailView.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/12/26.
//

import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.cuisine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(recipe.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Tags
                    HStack(spacing: 6) {
                        ForEach(recipe.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                .padding(.horizontal)
                
                // MARK: - Info Cards
                HStack(spacing: 12) {
                    InfoCard(icon: "clock", label: "Time", value: "\(recipe.totalTime) min")
                    InfoCard(icon: "flame", label: "Calories", value: "\(recipe.calories)")
                    InfoCard(icon: "person.2", label: "Servings", value: "\(recipe.servings)")
                    InfoCard(icon: "chart.bar", label: "Level", value: recipe.difficulty.displayName)
                }
                .padding(.horizontal)
                
                // MARK: - Ingredients
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ingredients")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                            HStack {
                                Text(ingredient.name.capitalized)
                                    .font(.body)
                                
                                Spacer()
                                
                                Text(ingredientQuantityText(ingredient))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(index % 2 == 0 ? Color(.systemGray6) : Color.clear)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                
                // MARK: - Steps
                VStack(alignment: .leading, spacing: 12) {
                    Text("Steps")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Color.accentColor)
                                    .clipShape(Circle())
                                
                                Text(step)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // MARK: - Tips
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tips")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                            .font(.title3)
                        
                        Text(recipe.tips)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                
                // MARK: - Add to Plan Button
                Button {
                    // TODO: Add to weekly plan
                } label: {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Add to Weekly Plan")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .padding(.top)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helper
    private func ingredientQuantityText(_ ingredient: Ingredient) -> String {
        let qty = ingredient.quantity
        if qty == floor(qty) {
            return "\(Int(qty)) \(ingredient.unit)"
        }
        return "\(qty) \(ingredient.unit)"
    }
}

// MARK: - Info Card
struct InfoCard: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(recipe: RecipeLoader.load().first!)
    }
}
