//
//  WeeklyPlan.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/13/26.
//

import Foundation
import SwiftData

enum Weekday: String, Codable, CaseIterable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
    
    var shortName: String {
        String(rawValue.prefix(3))
    }
}

@Model
class PlannedMeal {
    var id: UUID
    var recipeId: UUID
    var recipeName: String
    var dayRaw: String
    var mealSlot: String
    var isCooked: Bool
    var servingsPlanned: Int
    var recipeServings: Int
    var date: Date
    
    var day: Weekday {
        get { Weekday(rawValue: dayRaw) ?? .monday }
        set { dayRaw = newValue.rawValue }
    }
    
    init(recipeId: UUID, recipeName: String, day: Weekday, mealSlot: String, servingsPlanned: Int = 1, recipeServings: Int = 1, date: Date = Date()) {
        self.id = UUID()
        self.recipeId = recipeId
        self.recipeName = recipeName
        self.dayRaw = day.rawValue
        self.mealSlot = mealSlot
        self.isCooked = false
        self.servingsPlanned = servingsPlanned
        self.recipeServings = recipeServings
        self.date = Calendar.current.startOfDay(for: date)
    }
}

struct MealSlots {
    static let defaults = ["Breakfast", "Lunch", "Dinner"]
}
