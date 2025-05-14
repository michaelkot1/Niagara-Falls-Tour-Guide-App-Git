//
//  HomeSwift.swift
//  Niagara Falls SightSeeing
//
//  Created by Michael Kot on 4/1/25.
//

import SwiftUI

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var animateGradient = false
    @State private var showWelcome = false
    @State private var waveOffset = 0.0
    @State private var currentTabIndex = 1
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.appBlue.opacity(0.1), Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Water Wave Animation
                WaterWaveView()
                    .frame(height: 90)
                    .frame(maxWidth: .infinity)
                    .position(x: UIScreen.main.bounds.width / 2, y: 0)
                    .ignoresSafeArea()
                
                ScrollView {
                    // Add some padding at top to account for the wave
                    VStack(spacing: 12) {
                        Spacer()
                            .frame(height: 20)
                            
                        // Welcome header that animates in
                        Text("Welcome to Niagara Falls")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.appBlue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 0)
                            .opacity(showWelcome ? 1 : 0)
                            .offset(y: showWelcome ? 0 : 20)
                            .onAppear {
                                withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                                    showWelcome = true
                                }
                            }
                        
                        // Hero image carousel
                        TabView(selection: $currentTabIndex) {
                            // First image
                            ZStack(alignment: .bottomLeading) {
                                Image("newPIC")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 260)
                                    .clipped()
                                    
                                // Text overlay
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Discover the Wonder")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Text("Experience nature's most powerful waterfall")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.black.opacity(0.7), .clear]),
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                            }
                            .tag(0)
                            
                            // Second image
                            ZStack(alignment: .bottomLeading) {
                                Image("niagara-falls-state-park")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 260)
                                    .clipped()
                                    
                                // Text overlay
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("All-Season Beauty")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("Breathtaking views in every season")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.black.opacity(0.7), .clear]),
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                            }
                            .tag(1)
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                        .frame(height: 260)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                        
                        // Featured Tour Card - larger and more prominent
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Featured Tour")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.appBlue)
                                .padding(.horizontal)
                            
                            FeaturedTourCard {
                                // Navigate to Tours tab
                                appState.selectedTab = 2
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 5)
                        
                        // Quick Links Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Explore")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.appBlue)
                                .padding(.horizontal)
                            
                            // Quick access buttons
                            HStack(spacing: 15) {
                                QuickLinkButton(
                                    icon: "map.fill",
                                    title: "Map",
                                    color: Color.green.opacity(0.8)
                                ) {
                                    appState.selectedTab = 1 // Go to Explore tab
                                }
                                
                                QuickLinkButton(
                                    icon: "figure.walk",
                                    title: "Tours",
                                    color: Color.orange.opacity(0.8)
                                ) {
                                    appState.selectedTab = 2 // Go to Tours tab
                                }
                                
                                QuickLinkButton(
                                    icon: "calendar",
                                    title: "Events",
                                    color: Color.purple.opacity(0.8)
                                ) {
                                    appState.selectedTab = 3 // Go to Events tab
                                }
                                
                                QuickLinkButton(
                                    icon: "info.circle.fill",
                                    title: "About",
                                    color: Color.blue.opacity(0.8)
                                ) {
                                    appState.selectedTab = 4 // Go to Settings tab
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Features section - redesigned with cards
                        VStack(alignment: .leading, spacing: 12) {
                            Text("App Features")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.appBlue)
                                .padding(.horizontal)
                            
                            VStack(spacing: 15) {
                                FeatureCard(
                                    icon: "map.fill",
                                    title: "Interactive Maps",
                                    description: "Navigate with ease using our detailed maps",
                                    color: .blue
                                )
                                
                                FeatureCard(
                                    icon: "speaker.wave.2.fill",
                                    title: "Audio Guide",
                                    description: "Listen to the history and facts as you explore",
                                    color: .red
                                )
                                
                                FeatureCard(
                                    icon: "location.fill",
                                    title: "Points of Interest",
                                    description: "Discover hidden gems and popular attractions",
                                    color: .green
                                )
                                
                                FeatureCard(
                                    icon: "calendar",
                                    title: "Local Events",
                                    description: "Stay updated with events happening in Niagara Falls",
                                    color: .purple
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        // Footer with app info
                        VStack(spacing: 5) {
                            Text("Niagara Falls Guide")
                                .font(.headline)
                                .foregroundColor(.appBlue)
                            
                            Text("Your perfect companion for exploring")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    // Centered title with larger font and darker blue
                    Text("Niagara Falls")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "0E3B55")) // Dark blue from the Home button image
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Water Wave Animation View
struct WaterWaveView: View {
    @State private var waveOffset = 0.0
    
    var body: some View {
        ZStack {
            // First wave (slower)
            WaterWave(yOffset: 0.7, amplitude: 10, frequency: 0.15, phase: waveOffset)
                .fill(Color.appBlue.opacity(0.4))
                .frame(height: 100)
            
            // Second wave (faster)
            WaterWave(yOffset: 0.75, amplitude: 15, frequency: 0.2, phase: waveOffset * 1.5)
                .fill(Color.appBlue.opacity(0.3))
                .frame(height: 100)
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 5).repeatForever(autoreverses: false)) {
                waveOffset = .pi * 2
            }
        }
    }
}

struct WaterWave: Shape {
    var yOffset: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let midHeight = height * yOffset
        
        // Start at the bottom left
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        
        // Draw path to top left with wave
        for x in stride(from: 0, to: width, by: 5) {
            let relativeX = x / width
            let sine = sin(CGFloat(phase) + relativeX * CGFloat.pi * frequency)
            let y = midHeight + amplitude * sine
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Line to bottom right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
}

// MARK: - Featured Tour Card
struct FeaturedTourCard: View {
    var onTap: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            Image("niagara-falls-in-autumn")
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .scaleEffect(x: -1, y: 1)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.black.opacity(0.7), .clear]),
                                startPoint: .bottom,
                                endPoint: .center
                            )
                        )
                )
                .scaleEffect(isHovering ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isHovering)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Category pill
               
                
                Text("Niagara Falls Tour")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack {
                    Text("All Day • 9 Stops")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                    
                    // Rating
                    HStack(spacing: 2) {
                        ForEach(0..<5) { _ in
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                        Text("(120)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Button(action: onTap) {
                    Text("View Details")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .foregroundColor(.appBlue)
                        .cornerRadius(20)
                }
                .padding(.top, 5)
            }
            .padding(15)
        }
        .frame(maxWidth: .infinity)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .onTapGesture {
            onTap()
        }
        .onHover({ hovering in
            isHovering = hovering
        })
    }
}

// MARK: - Quick Link Button
struct QuickLinkButton: View {
    var icon: String
    var title: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 60, height: 60)
                        .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    var icon: String
    var title: String
    var description: String
    var color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
    }
}

// Extension for hover support
extension View {
    func onHover(_ mouseIsHovering: @escaping (Bool) -> Void) -> some View {
        #if os(iOS)
        return self // iOS doesn't support hover
        #else
        return onHover(perform: mouseIsHovering)
        #endif
    }
}
