# NiagaraFallsTourApp - GPS Audio Tour Guide

A GPS-based audio tour guide application for Niagara Falls, similar to Shaka Guide. This iOS app provides visitors with an immersive audio experience as they explore the Niagara Falls region.

## Features

- Real-time GPS tracking and navigation
- Automatic audio playback based on location
- Offline map and audio support
- Car audio system integration
- Points of interest with detailed information
- Event calendar for local activities
- User feedback system

## Requirements

- iOS 14.0+
- Xcode 13.0+
- Swift 5.5+
- CocoaPods (for dependencies)

## Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   pod install
   ```
3. Open `NiagaraFallsCursorAI.xcworkspace` in Xcode
4. Build and run the project

## Usage

1. Launch the app and grant location permissions
2. Download offline content when prompted
3. Start the tour from any location
4. Follow the map and listen to audio commentary
5. Explore points of interest at your own pace

## Architecture

The app follows the MVVM architecture pattern and uses SwiftUI for the user interface. Key components include:

- LocationManager: Handles GPS tracking and geofencing
- AudioManager: Manages audio playback and car audio integration
- TourManager: Controls tour content and points of interest
- ContentView: Main interface with map integration

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
