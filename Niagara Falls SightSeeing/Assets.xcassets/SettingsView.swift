//
//  SettingsView.swift
//  Niagara Falls SightSeeing
//
//  Created by Michael Kot on 4/1/25.
//

import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @State private var downloadMaps = true
    @State private var audioGuide = true
    @State private var notifications = true
    @State private var darkMode = false
    @State private var language = "English"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("App Preferences")) {
                    Toggle("Download Maps for Offline", isOn: $downloadMaps)
                    Toggle("Audio Guide", isOn: $audioGuide)
                    Toggle("Notifications", isOn: $notifications)
                    Toggle("Dark Mode", isOn: $darkMode)
                    
                    Picker("Language", selection: $language) {
                        Text("English").tag("English")
                        Text("Hindu").tag("Hindu")
                    }
                }
                
                Section(header: Text("Account")) {
                    NavigationLink(destination: Text("Profile Settings")) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.appBlue)
                            Text("Profile")
                        }
                    }
                    
                    NavigationLink(destination: Text("Subscription Details")) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.appBlue)
                            Text("Subscription")
                        }
                    }
                }
                
                Section(header: Text("Support")) {
                    NavigationLink(destination: Text("Help Center")) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.appBlue)
                            Text("Help Center")
                        }
                    }
                    
                    NavigationLink(destination: Text("Contact Us")) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.appBlue)
                            Text("Contact Us")
                        }
                    }
                    
                    NavigationLink(destination: Text("About")) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.appBlue)
                            Text("About")
                        }
                    }
                }
                
                Section {
                    Button(action: {}) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
