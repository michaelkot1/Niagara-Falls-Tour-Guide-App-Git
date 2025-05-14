//
//  Models.swift
//  Niagara Falls SightSeeing
//
//  Created by Michael Kot on 4/1/25.
//

import SwiftUI
import MapKit

// MARK: - Attraction Model
struct Attraction: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let coordinate: CLLocationCoordinate2D
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var isLoading = true
    @Published var selectedTab = 0
    
    init() {
        // Simulate loading time
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.isLoading = false
        }
    }
}
