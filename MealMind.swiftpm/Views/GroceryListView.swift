//
//  GroceryListView.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/15/26.
//

import SwiftUI
import SwiftData

struct GroceryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var meals: [PlannedMeal]
    @Query(sort: \KitchenItem.name) private var pantry: [KitchenItem]
    @Query(sort: \GroceryItem.name) private var allGroceryItems: [GroceryItem]
    
    @State private var startDate = Calendar.current.startOfDay(for: Date())
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 6, to: Date()) ?? Date()
    @State private var showInStock = false
    @State private var showDatePicker = false
    @State private var showAddToPantry = false
    
    private var groceryItems: [GroceryItem] {
        allGroceryItems.filter { !$0.isRemoved }
    }
    
    private var filteredItems: [GroceryItem] {
        showInStock ? groceryItems : groceryItems.filter { !$0.isFullyCovered }
    }
    
    private var groupedByCategory: [(category: IngredientCategory, items: [GroceryItem])] {
        let dict = Dictionary(grouping: filteredItems) { $0.category }
        return IngredientCategory.allCases.compactMap { cat in
            guard let items = dict[cat], !items.isEmpty else { return nil }
            return (category: cat, items: items)
        }
    }
    
    private var neededCount: Int {
        groceryItems.filter { !$0.isFullyCovered && !$0.isChecked }.count
    }
    
    private var checkedCount: Int {
        groceryItems.filter { $0.isChecked }.count
    }
    
    private var checkedItems: [GroceryItem] {
        groceryItems.filter { $0.isChecked }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [Color("GradientBgStart"), Color("GradientBgEnd")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .ignoresSafeArea()
                VStack(spacing: 0) {
                    dateRangeBar
                    Divider()
                    statsBar
                    inStockToggle
                    groceryList
                }
                
                if checkedCount > 0 {
                    Button {
                        showAddToPantry = true
                    } label: {
                        HStack {
                            Image(systemName: "cart.badge.plus")
                            Text("Add \(checkedCount) items to Pantry")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: checkedCount)
            .navigationTitle("Grocery List")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            for item in groceryItems { item.isChecked = false }
                        } label: {
                            Label("Uncheck All", systemImage: "arrow.uturn.backward")
                        }
                        Button {
                            for item in allGroceryItems where item.isRemoved { item.isRemoved = false }
                        } label: {
                            Label("Restore Removed Items", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear { rebuildList() }
            .onChange(of: meals.count) { rebuildList() }
            .onChange(of: pantry.count) { rebuildList() }
            .sheet(isPresented: $showDatePicker) {
                DateRangeSheet(
                    startDate: $startDate,
                    endDate: $endDate,
                    onApply: { rebuildList() }
                )
            }
            .sheet(isPresented: $showAddToPantry) {
                BulkAddToPantrySheet(
                    items: checkedItems,
                    onConfirm: { finalItems in
                        addAllToPantry(finalItems)
                        for item in groceryItems where item.isChecked {
                            item.isChecked = false
                        }
                    }
                )
            }
        }
    }
    
    private var dateRangeBar: some View {
        Button { showDatePicker = true } label: {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Shopping for")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(dateRangeText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                Spacer()
                HStack(spacing: 8) {
                    PresetButton(title: "This Week") { setThisWeek() }
                    PresetButton(title: "Next 3 Days") { setNextDays(3) }
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
    
    private var dateRangeText: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: startDate)) – \(fmt.string(from: endDate))"
    }
    
    private var statsBar: some View {
        HStack {
            Text("\(neededCount) items to buy")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if checkedCount > 0 {
                Text("\(checkedCount) selected")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inStockToggle: some View {
        Toggle("Show items already in stock", isOn: $showInStock)
            .font(.caption)
            .padding(.horizontal)
            .padding(.bottom, 4)
    }
    
    private var groceryList: some View {
        Group {
            if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "cart")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No groceries needed")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Plan some meals first, then come back here")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding(.horizontal)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(groupedByCategory, id: \.category) { group in
                            GroceryCategorySection(
                                category: group.category,
                                items: group.items,
                                onToggle: { item in toggleItem(item) },
                                onRemove: { item in removeItem(item) }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, checkedCount > 0 ? 80 : 20)
                }
            }
        }
    }
    
    private func rebuildList() {
        GroceryListBuilder.rebuild(
            meals: meals,
            pantry: pantry,
            existing: allGroceryItems,
            startDate: startDate,
            endDate: endDate,
            context: modelContext
        )
    }
    
    private func toggleItem(_ item: GroceryItem) {
        item.isChecked.toggle()
    }
    
    private func removeItem(_ item: GroceryItem) {
        withAnimation {
            item.isRemoved = true
        }
    }
    
    private func addAllToPantry(_ items: [PantryAddItem]) {
        for item in items {
            let key = item.name.lowercased()
            if let existing = pantry.first(where: { $0.name.lowercased() == key }) {
                if item.type == .countable {
                    existing.count += item.count
                } else {
                    existing.stockLevel = item.stockLevel
                }
            } else {
                let newItem = KitchenItem(
                    name: item.name,
                    category: item.category,
                    type: item.type,
                    count: item.type == .countable ? item.count : 0,
                    stockLevel: item.type == .bulk ? item.stockLevel : .out
                )
                modelContext.insert(newItem)
            }
        }
    }
    
    private func setThisWeek() {
        let cal = Calendar.current
        guard let week = cal.dateInterval(of: .weekOfYear, for: Date()) else { return }
        startDate = week.start
        endDate = cal.date(byAdding: .day, value: 6, to: week.start) ?? Date()
        rebuildList()
    }
    
    private func setNextDays(_ n: Int) {
        startDate = Calendar.current.startOfDay(for: Date())
        endDate = Calendar.current.date(byAdding: .day, value: n - 1, to: startDate) ?? Date()
        rebuildList()
    }
}

struct PantryAddItem: Identifiable {
    let id = UUID()
    var name: String
    var category: IngredientCategory
    var type: IngredientType
    var count: Int
    var stockLevel: StockLevel
}

struct BulkAddToPantrySheet: View {
    let items: [GroceryItem]
    let onConfirm: ([PantryAddItem]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var editableItems: [PantryAddItem] = []
    
    var body: some View {
        NavigationStack {
            List {
                ForEach($editableItems) { $item in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name.capitalized)
                            .font(.body.weight(.medium))
                        
                        HStack {
                            Picker("Type", selection: $item.type) {
                                Text("Countable").tag(IngredientType.countable)
                                Text("Bulk").tag(IngredientType.bulk)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 180)
                            
                            Spacer()
                            
                            if item.type == .countable {
                                HStack(spacing: 12) {
                                    Button {
                                        if item.count > 1 { item.count -= 1 }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(item.count > 1 ? .red : .gray.opacity(0.3))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(item.count <= 1)
                                    
                                    Text("\(item.count)")
                                        .font(.headline)
                                        .frame(minWidth: 24)
                                    
                                    Button {
                                        item.count += 1
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.green)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                Picker("", selection: $item.stockLevel) {
                                    ForEach(StockLevel.allCases, id: \.self) { level in
                                        Text(level.displayName).tag(level)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indices in
                    editableItems.remove(atOffsets: indices)
                }
            }
            .navigationTitle("Add to Pantry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add All") {
                        onConfirm(editableItems)
                        dismiss()
                    }
                    .disabled(editableItems.isEmpty)
                }
            }
            .onAppear {
                editableItems = items.map { item in
                    PantryAddItem(
                        name: item.name,
                        category: item.category,
                        type: item.type,
                        count: item.type == .countable ? max(Int(ceil(item.netQuantity)), 1) : 0,
                        stockLevel: .full
                    )
                }
            }
        }
    }
}

struct GroceryCategorySection: View {
    let category: IngredientCategory
    let items: [GroceryItem]
    let onToggle: (GroceryItem) -> Void
    let onRemove: (GroceryItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            
            ForEach(items) { item in
                GroceryItemRow(
                    item: item,
                    onToggle: { onToggle(item) },
                    onRemove: { onRemove(item) }
                )
            }
        }
    }
}

struct GroceryItemRow: View {
    let item: GroceryItem
    let onToggle: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isChecked ? .green : (item.isFullyCovered ? .blue : .gray))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(item.isChecked, color: .gray)
                    .foregroundStyle(item.isChecked ? .secondary : .primary)
                
                if item.isFullyCovered {
                    Text("Already in pantry")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else if item.pantryCount > 0 {
                    Text("Have \(item.pantryCount), need \(item.displayQuantity) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if !item.isFullyCovered {
                Text(item.displayQuantity)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(item.isChecked ? .secondary : .primary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        .opacity(item.isChecked ? 0.7 : 1.0)
        .contextMenu {
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Remove from list", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
}

struct PresetButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
        }
    }
}

struct DateRangeSheet: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("From") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                Section("To") {
                    DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
            }
            .navigationTitle("Select Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    GroceryListView()
        .modelContainer(for: [KitchenItem.self, PlannedMeal.self], inMemory: true)
}
