//
//  OnboardingView.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/24/26.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "fork.knife.circle.fill",
            iconColor: Color("AccentColor"),
            title: "Welcome to MealMind",
            subtitle: "Your intelligent kitchen companion",
            description: "Plan meals, manage your pantry, and build grocery lists — all powered by on-device AI that keeps your data private."
        ),
        OnboardingPage(
            icon: "mic.circle.fill",
            iconColor: .yellow,
            title: "Voice-Powered Pantry",
            subtitle: "Just say it",
            description: "\"I bought 5 apples\", \"We used 2 eggs\", or \"Running low on milk\" — MealMind understands natural speech and updates your pantry instantly."
        ),
        OnboardingPage(
            icon: "book.circle.fill",
            iconColor: .purple,
            title: "Recipes & Meal Planning",
            subtitle: "Plan your week",
            description: "Browse recipes, add your own with structured ingredients, and plan meals across daily, weekly, or monthly views."
        ),
        OnboardingPage(
            icon: "cart.circle.fill",
            iconColor: .green,
            title: "Smart Grocery List",
            subtitle: "Buy only what you need",
            description: "Auto-generated from your meal plan, minus what's already in your pantry. Check off items and add them to stock in bulk."
        ),
        OnboardingPage(
            icon: "brain.head.profile.fill",
            iconColor: .red,
            title: "Built with Apple Intelligence",
            subtitle: "100% on-device",
            description: "Foundation Models parse your voice input. CoreML classifies ingredients. NaturalLanguage handles text parsing. Speech framework captures your voice. Everything stays on your device."
        )
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [pages[currentPage].iconColor.opacity(0.08), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            VStack {
                HStack {
                    Spacer()
                    Button("Skip") {
                        hasSeenOnboarding = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color("AccentColor"))
                    .padding()
                }
                
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: 24) {
                            Spacer()
                            
                            Image(systemName: page.icon)
                                .font(.system(size: 80))
                                .foregroundStyle(page.iconColor)
                                .shadow(color: page.iconColor.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            Text(page.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(Color("PrimaryText"))
                                .multilineTextAlignment(.center)
                            
                            Text(page.subtitle)
                                .font(.title3)
                                .foregroundStyle(page.iconColor)
                                .fontWeight(.medium)
                            
                            Text(page.description)
                                .font(.body)
                                .foregroundStyle(Color("SecondaryText"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            
                            Spacer()
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                HStack {
                    if currentPage > 0 {
                        Button {
                            withAnimation { currentPage -= 1 }
                        } label: {
                            Text("Previous")
                                .font(.headline)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color("PillBackground"))
                                .foregroundStyle(Color("PrimaryText"))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            hasSeenOnboarding = true
                        }
                    } label: {
                        Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                            .font(.headline)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(pages[currentPage].iconColor)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
}

#Preview {
    OnboardingView()
}
