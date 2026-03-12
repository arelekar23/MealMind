//
//  WeeklyPlanView.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/13/26.
//

import SwiftUI
import SwiftData

struct MealPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var meals: [PlannedMeal] = []
    @State private var selectedDate: Date = Date()
    @State private var viewMode: CalendarViewMode = .weekly
    @State private var showingAddMeal = false
    
    private var isSelectedDateInPast: Bool {
        Calendar.current.startOfDay(for: selectedDate) < Calendar.current.startOfDay(for: Date())
    }
    
    var selectedWeekday: Weekday {
        let cal = Calendar.current
        let idx = cal.component(.weekday, from: selectedDate)
        let mapping: [Int: Weekday] = [
            1: .sunday, 2: .monday, 3: .tuesday, 4: .wednesday,
            5: .thursday, 6: .friday, 7: .saturday
        ]
        return mapping[idx] ?? .monday
    }
    
    var mealsForSelectedDate: [PlannedMeal] {
        let cal = Calendar.current
        return meals.filter { cal.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var cookedCount: Int {
        meals.filter { $0.isCooked }.count
    }
    
    var currentWeekDates: [Date] {
        let cal = Calendar.current
        guard let week = cal.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: week.start) }
    }
    
    var currentMonthDates: [Date] {
        let cal = Calendar.current
        guard let month = cal.dateInterval(of: .month, for: selectedDate) else { return [] }
        let startWeekday = cal.component(.weekday, from: month.start)
        let offset = (startWeekday - cal.firstWeekday + 7) % 7
        let start = cal.date(byAdding: .day, value: -offset, to: month.start)!
        return (0..<42).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }
    
    func fetchMeals() {
        let descriptor = FetchDescriptor<PlannedMeal>()
        meals = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private var navTitle: String {
        switch viewMode {
        case .daily: return "Daily Plan"
        case .weekly: return "Weekly Plan"
        case .monthly: return "Monthly Plan"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("GradientBgStart"), Color("GradientBgEnd")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .ignoresSafeArea()
                VStack(spacing: 0) {
                    Picker("View", selection: $viewMode) {
                        ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    calendarNavigation
                    
                    switch viewMode {
                    case .daily:
                        dailyView
                    case .weekly:
                        weeklyView
                    case .monthly:
                        monthlyView
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    statsBar
                    mealsListSection
                }
                .navigationTitle(navTitle)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAddMeal = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .disabled(isSelectedDateInPast)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                clearAllMeals()
                            } label: {
                                Label("Clear All Meals", systemImage: "trash")
                            }
                            Button(role: .destructive) {
                                clearDayMeals()
                            } label: {
                                Label("Clear \(selectedWeekday.rawValue)", systemImage: "xmark.circle")
                            }
                            Button {
                                selectedDate = Date()
                            } label: {
                                Label("Go to Today", systemImage: "calendar")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .onAppear { fetchMeals() }
                .sheet(isPresented: $showingAddMeal) {
                    AddMealSheet(selectedDay: selectedWeekday, selectedDate: selectedDate)
                }
                .onChange(of: showingAddMeal) {
                    if !showingAddMeal { fetchMeals() }
                }
            }
        }
    }
    
    private var calendarNavigation: some View {
        HStack {
            Button {
                navigateBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
            }
            
            Spacer()
            
            Text(navigationTitle)
                .font(.headline)
            
            Spacer()
            
            Button {
                navigateForward()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var navigationTitle: String {
        let formatter = DateFormatter()
        switch viewMode {
        case .daily:
            formatter.dateFormat = "EEEE, MMM d"
        case .weekly:
            formatter.dateFormat = "MMM d"
            let start = currentWeekDates.first ?? selectedDate
            let end = currentWeekDates.last ?? selectedDate
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        case .monthly:
            formatter.dateFormat = "MMMM yyyy"
        }
        return formatter.string(from: selectedDate)
    }
    
    private var dailyView: some View {
        VStack {
            Text(selectedWeekday.rawValue)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.vertical, 8)
        }
    }
    
    private var weeklyView: some View {
        HStack(spacing: 4) {
            ForEach(currentWeekDates, id: \.self) { date in
                WeekDayCell(
                    date: date,
                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                    isToday: Calendar.current.isDateInToday(date),
                    hasMeals: hasMeals(for: date),
                    action: { selectedDate = date }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    private var monthlyView: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(currentMonthDates, id: \.self) { date in
                    MonthDayCell(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        isToday: Calendar.current.isDateInToday(date),
                        isCurrentMonth: Calendar.current.isDate(date, equalTo: selectedDate, toGranularity: .month),
                        hasMeals: hasMeals(for: date),
                        action: { selectedDate = date }
                    )
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 4)
    }
    
    private var statsBar: some View {
        HStack {
            Text("\(mealsForSelectedDate.count) meals planned")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(cookedCount)/\(meals.count) cooked")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private var mealsListSection: some View {
        Group {
            if mealsForSelectedDate.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: isSelectedDateInPast ? "clock.arrow.circlepath" : "fork.knife")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(isSelectedDateInPast
                         ? "Past date"
                         : "No meals for \(selectedWeekday.rawValue)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    Text(isSelectedDateInPast
                         ? "You can only plan meals for today or later"
                         : "Tap + to add a meal")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(MealSlots.defaults, id: \.self) { slot in
                            let slotMeals = mealsForSelectedDate.filter { $0.mealSlot == slot }
                            if !slotMeals.isEmpty {
                                MealSlotSection(
                                    title: slot,
                                    meals: slotMeals,
                                    onDelete: { meal in modelContext.delete(meal); fetchMeals() },
                                    onToggleCooked: { meal in
                                        meal.isCooked.toggle()
                                    }
                                )
                            }
                        }
                        
                        let customMeals = mealsForSelectedDate.filter { !MealSlots.defaults.contains($0.mealSlot) }
                        if !customMeals.isEmpty {
                            MealSlotSection(
                                title: "Other",
                                meals: customMeals,
                                onDelete: { meal in modelContext.delete(meal); fetchMeals() },
                                onToggleCooked: { meal in
                                    meal.isCooked.toggle()
                                    if meal.isCooked {
                                        deductIngredients(for: meal)
                                    } else {
                                        restoreIngredients(for: meal)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    private func hasMeals(for date: Date) -> Bool {
        let cal = Calendar.current
        return meals.contains { cal.isDate($0.date, inSameDayAs: date) }
    }
    
    private func navigateBack() {
        let cal = Calendar.current
        switch viewMode {
        case .daily:
            selectedDate = cal.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        case .weekly:
            selectedDate = cal.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
        case .monthly:
            selectedDate = cal.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        }
    }
    
    private func navigateForward() {
        let cal = Calendar.current
        switch viewMode {
        case .daily:
            selectedDate = cal.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        case .weekly:
            selectedDate = cal.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
        case .monthly:
            selectedDate = cal.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        }
    }
    
    private func deductIngredients(for meal: PlannedMeal) {
        let recipes = RecipeLoader.load()
        guard let recipe = recipes.first(where: { $0.id == meal.recipeId }) else { return }
        
        let descriptor = FetchDescriptor<KitchenItem>()
        guard let kitchenItems = try? modelContext.fetch(descriptor) else { return }
        
        let servingsPlanned = Double(meal.servingsPlanned)
        let ratio = meal.recipeServings > 0 ? servingsPlanned / Double(meal.recipeServings) : 1.0
        
        for ingredient in recipe.ingredients {
            if let item = IngredientMatcher.findMatch(for: ingredient.name, in: kitchenItems) {
                if item.type == .countable {
                    let deduction = Int(ceil(ingredient.quantity * ratio))
                    item.count = max(0, item.count - deduction)
                }
            }
        }
    }
    
    private func restoreIngredients(for meal: PlannedMeal) {
        let recipes = RecipeLoader.load()
        guard let recipe = recipes.first(where: { $0.id == meal.recipeId }) else { return }
        
        let descriptor = FetchDescriptor<KitchenItem>()
        guard let kitchenItems = try? modelContext.fetch(descriptor) else { return }
        
        let servingsPlanned = Double(meal.servingsPlanned)
        let ratio = meal.recipeServings > 0 ? servingsPlanned / Double(meal.recipeServings) : 1.0
        
        for ingredient in recipe.ingredients {
            if let item = IngredientMatcher.findMatch(for: ingredient.name, in: kitchenItems) {
                if item.type == .countable {
                    let restoration = Int(ceil(ingredient.quantity * ratio))
                    item.count += restoration
                }
            }
        }
    }
    private func clearAllMeals() {
        for meal in meals { modelContext.delete(meal) }
        fetchMeals()
    }
    
    private func clearDayMeals() {
        for meal in mealsForSelectedDate { modelContext.delete(meal) }
        fetchMeals()
    }
}

enum CalendarViewMode: String, CaseIterable {
    case daily = "Day"
    case weekly = "Week"
    case monthly = "Month"
}

struct WeekDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasMeals: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayLetter)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .secondary)
                
                Text(dayNumber)
                    .font(.callout)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isSelected ? .white : (isToday ? .accentColor : .primary))
                
                if hasMeals {
                    Circle()
                        .fill(isSelected ? .white : .accentColor)
                        .frame(width: 5, height: 5)
                } else {
                    Circle()
                        .fill(.clear)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : (isToday ? Color.accentColor.opacity(0.1) : Color.clear))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private var dayLetter: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return fmt.string(from: date)
    }
    
    private var dayNumber: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d"
        return fmt.string(from: date)
    }
}

struct MonthDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let hasMeals: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(.caption)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(textColor)
                
                if hasMeals {
                    Circle()
                        .fill(isSelected ? .white : .accentColor)
                        .frame(width: 4, height: 4)
                } else {
                    Circle()
                        .fill(.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : (isToday ? Color.accentColor.opacity(0.1) : Color.clear))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var dayNumber: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d"
        return fmt.string(from: date)
    }
    
    private var textColor: Color {
        if isSelected { return .white }
        if !isCurrentMonth { return .secondary.opacity(0.3) }
        if isToday { return .accentColor }
        return .primary
    }
}

struct MealSlotSection: View {
    let title: String
    let meals: [PlannedMeal]
    let onDelete: (PlannedMeal) -> Void
    let onToggleCooked: (PlannedMeal) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            
            ForEach(meals) { meal in
                MealCard(meal: meal, onDelete: {
                    onDelete(meal)
                }, onToggleCooked: {
                    onToggleCooked(meal)
                })
            }
        }
    }
}

struct MealCard: View {
    @Bindable var meal: PlannedMeal
    let onDelete: () -> Void
    let onToggleCooked: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggleCooked) {
                Image(systemName: meal.isCooked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(meal.isCooked ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.recipeName)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(meal.isCooked, color: .gray)
                    .foregroundStyle(meal.isCooked ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    Text(meal.mealSlot)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("\(meal.servingsPlanned) of \(meal.recipeServings) servings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

struct AddMealSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let selectedDay: Weekday
    let selectedDate: Date
    @State private var selectedSlotIndex: Int = 0
    @State private var customSlot: String = ""
    @State private var useCustomSlot = false
    @State private var searchText = ""
    @State private var allRecipes: [Recipe] = []
    @State private var servingsPlanned: Int = 1
    @State private var addedMealIds: Set<String> = []
    @State private var showAddedToast = false
    @State private var lastAddedName = ""
    
    var currentSlot: String {
        useCustomSlot ? customSlot : MealSlots.defaults[selectedSlotIndex]
    }
    
    var filteredRecipes: [Recipe] {
        var result = allRecipes
        
        let slot = currentSlot
        result = result.filter { recipe in
            !addedMealIds.contains("\(slot)|\(recipe.id)")
        }
        
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.cuisine.lowercased().contains(query)
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                slotPickerSection
                Divider()
                searchBarSection
                recipeListSection
            }
            .navigationTitle("Add Meals — \(selectedDay.shortName)")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                allRecipes = RecipeLoader.load()
                loadExistingMeals()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay(alignment: .bottom) {
                if showAddedToast {
                    Text("Added \(lastAddedName) to \(currentSlot)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .shadow(radius: 4)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
    
    private var slotPickerSection: some View {
        VStack(spacing: 12) {
            if useCustomSlot {
                TextField("Custom slot name", text: $customSlot)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
            } else {
                Picker("Slot", selection: $selectedSlotIndex) {
                    ForEach(0..<MealSlots.defaults.count, id: \.self) { index in
                        Text(MealSlots.defaults[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
            
            Toggle("Custom slot", isOn: $useCustomSlot)
                .padding(.horizontal)
            
            Stepper("Servings: \(servingsPlanned)", value: $servingsPlanned, in: 1...10)
                .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }
    
    private var searchBarSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search recipes...", text: $searchText)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var recipeListSection: some View {
        ScrollView {
            if filteredRecipes.isEmpty {
                VStack(spacing: 8) {
                    Text("Recipe not found. Try a different search.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredRecipes, id: \.id) { recipe in
                        RecipeRow(recipe: recipe) { addMeal(recipe: recipe) }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func addMeal(recipe: Recipe) {
        let slot = currentSlot
        guard !slot.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let meal = PlannedMeal(
            recipeId: recipe.id,
            recipeName: recipe.name,
            day: selectedDay,
            mealSlot: slot,
            servingsPlanned: servingsPlanned,
            recipeServings: recipe.servings,
            date: selectedDate
        )
        modelContext.insert(meal)
        
        addedMealIds.insert("\(slot)|\(recipe.id)")
        
        lastAddedName = recipe.name
        withAnimation { showAddedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showAddedToast = false }
        }
    }
    
    private func loadExistingMeals() {
        let descriptor = FetchDescriptor<PlannedMeal>()
        let existingMeals = (try? modelContext.fetch(descriptor)) ?? []
        let cal = Calendar.current
        
        for meal in existingMeals where cal.isDate(meal.date, inSameDayAs: selectedDate) {
            addedMealIds.insert("\(meal.mealSlot)|\(meal.recipeId)")
        }
    }
}

struct RecipeRow: View {
    let recipe: Recipe
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(recipe.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text("\(recipe.cuisine) · \(recipe.totalTime) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.blue)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MealPlanView()
        .modelContainer(for: [KitchenItem.self, PlannedMeal.self], inMemory: true)
}
