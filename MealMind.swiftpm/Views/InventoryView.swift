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
    @State private var showLowOnly = false
    @StateObject private var voiceManager = VoiceInputManager()
    @State private var isProcessingVoice = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var llmParser = LLMFoodParser()
    
    var filteredItems: [KitchenItem] {
        var result = items
        if showLowOnly {
            result = result.filter { item in
                if item.type == .countable { return item.count <= 2 }
                return item.stockLevel == .low || item.stockLevel == .out
            }
        } else if let category = selectedCategory {
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
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [Color("GradientBgStart"), Color("GradientBgEnd")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("\(availableCount) of \(items.count) items available")
                            .font(.subheadline)
                            .foregroundStyle(Color("SecondaryText"))
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                CategoryPill(
                                    title: "All",
                                    isSelected: selectedCategory == nil && !showLowOnly,
                                    action: { selectedCategory = nil; showLowOnly = false }
                                )
                                CategoryPill(
                                    title: "⚠️ Low",
                                    isSelected: showLowOnly,
                                    action: { selectedCategory = nil; showLowOnly = true }
                                )
                                ForEach(IngredientCategory.allCases, id: \.self) { category in
                                    CategoryPill(
                                        title: category.displayName,
                                        isSelected: selectedCategory == category && !showLowOnly,
                                        action: { selectedCategory = category; showLowOnly = false }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        if filteredItems.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "refrigerator")
                                    .font(.largeTitle)
                                    .foregroundStyle(Color("TertiaryText"))
                                Text("Your pantry is empty")
                                    .font(.headline)
                                    .foregroundStyle(Color("SecondaryText"))
                                Text("Tap + to add items you have at home")
                                    .font(.subheadline)
                                    .foregroundStyle(Color("TertiaryText"))
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
                                                fetchItems()
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
                    .padding(.bottom, 100)
                }
                
                if voiceManager.isListening || isProcessingVoice {
                    VoiceListeningOverlay(
                        text: isProcessingVoice ? "" : voiceManager.transcribedText,
                        isProcessing: isProcessingVoice,
                        onCancel: {
                            voiceManager.stopListening()
                            isProcessingVoice = false
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                if !voiceManager.isListening && !isProcessingVoice {
                    HStack {
                        Button {
                            voiceManager.onResult = { text in
                                processVoiceInput(text)
                            }
                            voiceManager.startListening()
                        } label: {
                            Image(systemName: "mic.fill")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Color("AccentColor"))
                                .clipShape(Circle())
                                .shadow(color: Color("AccentColor").opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        Spacer()
                        
                        Button {
                            showingAddItem = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Color("AccentColor"))
                                .clipShape(Circle())
                                .shadow(color: Color("AccentColor").opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: voiceManager.isListening)
            .animation(.easeInOut(duration: 0.25), value: isProcessingVoice)
            .navigationTitle("My Pantry")
            .searchable(text: $searchText, prompt: "Search items...")
            .onAppear { fetchItems() }
            .sheet(isPresented: $showingAddItem) { AddItemSheet() }
            .onChange(of: showingAddItem) { if !showingAddItem { fetchItems() } }
            .sheet(item: $editingItem) { item in EditItemSheet(item: item) }
            .onChange(of: editingItem) { if editingItem == nil { fetchItems() } }
            .overlay(alignment: .bottom) {
                if showToast {
                    Text(toastMessage)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color("PrimaryText"))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .shadow(radius: 4)
                        .padding(.bottom, 90)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation { showToast = false }
                            }
                        }
                }
            }
        }
    }
    
    private func processVoiceInput(_ text: String) {
        isProcessingVoice = true
        Task {
            var items: [ParsedVoiceItem] = []
            if llmParser.isAvailable {
                if let llmItems = await llmParser.parse(text) {
                    items = llmItems
                }
            } else {
                items = nlpFallbackParse(text)
            }
            isProcessingVoice = false
            if items.isEmpty {
                if llmParser.isAvailable {
                    showToastMessage("Couldn't understand. Try again")
                } else {
                    showToastMessage("Couldn't recognize any food items. Try again!")
                }
            } else {
                applyToPantry(items)
                let summary = items.map { item in
                    switch item.action {
                    case .add:
                        if item.type == .countable && item.count > 0 {
                            return "+ \(item.count) \(item.name)"
                        } else {
                            return "+ \(item.name)"
                        }
                    case .remove:
                        if item.type == .countable && item.count > 0 {
                            return "- \(item.count) \(item.name)"
                        } else {
                            return "- \(item.name)"
                        }
                    case .low: return "\(item.name) → low"
                    case .out: return "\(item.name) → out"
                    }
                }.joined(separator: ", ")
                showToastMessage("Updated: \(summary)")
            }
        }
    }
    
    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation { showToast = true }
    }
    
    private func nlpFallbackParse(_ text: String) -> [ParsedVoiceItem] {
        let lower = text.lowercased()
        let action: PantryAction
        if lower.contains("ate") || lower.contains("used") || lower.contains("consumed") || lower.contains("finished") || lower.contains("had ") {
            action = .remove
        } else if lower.contains("low on") || lower.contains("running low") || lower.contains("almost out") {
            action = .low
        } else if lower.contains("out of") || lower.contains("no more") || lower.contains("don't have") || lower.contains("finished all") {
            action = .out
        } else {
            action = .add
        }
        let segments = text
            .replacingOccurrences(of: ",", with: " and ")
            .components(separatedBy: " and ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        var parsed: [ParsedVoiceItem] = []
        for segment in segments {
            let cleaned = segment.trimmingCharacters(in: .whitespaces)
            guard !cleaned.isEmpty else { continue }
            let result = IngredientParser.parse(cleaned)
            let name = result.name.isEmpty ? cleaned : result.name
            guard !name.isEmpty else { continue }
            let classified = IngredientClassifier.classify(name)
            guard classified.category != .other else { continue }
            parsed.append(ParsedVoiceItem(
                rawText: segment, name: name, category: result.category,
                type: result.type, count: max(result.count, 1),
                stockLevel: result.stockLevel, action: action
            ))
        }
        return parsed
    }
    
    private func applyToPantry(_ voiceItems: [ParsedVoiceItem]) {
        let descriptor = FetchDescriptor<KitchenItem>()
        let existingItems = (try? modelContext.fetch(descriptor)) ?? []
        for voiceItem in voiceItems {
            if voiceItem.action == .add && voiceItem.type == .countable && voiceItem.count <= 0 { continue }
            let existing = existingItems.first(where: {
                $0.name.lowercased() == voiceItem.name.lowercased()
            })
            switch voiceItem.action {
            case .add:
                if let existing {
                    if existing.type == .countable { existing.count += voiceItem.count }
                    else { existing.stockLevel = .full }
                } else {
                    modelContext.insert(KitchenItem(
                        name: voiceItem.name, category: voiceItem.category, type: voiceItem.type,
                        count: voiceItem.type == .countable ? voiceItem.count : 0,
                        stockLevel: voiceItem.type == .bulk ? .full : .out
                    ))
                }
            case .remove:
                if let existing {
                    if existing.type == .countable {
                        if voiceItem.count == -1 { existing.count = 0 }
                        else { existing.count = max(0, existing.count - voiceItem.count) }
                    } else { existing.stockLevel = .out }
                }
            case .low:
                if let existing { existing.stockLevel = .low }
                else {
                    modelContext.insert(KitchenItem(
                        name: voiceItem.name, category: voiceItem.category, type: voiceItem.type,
                        count: voiceItem.type == .countable ? 1 : 0, stockLevel: .low
                    ))
                }
            case .out:
                if let existing {
                    if existing.type == .countable { existing.count = 0 }
                    else { existing.stockLevel = .out }
                } else {
                    modelContext.insert(KitchenItem(
                        name: voiceItem.name, category: voiceItem.category, type: voiceItem.type,
                        count: 0, stockLevel: .out
                    ))
                }
            }
        }
        fetchItems()
    }
    
    private func normalizeForMatch(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }
}

enum PantryAction: String, CaseIterable {
    case add = "Add"
    case remove = "Remove"
    case low = "Running Low"
    case out = "Out"
}

struct ParsedVoiceItem: Identifiable {
    let id = UUID()
    let rawText: String
    var name: String
    var category: IngredientCategory
    var type: IngredientType
    var count: Int
    var stockLevel: StockLevel
    var action: PantryAction = .add
}

struct VoiceListeningOverlay: View {
    let text: String
    var isProcessing: Bool = false
    let onCancel: () -> Void
    @State private var pulse = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isProcessing ? Color("AccentColor").opacity(0.2) : Color("AccentColor").opacity(0.2))
                    .frame(width: pulse ? 80 : 60, height: pulse ? 80 : 60)
                if isProcessing {
                    ProgressView()
                } else {
                    Image(systemName: "mic.fill")
                        .font(.title)
                        .foregroundStyle(Color("AccentColor"))
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { pulse = true }
            }
            Text(isProcessing ? "Analyzing with AI..." : (text.isEmpty ? "Listening... say what you have" : "\"\(text)\""))
                .font(.body)
                .foregroundStyle(text.isEmpty && !isProcessing ? Color("SecondaryText") : Color("PrimaryText"))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .animation(.default, value: text)
            if !isProcessing {
                Text("Stops automatically after 2s of silence")
                    .font(.caption2)
                    .foregroundStyle(Color("TertiaryText"))
            }
            Button("Cancel", role: .cancel) { onCancel() }
                .font(.subheadline)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

struct KitchenItemCard: View {
    @Bindable var item: KitchenItem
    
    private var statusColor: Color {
        if item.type == .countable {
            if item.count == 0 { return Color("OutOfStock") }
            if item.count <= 2 { return Color("LowStock") }
            return Color("InStock")
        }
        switch item.stockLevel {
        case .full: return Color("InStock")
        case .low: return Color("LowStock")
        case .out: return Color("OutOfStock")
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(statusColor)
                .frame(width: 4, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name.capitalized)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color("PrimaryText"))
                Text(item.category.displayName)
                    .font(.caption2)
                    .foregroundStyle(Color("SecondaryText"))
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
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CountableControl: View {
    @Bindable var item: KitchenItem
    var body: some View {
        HStack(spacing: 12) {
            Button {
                if item.count > 0 { item.count -= 1 }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(item.count > 0 ? Color("OutOfStock") : Color("TertiaryText"))
            }
            .buttonStyle(.plain)
            .disabled(item.count == 0)
            Text("\(item.count)")
                .font(.headline)
                .foregroundStyle(Color("PrimaryText"))
                .frame(minWidth: 24)
                .multilineTextAlignment(.center)
            Button {
                item.count += 1
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color("InStock"))
            }
            .buttonStyle(.plain)
        }
    }
}

struct BulkControl: View {
    @Bindable var item: KitchenItem
    private var stockColor: Color {
        switch item.stockLevel {
        case .full: return Color("InStock")
        case .low: return Color("LowStock")
        case .out: return Color("OutOfStock")
        }
    }
    var body: some View {
        Menu {
            ForEach(StockLevel.allCases, id: \.self) { level in
                Button {
                    item.stockLevel = level
                } label: {
                    HStack {
                        Text(level.displayName)
                        if item.stockLevel == level { Image(systemName: "checkmark") }
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
}

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
                    TextField("e.g. I bought 5 bananas, I have 2 kg rice", text: $name)
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
                        ForEach(IngredientCategory.allCases, id: \.self) { Text($0.displayName).tag($0) }
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
                            ForEach(StockLevel.allCases, id: \.self) { Text($0.displayName).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let parsed = IngredientParser.parse(name)
                        let raw = parsed.name.isEmpty ? name.trimmingCharacters(in: .whitespaces) : parsed.name
                        let itemName = raw.prefix(1).uppercased() + raw.dropFirst()
                        let key = itemName.lowercased()
                        if let existing = existingItems.first(where: { IngredientMatcher.matches($0.name, itemName) }) {
                            if existing.type == .countable { existing.count += count; dismiss() }
                            else { duplicateItemName = existing.name.capitalized; showBulkDuplicateAlert = true }
                        } else {
                            modelContext.insert(KitchenItem(
                                name: itemName, category: selectedCategory, type: selectedType,
                                count: selectedType == .countable ? count : 0,
                                stockLevel: selectedType == .bulk ? stockLevel : .out
                            ))
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

struct EditItemSheet: View {
    @Bindable var item: KitchenItem
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item name", text: $item.name)
                    Picker("Category", selection: $item.category) {
                        ForEach(IngredientCategory.allCases, id: \.self) { Text($0.displayName).tag($0) }
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
                            ForEach(StockLevel.allCases, id: \.self) { Text($0.displayName).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    InventoryView()
        .modelContainer(for: KitchenItem.self, inMemory: true)
}
