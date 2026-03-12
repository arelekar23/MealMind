//
//  RecipeListView.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/11/26.
//

import SwiftUI
import SwiftData

struct RecipeListView: View {
    @StateObject private var viewModel = RecipeViewModel()
    @State private var showAddRecipe = false
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query(sort: \KitchenItem.name) private var pantry: [KitchenItem]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("GradientBgStart"), Color("GradientBgEnd")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        Text("Find something to cook")
                            .font(.subheadline)
                            .foregroundStyle(Color("SecondaryText"))
                            .padding(.horizontal)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                CategoryPill(
                                    title: "All",
                                    isSelected: viewModel.selectedCategory == nil,
                                    action: { viewModel.selectedCategory = nil }
                                )
                                ForEach(MealCategory.allCases, id: \.self) { category in
                                    CategoryPill(
                                        title: category.displayName,
                                        isSelected: viewModel.selectedCategory == category,
                                        action: { viewModel.selectedCategory = category }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        let canCook = viewModel.canCookNow(with: pantry).filter { recipe in
                            viewModel.selectedCategory == nil || recipe.category == viewModel.selectedCategory
                        }
                        
                        if !canCook.isEmpty && viewModel.searchText.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "frying.pan.fill")
                                        .foregroundStyle(Color("AccentColor"))
                                    Text("Cook Now")
                                        .font(.headline)
                                        .foregroundStyle(Color("PrimaryText"))
                                    Spacer()
                                    Text("\(canCook.count) recipes")
                                        .font(.caption)
                                        .foregroundStyle(Color("SecondaryText"))
                                }
                                .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(canCook.prefix(6)) { recipe in
                                            NavigationLink(value: recipe) {
                                                CookNowCard(recipe: recipe, pantry: pantry)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.bottom, 8)
                        }
                        let columns = sizeClass == .regular
                        ? [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
                        : [GridItem(.flexible())]
                        
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(viewModel.filteredRecipes) { recipe in
                                NavigationLink(value: recipe) {
                                    RecipeCard(recipe: recipe)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Recipes")
            .searchable(text: $viewModel.searchText, prompt: "Search recipes, cuisines, tags...")
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe, viewModel: viewModel)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddRecipe = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color("AccentColor"))
                    }
                }
            }
            .sheet(isPresented: $showAddRecipe) {
                AddRecipeView { recipe in
                    viewModel.addRecipe(recipe)
                }
            }
        }
    }
}

struct CookNowCard: View {
    let recipe: Recipe
    let pantry: [KitchenItem]
    
    private let skipIngredients: Set<String> = ["water", "ice", "hot water", "cold water", "warm water", "boiling water"]
    
    private var relevantIngredients: [Ingredient] {
        recipe.ingredients.filter { !skipIngredients.contains($0.name.lowercased()) }
    }
    
    private var matchCount: Int {
        relevantIngredients.filter { ing in
            pantry.contains { IngredientMatcher.matches($0.name, ing.name) && $0.isAvailable }
        }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recipe.name)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(2)
            
            Text(recipe.cuisine)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("\(matchCount)/\(relevantIngredients.count) ingredients")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(12)
        .frame(width: 150, height: 120, alignment: .leading)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private var gradientColors: [Color] {
        switch recipe.category {
        case .breakfast: return [Color("GradientBreakfastStart"), Color("GradientBreakfastEnd")]
        case .mainMeal: return [Color("GradientMainStart"), Color("GradientMainEnd")]
        case .snack: return [Color("GradientSnackStart"), Color("GradientSnackEnd")]
        case .dessert: return [Color("GradientDessertStart"), Color("GradientDessertEnd")]
        }
    }
}

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color("AccentColor") : Color("PillBackground"))
                .foregroundStyle(isSelected ? .white : Color("PrimaryText"))
                .clipShape(Capsule())
        }
    }
}

struct RecipeCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.cuisine.uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text(recipe.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                Text(recipe.difficulty.displayName)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            VStack(alignment: .leading, spacing: 10) {
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundStyle(Color("AccentColor"))
                        Text("\(recipe.totalTime) min")
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .foregroundStyle(Color("AccentColor"))
                        Text("\(recipe.servings) servings")
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color("TertiaryText"))
                }
                .font(.caption)
                .foregroundStyle(Color("SecondaryText"))
                
                if !recipe.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(recipe.tags.prefix(4), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color("AccentColor").opacity(0.2))
                                .foregroundStyle(Color("AccentColor"))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
            .padding(16)
            .background(Color("CardBackground"))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color("CardShadow"), radius: 8, x: 0, y: 4)
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
}

#Preview {
    RecipeListView()
}
