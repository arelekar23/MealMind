//
//  SplashScreenView.swift
//  MealMind
//
//  Created by Adwait Relekar on 2/27/26.
//

import SwiftUI

struct SplashScreen: View {
    @State private var iconScale: CGFloat = 0.3
    @State private var iconRotation: Double = -180
    @State private var iconOpacity: Double = 0
    @State private var titleOffset: CGFloat = 50
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var burstVisible = false
    @State private var orbitVisible = false
    @State private var floatersVisible = false
    @State private var gradientAngle: Double = 0
    
    var onFinished: () -> Void
    
    private let burstEmojis = ["🍎", "🥕", "🍳", "🥑", "🌶️", "🧅", "🍋", "🥦", "🍅", "🧄", "🫒", "🥚", "🍌", "🥛", "🧈", "🍚"]
    private let orbitEmojis = ["🥘", "🍲", "🥗", "🍛", "🥙", "🍜"]
    private let floatingEmojis = ["🫑", "🥬", "🧅", "🍇", "🥭", "🫐", "🍊", "🥒", "🌽", "🍆", "🥔", "🫘", "🧀", "🥩", "🫚", "🍯", "🫛", "🥜", "🍶", "🫙"]
    
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let isIPad = size.width > 600
            let iconSize: CGFloat = isIPad ? 120 : 80
            let titleSize: CGFloat = isIPad ? 56 : 42
            let ringSize: CGFloat = isIPad ? 220 : 160
            let outerRingSize: CGFloat = isIPad ? 280 : 200
            let burstDistance: ClosedRange<CGFloat> = isIPad ? 200...340 : 130...220
            let orbitRadius: CGFloat = isIPad ? 200 : 140
            let emojiSize: ClosedRange<CGFloat> = isIPad ? 26...44 : 18...32
            let burstEmojiSize: CGFloat = isIPad ? 40 : 30
            let orbitEmojiSize: CGFloat = isIPad ? 34 : 26
            
            ZStack {
                AngularGradient(
                    colors: [
                        Color("AccentColor").opacity(0.3),
                        Color.orange.opacity(0.4),
                        Color("AccentColor").opacity(0.2),
                        Color.green.opacity(0.3),
                        Color("AccentColor").opacity(0.3)
                    ],
                    center: .center,
                    angle: .degrees(gradientAngle)
                )
                .blur(radius: 60)
                .ignoresSafeArea()
                
                if floatersVisible {
                    ForEach(0..<20, id: \.self) { i in
                        FloatingEmoji(
                            emoji: floatingEmojis[i % floatingEmojis.count],
                            screenSize: size,
                            delay: Double(i) * 0.15,
                            emojiSize: emojiSize
                        )
                    }
                }
                if burstVisible {
                    ForEach(0..<burstEmojis.count, id: \.self) { i in
                        BurstParticle(
                            emoji: burstEmojis[i],
                            index: i,
                            total: burstEmojis.count,
                            delay: Double(i) * 0.05,
                            distanceRange: burstDistance,
                            emojiSize: burstEmojiSize
                        )
                    }
                }
                
                VStack(spacing: isIPad ? 28 : 20) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(Color("AccentColor").opacity(0.2), lineWidth: 2)
                            .frame(width: ringSize, height: ringSize)
                            .scaleEffect(ringScale)
                            .opacity(ringOpacity)
                        
                        Circle()
                            .stroke(Color("AccentColor").opacity(0.1), lineWidth: 1)
                            .frame(width: outerRingSize, height: outerRingSize)
                            .scaleEffect(ringScale * 0.8)
                            .opacity(ringOpacity * 0.6)
                        
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: iconSize))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color("AccentColor"), .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(iconScale)
                            .rotationEffect(.degrees(iconRotation))
                            .opacity(iconOpacity)
                            .shadow(color: Color("AccentColor").opacity(0.4), radius: 20, x: 0, y: 10)
                    }
                    
                    VStack(spacing: 8) {
                        Text("MealMind")
                            .font(.system(size: titleSize, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color("PrimaryText"), Color("AccentColor")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(y: titleOffset)
                            .opacity(titleOpacity)
                        
                        Text("Your Intelligent Kitchen Companion")
                            .font(isIPad ? .title3 : .subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color("SecondaryText"))
                            .opacity(subtitleOpacity)
                    }
                    
                    Spacer()
                    Spacer()
                }
            }
        }
        .onAppear { startAnimations() }
    }
    
    private func startAnimations() {
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
            gradientAngle = 360
        }
        
        withAnimation { floatersVisible = true }
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
            iconScale = 1.0
            iconRotation = 0
            iconOpacity = 1
        }
        
        withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
            ringScale = 1.2
            ringOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.8).delay(1.3)) {
            ringOpacity = 0
            ringScale = 1.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation { burstVisible = true }
        }
        
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.9)) {
            titleOffset = 0
            titleOpacity = 1
        }
        
        withAnimation(.easeIn(duration: 0.5).delay(1.4)) {
            subtitleOpacity = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            onFinished()
        }
    }
}

struct BurstParticle: View {
    let emoji: String
    let index: Int
    let total: Int
    let delay: Double
    let distanceRange: ClosedRange<CGFloat>
    let emojiSize: CGFloat
    
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.2
    @State private var rotation: Double = 0
    
    var body: some View {
        Text(emoji)
            .font(.system(size: emojiSize))
            .offset(offset)
            .opacity(opacity)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                let angle = (Double(index) / Double(total)) * 2 * .pi
                let distance = CGFloat.random(in: distanceRange)
                let tx = cos(angle) * distance
                let ty = sin(angle) * distance
                
                withAnimation(.spring(response: 0.7, dampingFraction: 0.5).delay(delay)) {
                    offset = CGSize(width: tx, height: ty)
                    opacity = 1
                    scale = CGFloat.random(in: 0.8...1.2)
                    rotation = Double.random(in: -30...30)
                }
                withAnimation(.easeOut(duration: 0.8).delay(delay + 1.2)) {
                    opacity = 0
                    scale = 0.4
                    offset = CGSize(width: tx * 1.4, height: ty * 1.4)
                }
            }
    }
}
struct FloatingEmoji: View {
    let emoji: String
    let screenSize: CGSize
    let delay: Double
    let emojiSize: ClosedRange<CGFloat>
    
    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 0
    @State private var drift: CGSize = .zero
    @State private var wobble: Double = 0
    @State private var bounce: CGFloat = 1.0
    
    var body: some View {
        Text(emoji)
            .font(.system(size: CGFloat.random(in: emojiSize)))
            .position(position)
            .offset(drift)
            .opacity(opacity)
            .scaleEffect(bounce)
            .rotationEffect(.degrees(wobble))
            .onAppear {
                position = CGPoint(
                    x: CGFloat.random(in: 20...(screenSize.width - 20)),
                    y: CGFloat.random(in: 40...(screenSize.height - 40))
                )
                
                withAnimation(.easeIn(duration: 0.6).delay(delay)) {
                    opacity = Double.random(in: 0.08...0.2)
                }
                
                withAnimation(
                    .easeInOut(duration: Double.random(in: 2...4))
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    drift = CGSize(
                        width: CGFloat.random(in: -40...40),
                        height: CGFloat.random(in: -35...35)
                    )
                }
                
                withAnimation(
                    .easeInOut(duration: Double.random(in: 1.5...3))
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    wobble = Double.random(in: -20...20)
                }
                
                withAnimation(
                    .easeInOut(duration: Double.random(in: 1...2))
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    bounce = CGFloat.random(in: 0.85...1.15)
                }
            }
    }
}

#Preview {
    SplashScreen { }
}
