//
//  MainTabView.swift
//  Niagara Falls SightSeeing
//
//  Created by Michael Kot on 4/1/25.
//

import SwiftUI

// MARK: - Loading Screen
struct SplashScreen: View {
    var body: some View {
        ZStack {
            Color.appBlue.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "map.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                
                Text("Niagara Falls")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Loading spinner removed as requested
            }
        }
    }
}

// MARK: - Main App View
struct MainTabView: View {
    @StateObject var appState = AppState()
    
    var body: some View {
        Group {
            if appState.isLoading {
                SplashScreen()
                    .environmentObject(appState)
            } else {
                TabView(selection: $appState.selectedTab) {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(0)
                    
                    ExploreView()
                        .tabItem {
                            Label("Explore", systemImage: "map.fill")
                        }
                        .tag(1)
                    
                    ToursView()
                        .tabItem {
                            Label("Tours", systemImage: "figure.walk")
                        }
                        .tag(2)
                    
                    CalendarView()
                        .tabItem {
                            Label("Events", systemImage: "calendar")
                        }
                        .tag(3)
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                        .tag(4)
                }
                .accentColor(.appBlue)
                .environmentObject(appState)
            }
        }
    }
}
