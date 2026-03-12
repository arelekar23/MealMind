# MealMind

An intelligent iOS meal planning app that helps you manage your pantry, discover recipes, plan weekly meals, and generate smart grocery lists -- all powered by on-device AI with zero network calls.

Built as a Swift Student Challenge 2026 submission.

## The Problem

After moving to the US for grad school, I found myself constantly wasting groceries. Without a system to plan meals around what I already had in my kitchen, food would expire before I could use it. MealMind was born from that frustration.

## Features

### Voice-Powered Pantry Management
Say things like "I have 5 apples and some cumin" and MealMind understands. Speech is captured via `SFSpeechRecognizer`, then parsed through a multi-layer AI pipeline:
- **Apple Foundation Models** (on-device LLM) extract food names, quantities, and units from natural speech
- **Deterministic Swift logic** detects user intent (add, remove, update)
- **CoreML text classifier** categorizes ingredients in real time (trained on 1,050+ examples)
- Falls back to an NLP pipeline using Apple's `NaturalLanguage` framework if the LLM is unavailable

### Recipe Discovery
Browse 50+ built-in recipes with detailed ingredients, instructions, prep/cook times, and difficulty ratings. An `IngredientMatcher` system handles ingredient name variations so "bell pepper" and "capsicum" match correctly when filtering by pantry availability.

### Weekly Meal Planning
Plan meals across breakfast, lunch, dinner, and snacks with daily, weekly, and monthly calendar views. Add multiple meals at once without dismissing the sheet, and already-added recipes are automatically hidden to prevent duplicates.

### Smart Grocery Lists
Grocery lists are auto-generated from your meal plan. The app aggregates ingredients across planned meals, subtracts what you already have in your pantry, and groups everything by category. Checking off an item automatically adds it to your pantry inventory.

### Add Your Own Recipes
Create custom recipes with ingredients, steps, and metadata. Custom recipes integrate with meal planning and grocery list generation just like built-in ones.

## Architecture

MealMind runs entirely on-device with no server calls, no API keys, and no internet dependency.

```
Speech Input (SFSpeechRecognizer)
        |
        v
Foundation Models (LLM) --> extracts food name, quantity, unit
        |                    (plain text pipe-delimited format)
        |
        v
Deterministic Swift --> detects action (add/remove/update)
        |
        v
CoreML Classifier --> categorizes ingredient (vegetable, protein, spice, etc.)
        |
        v
SwiftData (Persistence)
```

A key architectural decision was using **plain text pipe-delimited LLM responses** instead of `@Generable` structured output. Early testing showed the on-device model would hallucinate category and type values with `@Generable`, so responsibilities were split: the LLM only handles food name and quantity extraction (what it does well), while categorization is handled by the deterministic CoreML classifier.

### Tech Stack
- **UI**: SwiftUI with `@Query` + MVVM hybrid pattern
- **Persistence**: SwiftData
- **On-Device AI**: Apple Foundation Models (iOS 26)
- **ML**: CoreML (custom trained text classifier, 1,050+ training examples)
- **NLP**: Apple NaturalLanguage framework (tokenization, lemmatization, part-of-speech tagging)
- **Speech**: SFSpeechRecognizer with silence detection and auto-stop
- **Target**: iOS 26, no network calls

## Screenshots

*Coming soon*

## Requirements

- iOS 26+
- Xcode 26+
- Apple Intelligence enabled (for Foundation Models features)
- Microphone access (for voice input)

## Getting Started

1. Clone the repository
2. Open `MealMind.swiftpm` in Xcode
3. Build and run on a device or simulator with iOS 26+
4. Grant microphone and speech recognition permissions when prompted

## Author

**Adwait Relekar**
- [LinkedIn](https://linkedin.com/in/relekaradwait)
- [GitHub](https://github.com/arelekar23)

## License

This project was created for the Apple Swift Student Challenge 2026.
