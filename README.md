# NiagaraFallsTourApp - GPS Audio Tour Guide

A GPS-based audio tour guide application for Niagara Falls, similar to Shaka Guide. This iOS app provides visitors with an immersive audio experience as they explore the Niagara Falls region.

## Features

- Real-time GPS tracking and navigation
- Automatic audio playback based on location
- Points of interest with detailed information
- Event calendar for local activities
- Home, Explore, Tours, Events, and Settings sections

## Requirements

- iOS 14.0+
- Xcode 13.0+
- Swift 5.5+

## Installation

1. Clone the repository
2. Open `Niagara Falls SightSeeing.xcodeproj` in Xcode
3. Build and run the project

## Usage

1. Launch the app and grant location permissions
2. Navigate through the tabbed interface to access different features:
   - Home: Quick access to main features
   - Explore: Discover points of interest
   - Tours: Follow guided audio tours
   - Events: View calendar of local activities
   - Settings: Configure app preferences
3. Start the tour from any location
4. Follow the map and listen to audio commentary
5. Explore points of interest at your own pace

## Architecture

The app is built with SwiftUI and follows a component-based architecture. Key components include:

- LocationManager: Handles GPS tracking and location updates
- TourAudioManager: Manages audio playback for tours
- AppState: Controls the application state and navigation
- View Components: HomeView, ExploreView, ToursView, CalendarView, SettingsView

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by Shaka Guide
- Uses MapKit for navigation
- Built with SwiftUI and Core Location
