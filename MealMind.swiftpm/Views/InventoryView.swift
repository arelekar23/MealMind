//
//  InventoryView.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/12/26.
//

import SwiftUI
import SwiftData

struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var items: [KitchenItem] = []
    @State private var searchText = ""
    @State private var selectedCategory: IngredientCategory? = nil
    @State private var showingAddItem = false
    @State private var editingItem: KitchenItem? = nil
    
    var filteredItems: [KitchenItem] {
        var result = items
        
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { $0.name.lowercased().contains(query) }
        }
        
        return result
    }
    
    var availableCount: Int {
        items.filter { $0.isAvailable }.count
    }
    
    func fetchItems() {
        let descriptor = FetchDescriptor<KitchenItem>(sortBy: [SortDescriptor(\.name)])
        items = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // MARK: - Subtitle
                        Text("\(availableCount) of \(items.count) items available")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        // MARK: - Category Filter Pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                CategoryPill(
                                    title: "All",
                                    isSelected: selectedCategory == nil,
                                    action: { selectedCategory = nil }
                                )
                                ForEach(IngredientCategory.allCases, id: \.self) { category in
                                    CategoryPill(
                                        title: category.displayName,
                                        isSelected: selectedCategory == category,
                                        action: { selectedCategory = category }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // MARK: - Kitchen Items
                        if filteredItems.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "refrigerator")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                Text("Your pantry is empty")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Text("Tap + to add items you have at home")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(filteredItems) { item in
                                    KitchenItemCard(item: item)
                                        .contentShape(Rectangle())
                                        .contextMenu {
                                            Button {
                                                editingItem = item
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            Button(role: .destructive) {
                                                modelContext.delete(item)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                        .id(item.id)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 80)
                }
                
                // MARK: - Add Button
                Button {
                    showingAddItem = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("My Pantry")
            .searchable(text: $searchText, prompt: "Search items...")
            .onAppear { fetchItems() }
            .sheet(isPresented: $showingAddItem) {
                AddItemSheet()
            }
            .onChange(of: showingAddItem) {
                if !showingAddItem { fetchItems() }
            }
            .sheet(item: $editingItem) { item in
                EditItemSheet(item: item)
            }
            .onChange(of: editingItem) {
                if editingItem == nil { fetchItems() }
            }
        }
    }
}

// MARK: - Kitchen Item Card
struct KitchenItemCard: View {
    @Bindable var item: KitchenItem
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(item.isAvailable ? Color.green : Color.red.opacity(0.3))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name.capitalized)
                    .font(.body)
                    .fontWeight(.medium)
                Text(item.category.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if item.type == .countable {
                CountableControl(item: item)
            } else {
                BulkControl(item: item)
                    .frame(width: 110, alignment: .trailing)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        .animation(.none, value: item.stockLevelRaw)
    }
}

// MARK: - Countable Control
struct CountableControl: View {
    @Bindable var item: KitchenItem
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                if item.count > 0 { item.count -= 1 }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(item.count > 0 ? .red : .gray.opacity(0.3))
            }
            .disabled(item.count == 0)
            
            Text("\(item.count)")
                .font(.headline)
                .frame(minWidth: 24)
                .multilineTextAlignment(.center)
            
            Button {
                item.count += 1
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
        }
    }
}

// MARK: - Bulk Control
struct BulkControl: View {
    @Bindable var item: KitchenItem
    
    var body: some View {
        Menu {
            ForEach(StockLevel.allCases, id: \.self) { level in
                Button {
                    item.stockLevel = level
                } label: {
                    HStack {
                        Text(level.displayName)
                        if item.stockLevel == level {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Text(item.stockLevel.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .frame(minWidth: 90)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(stockColor.opacity(0.15))
                .foregroundStyle(stockColor)
                .clipShape(Capsule())
                .fixedSize()
        }
    }
    
    private var stockColor: Color {
        switch item.stockLevel {
        case .full: return .green
        case .low: return .orange
        case .out: return .red
        }
    }
}

// MARK: - Add Item Sheet
struct AddItemSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingItems: [KitchenItem]
    
    @State private var name = ""
    @State private var selectedCategory: IngredientCategory = .vegetable
    @State private var selectedType: IngredientType = .countable
    @State private var count: Int = 1
    @State private var stockLevel: StockLevel = .full
    @State private var showBulkDuplicateAlert = false
    @State private var duplicateItemName = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("What do you have?") {
                    TextField("e.g. Add 5 bananas, 2 kg rice", text: $name)
                        .onChange(of: name) {
                            let parsed = IngredientParser.parse(name)
                            if !parsed.name.isEmpty {
                                selectedCategory = parsed.category
                                selectedType = parsed.type
                                count = parsed.count
                                stockLevel = parsed.stockLevel
                            }
                        }
                }
                
                Section("Auto-detected") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(IngredientCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    
                    Picker("Type", selection: $selectedType) {
                        Text("Countable (eggs, onions)").tag(IngredientType.countable)
                        Text("Bulk (rice, oil, spices)").tag(IngredientType.bulk)
                    }
                }
                
                Section("Quantity") {
                    if selectedType == .countable {
                        Stepper("Count: \(count)", value: $count, in: 1...99)
                    } else {
                        Picker("Stock Level", selection: $stockLevel) {
                            ForEach(StockLevel.allCases, id: \.self) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let parsed = IngredientParser.parse(name)
                        let itemName = parsed.name.isEmpty ? name.trimmingCharacters(in: .whitespaces) : parsed.name
                        let key = itemName.lowercased()
                        
                        if let existing = existingItems.first(where: { $0.name.lowercased() == key }) {
                            if existing.type == .countable {
                                existing.count += count
                                dismiss()
                            } else {
                                duplicateItemName = existing.name.capitalized
                                showBulkDuplicateAlert = true
                            }
                        } else {
                            let item = KitchenItem(
                                name: itemName,
                                category: selectedCategory,
                                type: selectedType,
                                count: selectedType == .countable ? count : 0,
                                stockLevel: selectedType == .bulk ? stockLevel : .out
                            )
                            modelContext.insert(item)
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("\(duplicateItemName) already exists", isPresented: $showBulkDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You can update its stock level in your pantry.")
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Edit Item Sheet
struct EditItemSheet: View {
    @Bindable var item: KitchenItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item name", text: $item.name)
                    
                    Picker("Category", selection: $item.category) {
                        ForEach(IngredientCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    
                    Picker("Type", selection: $item.type) {
                        Text("Countable (eggs, onions)").tag(IngredientType.countable)
                        Text("Bulk (rice, oil, spices)").tag(IngredientType.bulk)
                    }
                }
                
                Section("Quantity") {
                    if item.type == .countable {
                        Stepper("Count: \(item.count)", value: $item.count, in: 0...99)
                    } else {
                        Picker("Stock Level", selection: $item.stockLevel) {
                            ForEach(StockLevel.allCases, id: \.self) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    InventoryView()
        .modelContainer(for: KitchenItem.self, inMemory: true)
}
