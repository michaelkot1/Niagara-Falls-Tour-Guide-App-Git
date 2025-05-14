//
//  ToursView.swift
//  Niagara Falls SightSeeing
//
//  Created by Michael Kot on 4/1/25.
//

import SwiftUI
import MapKit
import AVFoundation

// MARK: - Tour Route Manager
class TourRouteManager: ObservableObject {
    // Published properties update the UI when their values change
    @Published var routes: [UUID: MKRoute] = [:] // Stores routes keyed by source stop ID
    @Published var isLoading = false // Indicates if route calculation is in progress
    @Published var routePolylines: [MKPolyline] = [] // Collection of polylines for map display
    
    // Calculates routes between consecutive tour stops using MapKit's routing service
    func generateRoutes(for stops: [TourStop], completion: @escaping (Bool) -> Void) {
        self.isLoading = true
        self.routes = [:]
        self.routePolylines = []
        
        // Need at least two stops to create a route
        guard stops.count >= 2 else {
            self.isLoading = false
            completion(false)
            return
        }
        
        let sortedStops = stops.sorted { $0.order < $1.order }
        let dispatchGroup = DispatchGroup() // Used to track completion of multiple async operations
        var success = true
        
        // Generate routes between consecutive stops
        for i in 0..<(sortedStops.count - 1) {
            let sourceStop = sortedStops[i]
            let destinationStop = sortedStops[i+1]
            
            dispatchGroup.enter()
            calculateRoute(from: sourceStop, to: destinationStop) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let route):
                    DispatchQueue.main.async {
                        self.routes[sourceStop.id] = route
                        self.routePolylines.append(route.polyline)
                    }
                case .failure(_):
                    success = false
                }
                dispatchGroup.leave()
            }
        }
        
        // Once all route calculations are complete, update UI
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            completion(success)
        }
    }
    
    // Helper method to calculate a single route between two tour stops
    private func calculateRoute(from source: TourStop, to destination: TourStop, completion: @escaping (Result<MKRoute, Error>) -> Void) {
        // Convert tour stops to map items for the MapKit directions API
        let sourcePlacemark = MKPlacemark(coordinate: source.coordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destination.coordinate)
        
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        let destinationItem = MKMapItem(placemark: destinationPlacemark)
        
        // Configure the directions request
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = sourceItem
        directionsRequest.destination = destinationItem
        directionsRequest.transportType = .automobile // Assuming driving directions
        
        // Execute the request
        let directions = MKDirections(request: directionsRequest)
        directions.calculate { response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let route = response?.routes.first else {
                completion(.failure(NSError(domain: "TourRouteManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No route found"])))
                return
            }
            
            completion(.success(route))
        }
    }
}

// MARK: - Tour Stop Model
struct TourStop: Identifiable, Equatable, Hashable {
    var id = UUID() // Unique identifier for each stop
    var name: String // Display name of the stop
    var description: String // Brief description of the location
    var coordinate: CLLocationCoordinate2D // Geographic location
    var audioFileName: String // Reference to audio narration file
    var order: Int // Position in the tour sequence
    var imageName: String? // Optional reference to image asset
    
    // Additional properties for enhanced driving tour experience
    var drivingDirections: String // Text instructions to next stop
    var distanceToNextStop: String // Formatted distance to next stop
    var estimatedTimeToNextStop: String // Estimated travel time to next stop
    var nearbyFoodSpots: [FoodSpot]? // Optional array of nearby dining options
    var isAudioPoint: Bool // Indicates if this is a main narration point
    
    // Basic initializer for simple stop creation
    init(name: String, description: String, coordinate: CLLocationCoordinate2D, audioFileName: String, order: Int) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.coordinate = coordinate
        self.audioFileName = audioFileName
        self.order = order
        self.imageName = nil
        self.drivingDirections = ""
        self.distanceToNextStop = ""
        self.estimatedTimeToNextStop = ""
        self.nearbyFoodSpots = []
        self.isAudioPoint = true
    }
    
    // Complete initializer with all properties
    init(name: String,
         description: String,
         coordinate: CLLocationCoordinate2D,
         audioFileName: String,
         order: Int,
         drivingDirections: String,
         distanceToNextStop: String,
         estimatedTimeToNextStop: String,
         nearbyFoodSpots: [FoodSpot]?,
         isAudioPoint: Bool,
         imageName: String? = nil) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.coordinate = coordinate
        self.audioFileName = audioFileName
        self.order = order
        self.imageName = imageName
        self.drivingDirections = drivingDirections
        self.distanceToNextStop = distanceToNextStop
        self.estimatedTimeToNextStop = estimatedTimeToNextStop
        self.nearbyFoodSpots = nearbyFoodSpots
        self.isAudioPoint = isAudioPoint
    }
    
    // Required for Equatable conformance
    static func == (lhs: TourStop, rhs: TourStop) -> Bool {
        lhs.id == rhs.id
    }
    
    // Required for Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Tour Spot Model (Off-route Points of Interest)
struct TourSpot: Identifiable, Hashable, Equatable {
    var id = UUID() // Unique identifier for each spot
    var name: String // Display name of the spot
    var description: String // Detailed description of the location
    var location: String // Human-readable location/address
    var coordinate: CLLocationCoordinate2D // Geographic location
    var category: SpotCategory // Type of point of interest
    var website: String // Web URL for more information
    var rating: Double? // Optional rating for food spots
    var cuisine: String? // Optional cuisine type for food spots
    
    // Categories for different types of points of interest
    enum SpotCategory: String {
        case nature = "Nature"
        case attraction = "Attraction"
        case activity = "Activity"
        case historic = "Historic"
        case viewpoint = "Viewpoint"
        case restaurant = "Restaurant"
        case cafe = "Café"
        case fastFood = "Fast Food"
    }
    
    // Factory method to convert a FoodSpot into a TourSpot
    // for unified display and handling
    static func fromFoodSpot(_ foodSpot: FoodSpot) -> TourSpot {
        let category: SpotCategory
        
        // Determine the appropriate category based on cuisine description
        if foodSpot.cuisine.lowercased().contains("café") ||
           foodSpot.cuisine.lowercased().contains("cafe") ||
           foodSpot.cuisine.lowercased().contains("coffee") {
            category = .cafe
        } else if foodSpot.cuisine.lowercased().contains("fast") ||
                  foodSpot.cuisine.lowercased().contains("snack") {
            category = .fastFood
        } else {
            category = .restaurant
        }
        
        return TourSpot(
            id: UUID(),
            name: foodSpot.name,
            description: foodSpot.description,
            location: "Niagara Falls, near \(foodSpot.name)",
            coordinate: foodSpot.coordinate,
            category: category,
            website: "niagarafalls.com",
            rating: foodSpot.rating,
            cuisine: foodSpot.cuisine
        )
    }
    
    // Required for Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Required for Equatable conformance
    static func == (lhs: TourSpot, rhs: TourSpot) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Food Spot Model
struct FoodSpot: Identifiable, Hashable, Equatable {
    var id = UUID() // Unique identifier for each food spot
    var name: String // Name of the restaurant or food establishment
    var description: String // Brief description of the food spot
    var cuisine: String // Type of cuisine offered
    var coordinate: CLLocationCoordinate2D // Geographic location
    var rating: Double // User rating (typically 1-5 scale)
    
    // Required for Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Required for Equatable conformance
    static func == (lhs: FoodSpot, rhs: FoodSpot) -> Bool {
        // Compare by id, which is unique for each food spot
        lhs.id == rhs.id
    }
}

// MARK: - Tour Model
struct TourModel: Identifiable {
    var id = UUID() // Unique identifier for each tour
    var name: String // Display name of the tour
    var description: String // Brief description of the tour experience
    var duration: String // Human-readable duration (e.g., "Full Day", "2 Hours")
    var stops: [TourStop] // Ordered collection of tour stops
    var tourSpots: [TourSpot]  // Additional points of interest not on the main route
    var isPremium: Bool // Whether this is a premium/paid tour
    var rating: Double // User rating (typically 1-5 scale)
    var coverImage: String? // Reference to image asset for tour thumbnail
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager() // Core Location manager instance
    @Published var location: CLLocation? // Published property to notify views of location updates
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // Request highest accuracy
        locationManager.requestWhenInUseAuthorization() // Request permission while app is in use
        locationManager.startUpdatingLocation() // Begin receiving location updates
    }
    
    // Called by Core Location when new locations are available
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
    }
}

// MARK: - Tours View
struct ToursView: View {
    // Sample tour data
    let tours = [
        TourModel(
            name: "Niagara Falls Classic Tour",
            description: "Experience the beauty and power of Niagara Falls on both sides of the border",
            duration: "Full Day",
            stops: [
                TourStop(
                    name: "Niagara Parks Power Station & Tunnel",
                    description: "This 115-year-old former hydroelectric station offers tours of its preserved generator hall and a 2,200-foot tailrace tunnel.",
                    coordinate: CLLocationCoordinate2D(latitude: 43.074895, longitude: -79.078176),
                    audioFileName: "power_station_audio",
                    order: 1,
                    drivingDirections: "Start at the Power Station and head north on Niagara Parkway for about 0.5 km to reach Table Rock and the brink of the Falls.",
                    distanceToNextStop: "0.5 km",
                    estimatedTimeToNextStop: "2 mins",
                    nearbyFoodSpots: [
                        FoodSpot(
                            name: "Power Station Café",
                            description: "Light fare in historic setting",
                            cuisine: "Café",
                            coordinate: CLLocationCoordinate2D(latitude: 43.074995, longitude: -79.078276),
                            rating: 4.2
                        )
                    ],
                    isAudioPoint: true,
                    imageName: "niagara-parks-power-station"
                ),
                TourStop(
                    name: "Brink of the Falls (Table Rock)",
                    description: "Stand mere meters from the thundering cascade as 2,800 m³ of water plunge over the crest each second.",
                    coordinate: CLLocationCoordinate2D(latitude: 43.079154, longitude: -79.078442),
                    audioFileName: "table_rock_audio",
                    order: 2,
                    drivingDirections: "From Table Rock, continue north on Niagara Parkway (downriver). Keep left on Niagara Parkway as it curves downhill, then turn right onto River Road toward Hornblower Cruises.",
                    distanceToNextStop: "1.5 km",
                    estimatedTimeToNextStop: "5 mins",
                    nearbyFoodSpots: [
                        FoodSpot(
                            name: "Table Rock Restaurant",
                            description: "Fine dining overlooking the Falls",
                            cuisine: "Canadian",
                            coordinate: CLLocationCoordinate2D(latitude: 43.079254, longitude: -79.078542),
                            rating: 4.5
                        ),
                        FoodSpot(
                            name: "Tim Hortons",
                            description: "Canadian coffee chain",
                            cuisine: "Coffee & Snacks",
                            coordinate: CLLocationCoordinate2D(latitude: 43.079054, longitude: -79.078342),
                            rating: 4.0
                        )
                    ],
                    isAudioPoint: true,
                    imageName: "brink-of-the-falls"
                ),
                TourStop(
                    name: "Niagara City Cruises (Hornblower)",
                    description: "Embark on a breathtaking 20-minute voyage to the base of the falls with 360° views of all three waterfalls.",
                    coordinate: CLLocationCoordinate2D(latitude: 43.089151, longitude: -79.073060),
                    audioFileName: "hornblower_audio",
                    order: 3,
                    drivingDirections: "Exit and turn left onto River Road toward the Rainbow Bridge. After 200m, turn left up Clifton Hill.",
                    distanceToNextStop: "0.3 km",
                    estimatedTimeToNextStop: "3 mins",
                    nearbyFoodSpots: [
                        FoodSpot(
                            name: "Riverside Patio",
                            description: "Casual dining with river views",
                            cuisine: "American",
                            coordinate: CLLocationCoordinate2D(latitude: 43.089251, longitude: -79.073160),
                            rating: 4.0
                        )
                    ],
                    isAudioPoint: true,
                    imageName: "niagara-city-cruises"
                ),
                TourStop(
                    name: "Clifton Hill Entertainment Strip",
                    description: "Niagara Falls' famous tourist promenade packed with attractions, arcades, and themed restaurants.",
                    coordinate: CLLocationCoordinate2D(latitude: 43.0912, longitude: -79.0745),
                    audioFileName: "clifton_hill_audio",
                    order: 4,
                    drivingDirections: "At the top of Clifton Hill, turn right onto Victoria Avenue. Proceed 300m until you see the Skylon Tower.",
                    distanceToNextStop: "0.5 km",
                    estimatedTimeToNextStop: "3 mins",
                    nearbyFoodSpots: [
                        FoodSpot(
                            name: "Rainforest Café",
                            description: "Themed restaurant with animatronic animals",
                            cuisine: "American",
                            coordinate: CLLocationCoordinate2D(latitude: 43.0915, longitude: -79.0747),
                            rating: 3.9
                        ),
                        FoodSpot(
                            name: "Boston Pizza",
                            description: "Family-friendly pizza chain",
                            cuisine: "Italian",
                            coordinate: CLLocationCoordinate2D(latitude: 43.0918, longitude: -79.0749),
                            rating: 4.0
                        )
                    ],
                    isAudioPoint: true,
                    imageName: "clifton-hill"
                ),
                TourStop(
                    name: "Skylon Tower",
                    description: "A 160m observation tower offering panoramic views of the falls and surrounding areas up to 125km away.",
                    coordinate: CLLocationCoordinate2D(latitude: 43.085280, longitude: -79.079720),
                    audioFileName: "skylon_tower_audio",
                    order: 5,
                    drivingDirections: "Exit the Skylon lot and head to Niagara Parkway. Continue on Niagara Parkway for 25km all the way to Niagara-on-the-Lake.",
                    distanceToNextStop: "25 km",
                    estimatedTimeToNextStop: "30 mins",
                    nearbyFoodSpots: [
                        FoodSpot(
                            name: "Skylon Revolving Dining Room",
                            description: "Fine dining with 360° views",
                            cuisine: "International",
                            coordinate: CLLocationCoordinate2D(latitude: 43.085380, longitude: -79.079820),
                            rating: 4.4
                        ),
                        FoodSpot(
                            name: "Summit Suite Buffet",
                            description: "All-you-can-eat with Falls views",
                            cuisine: "International",
                            coordinate: CLLocationCoordinate2D(latitude: 43.085280, longitude: -79.079620),
                            rating: 3.9
                        )
                    ],
                    isAudioPoint: true,
                    imageName: "skylon-tower"
                ),
                TourStop(
                    name: "Historic Niagara-on-the-Lake",
                    description: "A well-preserved 19th-century village with heritage buildings, boutiques, and waterfront views.",
                    coordinate: CLLocationCoordinate2D(latitude: 43.255111, longitude: -79.071490),
                    audioFileName: "niagara_on_the_lake_audio",
                    order: 6,
                    drivingDirections: "From NOTL, head south toward Niagara Falls. Follow signs for Rainbow Bridge.",
                    distanceToNextStop: "19 km",
                    estimatedTimeToNextStop: "25 mins",
                    nearbyFoodSpots: [
                        FoodSpot(
                            name: "The Olde Angel Inn",
                            description: "Historic pub in Ontario's oldest operating inn",
                            cuisine: "British Pub",
                            coordinate: CLLocationCoordinate2D(latitude: 43.255411, longitude: -79.071690),
                            rating: 4.5
                        ),
                        FoodSpot(
                            name: "Treadwell Cuisine",
                            description: "Farm-to-table fine dining",
                            cuisine: "Canadian",
                            coordinate: CLLocationCoordinate2D(latitude: 43.255311, longitude: -79.071590),
                            rating: 4.7
                        )
                    ],
                    isAudioPoint: true,
                    imageName: "niagara-on-the-lake"
                ),
                TourStop(
                    name: "Rainbow Bridge",
                    description: "Cross the Rainbow Bridge for spectacular views of all three falls as you enter the USA.",
                    coordinate: CLLocationCoordinate2D(latitude: 43.090233, longitude: -79.067744),
                    audioFileName: "rainbow_bridge_audio",
                    order: 7,
                    drivingDirections: "After crossing the bridge into the USA, follow signs for Niagara Falls State Park.",
                    distanceToNextStop: "1.5 km",
                    estimatedTimeToNextStop: "5 mins",
                    nearbyFoodSpots: [
                        FoodSpot(
                            name: "Queen Victoria Place Restaurant",
                            description: "Historic dining with falls views",
                            cuisine: "Canadian",
                            coordinate: CLLocationCoordinate2D(latitude: 43.090333, longitude: -79.067844),
                            rating: 4.1
                        )
                    ],
                    isAudioPoint: true,
                    imageName: "rainbow-bridge"
                ),
                TourStop(
                    name: "Niagara Falls State Park (USA)",
                    description: "The oldest state park in the USA offers unparalleled views of American Falls and access to Maid of the Mist boats.",
                    coordinate: CLLocationCoordinate2D(latitude: 43.083714, longitude: -79.065147),
                    audioFileName: "state_park_audio",
                    order: 8,
                    drivingDirections: "From the State Park, follow signs for Goat Island. Cross the bridge to the island and park in Lot 2.",
                    distanceToNextStop: "1 km",
                    estimatedTimeToNextStop: "5 mins",
                    nearbyFoodSpots: [
                        FoodSpot(
                            name: "Top of the Falls Restaurant",
                            description: "Dining with panoramic falls views",
                            cuisine: "American",
                            coordinate: CLLocationCoordinate2D(latitude: 43.083814, longitude: -79.065247),
                            rating: 4.2
                        )
                    ],
                    isAudioPoint: true,
                    imageName: "niagara-falls-state-park"
                ),
                TourStop(
                    name: "Goat Island & Terrapin Point",
                    description: "Stand at the brink of Horseshoe Falls from the U.S. side and experience the Hurricane Deck near Bridal Veil Falls.",
                    coordinate: CLLocationCoordinate2D(latitude: 43.080060, longitude: -79.074140),
                    audioFileName: "goat_island_audio",
                    order: 9,
                    drivingDirections: "Exit Goat Island and follow signs to return to Canada via Rainbow Bridge. This completes your tour loop.",
                    distanceToNextStop: "2 km",
                    estimatedTimeToNextStop: "10 mins",
                    nearbyFoodSpots: [
                        FoodSpot(
                            name: "Cave of the Winds Café",
                            description: "Quick bites near the Hurricane Deck",
                            cuisine: "Snacks",
                            coordinate: CLLocationCoordinate2D(latitude: 43.080160, longitude: -79.074240),
                            rating: 3.8
                        )
                    ],
                    isAudioPoint: true,
                    imageName: "goat-island"
                )
            ],
            tourSpots: [
                TourSpot(
                    name: "Dufferin Islands Park",
                    description: "A tranquil 10-acre nature reserve of small islands just south of Horseshoe Falls. Winding paths and rustic footbridges connect these secluded islands, offering a peaceful escape from the crowds. It's a local hidden gem for picnics and birdwatching – you might spot ducks, herons, or even deer. Especially enchanting during the Winter Festival of Lights (Nov–Jan) when illuminated displays adorn the islands.",
                    location: "Follow the Niagara Parkway ~1 km upstream of Table Rock, entrance on the right.",
                    coordinate: CLLocationCoordinate2D(latitude: 43.0686, longitude: -79.0707),
                    category: .nature,
                    website: "niagaraparks.com"
                ),
                TourSpot(
                    name: "Journey Behind the Falls",
                    description: "A classic Niagara experience at Table Rock Center: descend 125 ft by elevator into 130-year-old tunnels through the bedrock behind Horseshoe Falls. You'll emerge to two observation portals directly behind the sheet of falling water, plus an outdoor deck at the base of Horseshoe Falls. Feel the vibration of one-fifth of the world's fresh water crashing down in front of you – an unforgettable perspective from behind Niagara Falls. (Open year-round; rain ponchos provided for the mist.)",
                    location: "Entrance inside Table Rock Welcome Centre.",
                    coordinate: CLLocationCoordinate2D(latitude: 43.0792, longitude: -79.0784),
                    category: .attraction,
                    website: "niagarafallstourism.com"
                ),
                TourSpot(
                    name: "Whirlpool Aero Car",
                    description: "An antique cable car ride that soars above the swirling Niagara Whirlpool. Operating since 1916, this open-air gondola (designed by Spanish engineer Leonardo Torres Quevedo) transports up to 35 passengers across a section of the Niagara River and back. Mid-span you'll be suspended 250 feet over the Niagara Whirlpool, a giant turbulent pool formed where the river makes a sharp turn. It's a ten-minute round-trip with 360° views of the gorge and rapids.",
                    location: "3850 Niagara Parkway, about 6 km north of Niagara Falls. Look for the Aero Car plaza on the left when driving north.",
                    coordinate: CLLocationCoordinate2D(latitude: 43.11798, longitude: -79.06877),
                    category: .attraction,
                    website: "en.wikipedia.org"
                ),
                TourSpot(
                    name: "White Water Walk",
                    description: "A self-guided boardwalk at the edge of the Niagara Rapids. An elevator takes you down 70 m into the gorge near the Whirlpool Rapids – class 6 white-water rapids among the wildest in North America. A 305 m (1,000 ft) riverside boardwalk lets you stroll mere feet from the thundering water as it crashes past at 48 km/h. Viewing platforms put you face-to-face with the power of the Niagara River's fastest section. It's a short but awe-inspiring walk for a close encounter with the raw force of nature (and great photos of the turbulent water!).",
                    location: "4330 Niagara Parkway, about 4 km north of the falls, just south of the Whirlpool Bridge.",
                    coordinate: CLLocationCoordinate2D(latitude: 43.1190, longitude: -79.0570),
                    category: .activity,
                    website: "niagarafallslive.com"
                ),
                TourSpot(
                    name: "Niagara Parks Butterfly Conservatory",
                    description: "An indoor tropical paradise home to over 2,000 free-flying butterflies of 45+ species. Stroll through lush rainforest greenery and blooming flowers as delicate butterflies flit all around you – often landing on visitors. Opened in 1996, this climate-controlled conservatory features a 11,000 sq ft glass dome and 180 m of pathways winding past waterfalls and ponds. It's a magical experience, perfect for families and nature lovers.",
                    location: "2405 Niagara Parkway, on the grounds of the Botanical Gardens ~9 km north of the falls.",
                    coordinate: CLLocationCoordinate2D(latitude: 43.1357, longitude: -79.0533),
                    category: .attraction,
                    website: "en.wikipedia.org"
                ),
                TourSpot(
                    name: "Niagara Floral Clock",
                    description: "A gigantic 40-ft diameter working clock made entirely of flowers. This horticultural marvel is carpeted with over 16,000 plants, changed twice annually to new designs. It's one of the world's largest floral clocks and a popular photo stop. Visitors can also see the clock's mechanisms behind it when the small tower is open. Built in 1950 by Ontario Hydro, the Floral Clock has been lovingly maintained for over 70 years and chimes on the quarter hour.",
                    location: "14004 Niagara Parkway, just north of the Botanical Gardens – about 11 km north of Niagara Falls.",
                    coordinate: CLLocationCoordinate2D(latitude: 43.149443, longitude: -79.047295),
                    category: .attraction,
                    website: "atlasobscura.com"
                ),
                TourSpot(
                    name: "Brock's Monument (Queenston Heights)",
                    description: "A towering 56 m limestone column atop Queenston Heights, dedicated to Sir Isaac Brock, a hero of the War of 1812. Major General Brock died defending Upper Canada at the Battle of Queenston Heights (1812), which took place on this very hill. The monument (built 1853–56 to replace an earlier one) marks the battlefield and houses Brock's tomb at its base. You can climb 235 steps inside to a viewing deck for a sweeping view of the Niagara region. Even from the ground, the site offers great vistas of the Niagara River and Lewiston, NY across the gorge.",
                    location: "Queenston Heights Park, off Niagara Parkway ~12 km north of the falls. Look for park entrance on left; monument is visible from road.",
                    coordinate: CLLocationCoordinate2D(latitude: 43.160139, longitude: -79.053056),
                    category: .historic,
                    website: "en.wikipedia.org"
                ),
                TourSpot(
                    name: "Maid of the Mist (U.S. Boat Tour)",
                    description: "The American counterpart to Hornblower, Maid of the Mist is the original Niagara Falls boat tour, operating continuously since 1846. Running from the U.S. side, it launches from Niagara Falls State Park. Today's Maid of the Mist boats are all-electric, emission-free vessels, but the experience remains the same – a half-hour journey into the mist of both the American and Horseshoe Falls. Access is via the Observation Tower elevator at Prospect Point. If you didn't ride Hornblower in Canada, this is a fantastic way to get up close to the falls from the U.S. side. Blue ponchos are provided (and very necessary!).",
                    location: "Prospect Point, Niagara Falls State Park – entrance via the Observation Tower.",
                    coordinate: CLLocationCoordinate2D(latitude: 43.086442, longitude: -79.068389),
                    category: .activity,
                    website: "niagarafallsusa.com"
                ),
                TourSpot(
                    name: "Cave of the Winds",
                    description: "An immersive adventure that takes you down into the Niagara Gorge on the U.S. side to feel the force of Bridal Veil Falls. After a brief exhibit on Niagara's natural history and Tesla's work, you'll ride an elevator 175 feet down through the rock. Outfitted in a poncho and sandals, you then walk on a series of wooden boardwalks to the Hurricane Deck, an observation platform just a few feet from Bridal Veil Falls. The rush of wind and water here is like standing in a tropical storm – an utterly thrilling sensory experience! You will get soaked (ponchos or not), but it's exhilarating to be that close to the crashing falls. (Open May–Oct for full access; an abbreviated Gorge Trip operates in winter.)",
                    location: "Goat Island, behind the Cave of the Winds Pavilion. Timed tickets required; entrance near Parking Lot 2.",
                    coordinate: CLLocationCoordinate2D(latitude: 43.082376, longitude: -79.071029),
                    category: .attraction,
                    website: "niagarafallsusa.com"
                ),
                TourSpot(
                    name: "Whirlpool State Park",
                    description: "A peaceful New York state park overlooking the Niagara Whirlpool and rapids from the U.S. side. The park has two levels: the street-level rim with scenic overlooks of the Whirlpool far below, and a lower riverbank level reached by a hiking trail/stairway (for experienced hikers). From the marked overlook points, you get a great view into the striking turquoise Whirlpool and the Aero Car crossing overhead on the Canadian side. It's a quieter spot to appreciate the geology of the Niagara Gorge and watch the Class V rapids upstream funnel into a swirling vortex. Picnic tables, restrooms, and walking trails make it a nice respite.",
                    location: "Along the Niagara Scenic Parkway ~7 km north of Niagara Falls, NY. Access via Whirlpool State Park parking lot on Robert Moses Pkwy.",
                    coordinate: CLLocationCoordinate2D(latitude: 43.117000, longitude: -79.060997),
                    category: .nature,
                    website: "parks.ny.gov"
                )
            ],
            isPremium: true,
            rating: 4.8,
            coverImage: "niagara-falls-state-park"
        )
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Featured Tours")) {
                    ForEach(tours) { tour in
                        NavigationLink(destination: TourDetailView(tour: tour)) {
                            TourListItem(tour: tour)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Tours")
        }
    }
}

// MARK: - Tour List Item
struct TourListItem: View {
    var tour: TourModel
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack(alignment: .topLeading) {
                if let imageName = tour.coverImage {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(10)
                } else {
                    Rectangle()
                        .fill(Color.appBlue.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .cornerRadius(10)
                }
                
                if tour.isPremium {
                    Text("PREMIUM")
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(5)
                        .padding(5)
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(tour.name)
                    .font(.headline)
                
                Text(tour.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", tour.rating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text(tour.duration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text("\(tour.stops.count) stops")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Tour Detail View
struct TourDetailView: View {
    var tour: TourModel
    @State private var showMap = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header image
                ZStack(alignment: .bottomLeading) {
                    if let imageName = tour.coverImage {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.appBlue.opacity(0.3))
                            .frame(height: 200)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(tour.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(tour.description)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Tour details
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Duration")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(tour.duration)
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Stops")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(tour.stops.count)")
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Rating")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                Text(String(format: "%.1f", tour.rating))
                                    .font(.headline)
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Tour stops
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tour Stops")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(tour.stops.sorted { $0.order < $1.order }) { stop in
                                    StopPreviewCard(stop: stop)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About This Tour")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Text("This guided tour takes you through the most iconic spots of Niagara Falls. You'll learn about the history, geology, and fascinating stories behind one of the world's most famous natural wonders. The tour includes exclusive narration by local experts and historians.")
                            .font(.body)
                            .padding(.horizontal)
                        
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                showMap = true
                            }) {
                                Text("Start Tour")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 200)
                                    .padding()
                                    .background(Color.appBlue)
                                    .cornerRadius(12)
                            }
                            
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showMap) {
            TourMapView(tour: tour)
        }
    }
}

// MARK: - Stop Preview Card
struct StopPreviewCard: View {
    var stop: TourStop
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                if let imageName = stop.imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 80)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    Rectangle()
                        .fill(Color.appBlue.opacity(0.2))
                        .frame(width: 120, height: 80)
                        .cornerRadius(8)
                }
                
                Text("#\(stop.order)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(5)
                    .background(Color.appBlue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(5)
            }
            
            Text(stop.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .frame(width: 120, alignment: .leading)
                
            Text(stop.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .frame(width: 120, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 8)
    }
}

extension TimeInterval {
    // Formats a time interval (in seconds) as a MM:SS string
    // For example, 125.3 seconds becomes "2:05"
    func formatAsMinutesSeconds() -> String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Tour Audio Manager
class TourAudioManager: NSObject, ObservableObject {
    private var audioPlayer: AVAudioPlayer? // Handles audio playback
    @Published var isPlaying = false // Indicates if audio is currently playing
    @Published var currentStopIndex = 0 // Index of the current tour stop
    @Published var currentTime: TimeInterval = 0 // Current playback position
    @Published var duration: TimeInterval = 0 // Total duration of current audio
    private var timer: Timer? // Timer to update currentTime during playback
    
    // Plays audio file associated with a tour stop
    func playAudio(filename: String) {
        // First stop any currently playing audio
        stopAudio()
        
        // Map the filename to the actual MP3 file
        // This mapping allows reusing a limited set of audio files for multiple stops
        var actualFilename = ""
        switch filename {
            case "table_rock_audio", "power_station_audio", "hornblower_audio", "clifton_hill_audio":
                actualFilename = "horseshoe falls" // Reuse existing audio for new points
            case "skylon_tower_audio":
                actualFilename = "skylon tower"
            case "niagara_on_the_lake_audio", "state_park_audio", "goat_island_audio":
                actualFilename = "american falls" // Reuse existing audio for new points
            case "rainbow_bridge_audio":
                actualFilename = "niagara whirpools" // Use existing audio
            default:
                actualFilename = "horseshoe falls" // Default fallback
        }
        
        guard let path = Bundle.main.path(forResource: actualFilename, ofType: "mp3") else {
            print("Could not find audio file: \(actualFilename).mp3")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            // Configure audio session for playback
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Initialize audio player
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            // Start playing and update state
            audioPlayer?.play()
            isPlaying = true
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            
            // Start timer to update current time
            startTimer()
            
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }
    
    // Pauses current audio playback
    func pauseAudio() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    // Resumes paused audio playback
    func resumeAudio() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }
    
    // Stops audio playback completely and resets state
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        stopTimer()
    }
    
    // Seeks to a specific time in the audio
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    // Starts a timer to update currentTime during playback
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
        }
    }
    
    // Stops the update timer
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - TourAudioManager Audio Delegate
extension TourAudioManager: AVAudioPlayerDelegate {
    // Called when audio playback completes
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
        stopTimer()
    }
    
    // Called when an error occurs during playback
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("Audio player decode error: \(error.localizedDescription)")
        }
        stopAudio()
    }
}

// MARK: - Approaching Banner
struct ApproachingBanner: View {
    var stop: TourStop
    
    var body: some View {
        // Banner that appears when user is approaching a tour stop
        // Provides visual notification that a new tour point is nearby
        HStack {
            Image(systemName: "location.fill")
                .foregroundColor(.white)
                .padding(8)
                .background(Circle().fill(Color.appBlue))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Approaching")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(stop.name)
                .font(.headline)
                    .foregroundColor(.appBlue)
            }
            
            Spacer()
            
            Button {
                // Do nothing, just a visual indicator
            } label: {
                Text("Coming Up")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.appBlue.opacity(0.2))
                    .foregroundColor(.appBlue)
                    .cornerRadius(12)
            }
            .disabled(true)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Tour Map View (Active Tour Experience)
struct TourMapView: View {
    var tour: TourModel
    @StateObject private var audioManager = TourAudioManager()
    @StateObject private var routeManager = TourRouteManager()
    @State private var position: MapCameraPosition
    @State private var selectedStop: TourStop?
    @State private var showStopDetail = false
    @State private var currentStopIndex = 0
    @State private var showFoodSpots = false
    @State private var selectedTab: TourTab = .audioPoints
    @State private var isPanelExpanded = false
    @State private var selectedFoodSpot: FoodSpot? = nil
    @State private var showAudioPointDetail = false
    @State private var selectedAudioPoint: TourStop? = nil
    @State private var showFoodSpotDetail = false
    @State private var selectedTourSpot: TourSpot? = nil
    @State private var showTourSpotDetail = false
    @State private var showingRouteLoadingIndicator = false
    @State private var showMapLegend = false // Controls visibility of the map legend
    @Environment(\.presentationMode) var presentationMode
    
    // Enum for tab selection in the tour interface
    enum TourTab {
        case audioPoints, tourSpots
    }
    
    // Location manager for tracking user's current location
    @StateObject private var locationManager = LocationManager()
    
    init(tour: TourModel) {
        self.tour = tour
        
        // Sort stops by order before initializing
        let sortedStops = tour.stops.sorted { $0.order < $1.order }
        
        // Initialize map view focused on the first stop's location
        if let firstStop = sortedStops.first {
            let region = MKCoordinateRegion(
                center: firstStop.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
            _position = State(initialValue: .region(region))
        } else {
            // Fallback to Niagara Falls general location if no stops available
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 43.0828, longitude: -79.0742),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            _position = State(initialValue: .region(region))
        }
    }
    
    // Returns tour stops sorted by their order property
    var sortedStops: [TourStop] {
        tour.stops.sorted { $0.order < $1.order }
    }
    
    // Returns the currently active tour stop
    var currentStop: TourStop {
        sortedStops[currentStopIndex]
    }
    
    // Returns the next stop in sequence, or nil if at the last stop
    var nextStop: TourStop? {
        if currentStopIndex < sortedStops.count - 1 {
            return sortedStops[currentStopIndex + 1]
        }
        return nil
    }
    
    // Advances to the next stop in the tour sequence
    func goToNextStop() {
        guard currentStopIndex < sortedStops.count - 1 else { return }
        
        // Stop current audio
        audioManager.stopAudio()
        
        // Move to next stop
        currentStopIndex += 1
        
        // Update map position
        let region = MKCoordinateRegion(
            center: currentStop.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        withAnimation {
            position = .region(region)
        }
        
        // Play audio for new stop
        audioManager.playAudio(filename: currentStop.audioFileName)
    }
    
    // Moves to the previous stop in the tour sequence
    func goToPreviousStop() {
        guard currentStopIndex > 0 else { return }
        
        // Stop current audio
        audioManager.stopAudio()
        
        // Move to previous stop
        currentStopIndex -= 1
        
        // Update map position
        let region = MKCoordinateRegion(
            center: currentStop.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        withAnimation {
            position = .region(region)
        }
        
        // Play audio for new stop
        audioManager.playAudio(filename: currentStop.audioFileName)
    }
    
    // Calculates distance in meters between user location and a map coordinate
    func calculateDistance(from userLocation: CLLocation, to coordinate: CLLocationCoordinate2D) -> Double {
        let stopLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return userLocation.distance(from: stopLocation)
    }
    
    // Returns the appropriate SF Symbol name for each spot category
    func spotIcon(for category: TourSpot.SpotCategory) -> String {
        switch category {
        case .nature:
            return "leaf.fill"
        case .attraction:
            return "star.fill"
        case .activity:
            return "figure.walk"
        case .historic:
            return "building.columns.fill"
        case .viewpoint:
            return "binoculars.fill"
        case .restaurant:
            return "fork.knife.circle.fill"
        case .cafe:
            return "cup.and.saucer.fill"
        case .fastFood:
            return "fork.knife"
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Map
                Map(position: $position, selection: $selectedStop) {
                    // User location
                    UserAnnotation()
                    
                    // Tour stops - always show on map regardless of mode
                    ForEach(Array(sortedStops.enumerated()), id: \.element.id) { index, stop in
                        Annotation(stop.name, coordinate: stop.coordinate) {
                            Button {
                                // Show stop detail when clicked
                                selectedAudioPoint = stop
                                // Ensure the boolean is set after the stop is assigned
                                DispatchQueue.main.async {
                                    showAudioPointDetail = true
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(stop.order == currentStop.order ? Color.red : Color.appBlue)
                                        .frame(width: 30, height: 30)
                                    Text("\(stop.order)")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                        }
                        .tag(stop)
                    }
                    
                    // Show food spots if in Tour Spots mode
                    if selectedTab == .tourSpots {
                        ForEach(currentStop.nearbyFoodSpots ?? [], id: \.id) { foodSpot in
                            Annotation(foodSpot.name, coordinate: foodSpot.coordinate) {
                                Button {
                                    // Show the food spot detail view
                                    self.selectedFoodSpot = foodSpot
                                    // Ensure the boolean is set after the food spot is assigned
                                    DispatchQueue.main.async {
                                        showFoodSpotDetail = true
                                    }
                                } label: {
                                    Image(systemName: "fork.knife.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.orange)
                                        .shadow(radius: 1)
                                }
                            }
                        }
                    }
                    
                    // Show tour spots if in Tour Spots mode
                    if selectedTab == .tourSpots {
                        // Show regular tour spots
                        ForEach(tour.tourSpots) { spot in
                            Annotation(spot.name, coordinate: spot.coordinate) {
                                Button {
                                    // Show the tour spot detail view
                                    selectedTourSpot = spot
                                    
                                    // Center the map on the selected spot
                                    let region = MKCoordinateRegion(
                                        center: spot.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                    )
                                    withAnimation {
                                        position = .region(region)
                                    }
                                    
                                    // Ensure the boolean is set after the spot is assigned
                                    DispatchQueue.main.async {
                                        showTourSpotDetail = true
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 36, height: 36)
                                            .shadow(radius: 2)
                                        
                                        Image(systemName: spotIcon(for: spot.category))
                                            .font(.system(size: 18))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        
                        // Show all food spots from all tour stops
                        ForEach(sortedStops, id: \.id) { stop in
                            if let foodSpots = stop.nearbyFoodSpots {
                                ForEach(foodSpots, id: \.id) { foodSpot in
                                    Annotation(foodSpot.name, coordinate: foodSpot.coordinate) {
                                        Button {
                                            // Show the food spot detail view
                                            self.selectedFoodSpot = foodSpot
                                            // Ensure the boolean is set after the food spot is assigned
                                            DispatchQueue.main.async {
                                                showFoodSpotDetail = true
                                            }
                                        } label: {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.orange)
                                                    .frame(width: 36, height: 36)
                                                    .shadow(radius: 2)
                                                
                                                Image(systemName: "fork.knife.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // In Tour Spots mode, don't show any connecting lines
                        // MapPolyline removed to hide audio point connections when in Tour Spots mode
                    } else if selectedTab == .audioPoints {
                        // In Audio Points mode, show road-following routes when available
                        if !routeManager.routePolylines.isEmpty {
                            // Display all road-following routes between stops
                            ForEach(routeManager.routePolylines, id: \.self) { polyline in
                                MapPolyline(polyline)
                                    .stroke(.appBlue, lineWidth: 4)
                            }
                        } else {
                            // Fallback to straight line if routes couldn't be generated
                            MapPolyline(coordinates: sortedStops.map { $0.coordinate })
                                .stroke(.appBlue, lineWidth: 3)
                        }
                    }
                }
                .mapControls {
                    MapCompass()
                    MapScaleView()
                    MapUserLocationButton()
                }
                .onChange(of: selectedStop) { oldValue, newValue in
                    if let stop = newValue {
                        // Center on the selected stop
                        let region = MKCoordinateRegion(
                            center: stop.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                        withAnimation {
                            position = .region(region)
                        }
                        
                        // If a different stop is selected manually, pause current audio
                        if stop.order != currentStop.order {
                            audioManager.pauseAudio()
                        }
                    }
                }
                .ignoresSafeArea()
                
                // Modern bottom UI
                VStack {
                    Spacer()
                    
                    // Current location banner when approaching stops
                    if let userLocation = locationManager.location {
                        ForEach(sortedStops.filter {
                            calculateDistance(from: userLocation, to: $0.coordinate) < 100 &&
                            $0.order > currentStopIndex
                        }, id: \.id) { stop in
                            ApproachingBanner(stop: stop)
                                .transition(.move(edge: .bottom))
                                .animation(.default, value: currentStopIndex)
                                .onAppear {
                                    // Auto-advance to this stop when in range
                                    if stop.order > currentStopIndex {
                                        // If already playing something, stop it
                                        audioManager.stopAudio()
                                        
                                        // Find the index of this stop
                                        if let index = sortedStops.firstIndex(where: { $0.id == stop.id }) {
                                            currentStopIndex = index
                                            withAnimation {
                                                let region = MKCoordinateRegion(
                                                    center: stop.coordinate,
                                                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                                )
                                                position = .region(region)
                                            }
                                            
                                            // Play the audio for this stop
                                            audioManager.playAudio(filename: stop.audioFileName)
                                        }
                                    }
                                }
                        }
                    }
                    
                    // Modern UI controls
                    VStack(spacing: 0) {
                        // Toggle buttons at top
                        HStack(spacing: 0) {
                            Button {
                                selectedTab = .audioPoints
                            } label: {
                                Text("Audio Points")
                                    .font(.headline)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedTab == .audioPoints ? Color.appBlue : Color.white)
                                    .foregroundColor(selectedTab == .audioPoints ? .white : .appBlue)
                            }
                            
                            Button {
                                selectedTab = .tourSpots
                                // Ensure any audio continues playing when switching tabs
                            } label: {
                                Text("Tour Spots")
                                    .font(.headline)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedTab == .tourSpots ? Color.appBlue : Color.white)
                                    .foregroundColor(selectedTab == .tourSpots ? .white : .appBlue)
                            }
                        }
                        
                        // Mode indicator and current stop section
                        VStack(spacing: 4) {
                            // Mode indicator
                            Text(selectedTab == .audioPoints ? "Audio Tour" :
                                 selectedTab == .tourSpots ? "Tour Spots" :
                                 "Off-Route Points of Interest")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                            
                            // Current stop name - Hide when in Tour Spots mode
                            if selectedTab != .tourSpots {
                                Text(currentStop.name)
                                    .font(.headline)
                                    .padding(.horizontal)
                                    .padding(.bottom, 4)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                Text("Points of Interest & Food")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                    .padding(.bottom, 4)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            
                            // Toggle button for stops list (for both modes now)
                            Button {
                                withAnimation(.spring()) {
                                    isPanelExpanded.toggle()
                                }
                            } label: {
                        HStack {
                                    Text(isPanelExpanded ? "Hide Content" : "Show Content")
                                .font(.caption)
                                        .foregroundColor(.appBlue)
                                    
                                    Image(systemName: isPanelExpanded ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.appBlue)
                                }
                                .padding(.bottom, 8)
                            }
                        }
                        
                        // Content for either tab - only shown when expanded
                        if isPanelExpanded {
                            if selectedTab == .audioPoints {
                                // Audio Points content - list of stops
                                ScrollView {
                                    VStack(spacing: 0) {
                                        // Show all audio points
                                        ForEach(sortedStops.filter { $0.isAudioPoint }) { stop in
                                            TourStopRow(
                                                stop: stop,
                                                isSelected: stop.order == currentStop.order,
                                                onTap: {
                                                    if let index = sortedStops.firstIndex(where: { $0.id == stop.id }) {
                                                        audioManager.stopAudio()
                                                        currentStopIndex = index
                                                        let region = MKCoordinateRegion(
                                                            center: stop.coordinate,
                                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                                        )
                                                        withAnimation {
                                                            position = .region(region)
                                                        }
                                                        audioManager.playAudio(filename: stop.audioFileName)
                                                    }
                                                },
                                                onInfoTap: {
                                                    // Show the stop detail view
                                                    selectedAudioPoint = stop
                                                    // Ensure the boolean is set after the stop is assigned
                                                    DispatchQueue.main.async {
                                                        showAudioPointDetail = true
                                                    }
                                                }
                                            )
                                            
                                            if sortedStops.filter({ $0.isAudioPoint }).last?.id != stop.id {
                                                Divider()
                                                    .padding(.leading, 50)
                                            }
                                        }
                                    }
                                    .padding(.bottom, 8)
                                }
                                .frame(maxHeight: 200)
                            } else if selectedTab == .tourSpots {
                                // Tour Spots content - list of tour spots
                                ScrollView {
                                    VStack(spacing: 0) {
                                        // Section header for Points of Interest
                                        Text("Points of Interest")
                                            .font(.headline)
                                            .padding(.horizontal, 15)
                                            .padding(.top, 5)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        // Show all tour spots
                                        ForEach(tour.tourSpots) { spot in
                                            TourSpotRow(
                                                spot: spot,
                                                isSelected: spot.id == selectedTourSpot?.id,
                                                onTap: {
                                                    selectedTourSpot = spot
                                                    
                                                    // Center the map on the selected spot
                                                    let region = MKCoordinateRegion(
                                                        center: spot.coordinate,
                                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                                    )
                                                    withAnimation {
                                                        position = .region(region)
                                                    }
                                                    
                                                    // Show the detail view
                                                    showTourSpotDetail = true
                                                },
                                                onInfoTap: {
                                                    // Show the tour spot detail view
                                                    selectedTourSpot = spot
                                                    showTourSpotDetail = true
                                                }
                                            )
                                            
                                            Divider()
                                                .padding(.leading, 50)
                                        }
                                        
                                        // Section header for Food & Drinks
                                        Text("Food & Drinks")
                                            .font(.headline)
                                            .padding(.horizontal, 15)
                                            .padding(.top, 15)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        // Get all food spots from all stops
                                        ForEach(sortedStops, id: \.id) { stop in
                                            if let foodSpots = stop.nearbyFoodSpots, !foodSpots.isEmpty {
                                                ForEach(foodSpots) { foodSpot in
                                                    HStack(spacing: 15) {
                                                        Button {
                                                            // Show the food spot detail view
                                                            self.selectedFoodSpot = foodSpot
                                                            
                                                            // Center on the food spot
                                                            let region = MKCoordinateRegion(
                                                                center: foodSpot.coordinate,
                                                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                                            )
                                                            withAnimation {
                                                                position = .region(region)
                                                            }
                                                            
                                                            // Show the detail view
                                                            DispatchQueue.main.async {
                                                                showFoodSpotDetail = true
                                                            }
                                                        } label: {
                                                            HStack(spacing: 15) {
                                                                // Food icon in circle
                                                                ZStack {
                                                                    Circle()
                                                                        .fill(Color.orange.opacity(0.2))
                                                                        .frame(width: 40, height: 40)
                                                                    
                                                                    Image(systemName: "fork.knife")
                                                                        .font(.system(size: 16))
                                                                        .foregroundColor(.orange)
                                                                }
                                                                
                                                                VStack(alignment: .leading, spacing: 2) {
                                                                    Text(foodSpot.name)
                                                                        .font(.subheadline)
                                                                        .fontWeight(.medium)
                                                                        .foregroundColor(.primary)
                                                                    
                                                                    Text(foodSpot.cuisine)
                                                                        .font(.caption)
                                                                        .foregroundColor(.secondary)
                                                                        .lineLimit(1)
                                                                }
                                                                
                                                                Spacer()
                                                            }
                                                        }
                                                        .buttonStyle(PlainButtonStyle())
                                                        
                                                        Button {
                                                            // Show the food spot detail view
                                                            self.selectedFoodSpot = foodSpot
                                                            DispatchQueue.main.async {
                                                                showFoodSpotDetail = true
                                                            }
                                                        } label: {
                                                            Image(systemName: "info.circle")
                                                                .foregroundColor(.orange)
                                                                .font(.system(size: 20))
                                                        }
                                                        .padding(.trailing, 10)
                                                    }
                                                    .padding(.vertical, 10)
                                                    .padding(.horizontal, 15)
                                                    
                                                    Divider()
                                                        .padding(.leading, 50)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.bottom, 8)
                                }
                                .frame(maxHeight: 350)
                            }
                        }
                        
                        // Audio player controls in a nice rounded container
                        VStack(spacing: 0) {
                            // Audio player controls - Hide when in Tour Spots mode
                            if selectedTab != .tourSpots {
                                HStack(spacing: 30) {
                                    // 15 seconds back
                                    Button {
                                        let newTime = max(0, audioManager.currentTime - 15)
                                        audioManager.seek(to: newTime)
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 50, height: 50)
                                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                                            
                                            Image(systemName: "gobackward.15")
                                                .font(.title3)
                                                .foregroundColor(.appBlue)
                                        }
                                    }
                                    
                                    // Play/Pause button
                                    Button {
                                        if audioManager.isPlaying {
                                            audioManager.pauseAudio()
                                        } else {
                                            if audioManager.currentTime > 0 {
                                                audioManager.resumeAudio()
                                            } else {
                                                audioManager.playAudio(filename: currentStop.audioFileName)
                                            }
                                        }
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(Color.appBlue)
                                                .frame(width: 65, height: 65)
                                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                                            
                                            Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                                .font(.title)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    // 15 seconds forward
                                    Button {
                                        let newTime = min(audioManager.duration, audioManager.currentTime + 15)
                                        audioManager.seek(to: newTime)
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 50, height: 50)
                                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                                            
                                            Image(systemName: "goforward.15")
                                                .font(.title3)
                                                .foregroundColor(.appBlue)
                                        }
                                    }
                                }
                                .padding(.vertical, 20)
                                
                                // Audio progress bar
                                if audioManager.duration > 0 {
                                    HStack {
                                        Text(audioManager.currentTime.formatAsMinutesSeconds())
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        
                                        Slider(value: $audioManager.currentTime, in: 0...max(0.1, audioManager.duration)) { editing in
                                            if !editing && audioManager.isPlaying {
                                                audioManager.seek(to: audioManager.currentTime)
                                            }
                                        }
                                        .accentColor(.appBlue)
                                        
                                        Text(audioManager.duration.formatAsMinutesSeconds())
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 15)
                                }
                            } else {
                                // Placeholder for when in Tour Spots mode
                                VStack {
                                    Text("These spots are off the main tour route")
                                        .font(.subheadline)
                                        .padding(.vertical, 10)
                                    
                                    Text("Select a spot on the map or from the list to learn more")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.bottom, 20)
                                }
                                .padding(.top, 10)
                            }
                        }
                        .background(Color.white)
                    
                        // Exit tour button
                    Button {
                        audioManager.stopAudio()
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Exit Tour")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.red)
                                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                )
                                .padding(.horizontal, 40)
                                .padding(.vertical, 15)
                        }
                        .background(Color.white)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: -5)
                    .padding(.horizontal)
                    .padding(.bottom, isPanelExpanded ? 0 : 10)
                    .animation(.spring(), value: isPanelExpanded)
                }
                
                // Map Legend Button (top right)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showMapLegend = true
                        }) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.appBlue)
                                .padding(10)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                        }
                        .padding(.top, 50)
                        .padding(.trailing, 16)
                    }
                    Spacer()
                }
                
                // Map Legend Overlay
                if showMapLegend {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showMapLegend = false
                        }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Map Legend")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.appBlue)
                            
                            Spacer()
                            
                            Button(action: {
                                showMapLegend = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        Divider()
                        
                        // Audio Points
                        HStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(Color.appBlue)
                                    .frame(width: 30, height: 30)
                                Text("1")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14, weight: .bold))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Audio Tour Points")
                                    .font(.headline)
                                
                                Text("Numbered stops with audio narration")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Current Stop
                        HStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 30, height: 30)
                                Text("3")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14, weight: .bold))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Current Audio Point")
                                    .font(.headline)
                                
                                Text("The stop you're currently at")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Points of Interest
                        HStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 30, height: 30)
                                Image(systemName: "star.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Points of Interest")
                                    .font(.headline)
                                
                                Text("Additional attractions and viewpoints")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Food Spots
                        HStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 30, height: 30)
                                Image(systemName: "fork.knife.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Food & Dining")
                                    .font(.headline)
                                
                                Text("Restaurants, cafés, and food options")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Route Lines
                        HStack(spacing: 15) {
                            Rectangle()
                                .fill(Color.appBlue)
                                .frame(width: 30, height: 4)
                                .padding(.vertical, 13)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Tour Route")
                                    .font(.headline)
                                
                                Text("Suggested path between audio points")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: 450)
                    .transition(.opacity)
                }
            }
        }
        .overlay {
            // Route loading indicator
            if showingRouteLoadingIndicator {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.appBlue)
                        
                        Text("Generating driving routes...")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .frame(width: 200, height: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    )
                    
                    Spacer()
                    Spacer()
                }
            }
        }
        .fullScreenCover(isPresented: $showAudioPointDetail) {
            Group {
                if let stop = selectedAudioPoint {
                    StopDetailView(
                        stop: stop,
                        onClose: {
                            showAudioPointDetail = false
                            // Reset the selected point to avoid potential issues
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                selectedAudioPoint = nil
                            }
                        },
                        onPlayAudio: {
                            // Play the audio for this stop
                            audioManager.playAudio(filename: stop.audioFileName)
                        }
                    )
                } else {
                    // Fallback in case the stop is nil
                    ZStack {
                        Color.white.ignoresSafeArea()
                        VStack(spacing: 20) {
                            Text("Unable to load details")
                                .font(.headline)
                            
                            Button("Close") {
                                showAudioPointDetail = false
                            }
                            .padding()
                            .background(Color.appBlue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .onTapGesture {
                        showAudioPointDetail = false
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showFoodSpotDetail) {
            Group {
                if let foodSpot = selectedFoodSpot {
                    FoodSpotDetailView(
                        foodSpot: foodSpot,
                        onClose: {
                            showFoodSpotDetail = false
                            // Reset the selected food spot to avoid potential issues
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                selectedFoodSpot = nil
                            }
                        }
                    )
                } else {
                    // Fallback in case the food spot is nil
                    ZStack {
                        Color.white.ignoresSafeArea()
                        VStack(spacing: 20) {
                            Text("Unable to load food spot details")
                                .font(.headline)
                            
                            Button("Close") {
                                showFoodSpotDetail = false
                            }
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .onTapGesture {
                        showFoodSpotDetail = false
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showTourSpotDetail) {
            Group {
                if let tourSpot = selectedTourSpot {
                    TourSpotDetailView(
                        spot: tourSpot,
                        onClose: {
                            showTourSpotDetail = false
                            // Reset the selected tour spot to avoid potential issues
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                selectedTourSpot = nil
                            }
                        }
                    )
                } else {
                    // Fallback in case the tour spot is nil
                    ZStack {
                        Color.white.ignoresSafeArea()
                        VStack(spacing: 20) {
                            Text("Unable to load tour spot details")
                                .font(.headline)
                            
                            Button("Close") {
                                showTourSpotDetail = false
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .onTapGesture {
                        showTourSpotDetail = false
                    }
                }
            }
        }
        .onDisappear {
            // Clean up when view disappears
            audioManager.stopAudio()
        }
        .onAppear {
            // Set up a timer to check proximity to audio points
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                guard let userLocation = locationManager.location else { return }
                
                // Check for any audio points within 50 meters that haven't been played yet
                for stop in sortedStops.filter({ $0.isAudioPoint && $0.order > currentStopIndex }) {
                    let stopLocation = CLLocation(latitude: stop.coordinate.latitude, longitude: stop.coordinate.longitude)
                    let distance = userLocation.distance(from: stopLocation)
                    
                    if distance < 50 {
                        // Approaching a new audio point
                        audioManager.stopAudio()
                        if let index = sortedStops.firstIndex(where: { $0.id == stop.id }) {
                            currentStopIndex = index
                            withAnimation {
                                let region = MKCoordinateRegion(
                                    center: stop.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                )
                                position = .region(region)
                            }
                            audioManager.playAudio(filename: stop.audioFileName)
                            break
                        }
                    }
                }
            }
            
            // Start playing the first stop's audio automatically
            audioManager.playAudio(filename: currentStop.audioFileName)
            
            // Generate road-following routes between all stops
            showingRouteLoadingIndicator = true
            routeManager.generateRoutes(for: sortedStops) { success in
                showingRouteLoadingIndicator = false
                
                if !success {
                    // You could show an alert here if you wanted
                    print("Failed to generate some routes")
                }
            }
        }
    }
}

// TourStopRow component for the expanded panel
struct TourStopRow: View {
    var stop: TourStop
    var isSelected: Bool
    var onTap: () -> Void
    var onInfoTap: (() -> Void)?
    
    var body: some View {
        // Row item for displaying a tour stop in a list
        // Highlights the currently selected stop
        HStack(spacing: 15) {
            Button(action: onTap) {
                HStack(spacing: 15) {
                    // Stop number in circle
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.red : Color.appBlue.opacity(0.2))
                            .frame(width: 35, height: 35)
                        
                        Text("\(stop.order)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(isSelected ? .white : .appBlue)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stop.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(stop.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(.appBlue)
                            .font(.caption)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if let onInfoTap = onInfoTap {
                Button(action: onInfoTap) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.appBlue)
                        .font(.system(size: 20))
                }
                .padding(.trailing, 15)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(isSelected ? Color.appBlue.opacity(0.1) : Color.white)
    }
}

// MARK: - RoundedCorner Extensions
extension View {
    // Adds the ability to round specific corners of a view
    // Example usage: .cornerRadius(10, corners: [.topLeft, .topRight])
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    // Creates a path with rounded corners only at the specified positions
    // This allows for more flexibility than the standard cornerRadius modifier
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// FoodSpotCard component for horizontal scrolling
struct FoodSpotCard: View {
    var foodSpot: FoodSpot
    var onTap: () -> Void
    
    var body: some View {
        // Card-style UI component for displaying food spots
        // Used in horizontal scrollable lists
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Restaurant icon at top
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 140, height: 80)
                    
                    VStack(alignment: .leading) {
                        Image(systemName: foodIcon(for: foodSpot.cuisine))
                            .font(.title2)
                            .foregroundColor(.orange)
                            .padding(8)
                            .background(Circle().fill(Color.white))
                            .padding(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(foodSpot.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .frame(width: 140, alignment: .leading)
                    
                    Text(foodSpot.cuisine)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        // Rating stars
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            
                            Text(String(format: "%.1f", foodSpot.rating))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Go to Map icon
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                    .frame(width: 140, alignment: .leading)
                }
            }
            .padding(.bottom, 10)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Helper function to determine food icon based on cuisine
    private func foodIcon(for cuisine: String) -> String {
        switch cuisine.lowercased() {
        case _ where cuisine.lowercased().contains("coffee"):
            return "cup.and.saucer.fill"
        case _ where cuisine.lowercased().contains("american"):
            return "fork.knife"
        case _ where cuisine.lowercased().contains("italian"):
            return "fork.knife"
        case _ where cuisine.lowercased().contains("international"):
            return "globe.americas.fill"
        case _ where cuisine.lowercased().contains("canadian"):
            return "leaf.fill"
        case _ where cuisine.lowercased().contains("café"),
             _ where cuisine.lowercased().contains("cafe"):
            return "cup.and.saucer.fill"
        default:
            return "fork.knife"
        }
    }
}

// FoodSpotDetailView component for displaying food spot details
struct FoodSpotDetailView: View {
    var foodSpot: FoodSpot
    var onClose: (() -> Void)?
    @State private var showInMaps = false
    
    init(foodSpot: FoodSpot, onClose: (() -> Void)? = nil) {
        self.foodSpot = foodSpot
        self.onClose = onClose
    }
    
    var body: some View {
        ZStack {
            // Background color
            Color.white.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header image or placeholder
                    ZStack(alignment: .bottom) {
                        // Image placeholder with gradient overlay
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange.opacity(0.7), Color.orange]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 200)
                        
                        // Food spot name and cuisine overlay
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(foodSpot.cuisine)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text(foodSpot.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            // Rating bubble
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 50, height: 50)
                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                                
                                VStack(spacing: 0) {
                                    Text(String(format: "%.1f", foodSpot.rating))
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                    
                                    // Star
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Description section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About This Restaurant")
                            .font(.headline)
                            .padding(.top, 16)
                        
                        Text(foodSpot.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                        
                        // Extended description (placeholder in real app this would have more)
                        Text("This restaurant offers a variety of delicious meals in a welcoming atmosphere. Whether you're looking for a quick bite or a leisurely dining experience, you'll find something to satisfy your appetite here. The staff is friendly and attentive, ensuring that your visit is pleasant from start to finish.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 16)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Location information section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Restaurant Information")
                            .font(.headline)
                            .padding(.top, 16)
                        
                        // Details rows
                        FoodDetailRow(icon: "location.fill", title: "Address", detail: "Niagara Falls, NY 14303, United States")
                        FoodDetailRow(icon: "clock.fill", title: "Opening Hours", detail: "10:00 AM - 9:00 PM")
                        FoodDetailRow(icon: "dollarsign.circle.fill", title: "Price Range", detail: priceRange(for: foodSpot.rating))
                        FoodDetailRow(icon: "phone.fill", title: "Phone", detail: "+1 (555) 123-4567")
                        FoodDetailRow(icon: "globe", title: "Website", detail: "www.niagarafallsrestaurant.com")
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    Divider()
                    
                    // Recommended dishes section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Popular Dishes")
                            .font(.headline)
                            .padding(.top, 16)
                        
                        Text("Based on customer reviews, these are some of the most popular dishes at this restaurant:")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                        
                        // Placeholder for popular dishes
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                
                                Text("Niagara Falls Special Burger")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                
                                Text("Canadian Maple Glazed Salmon")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                
                                Text("Waterfall Chocolate Dessert")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    .padding(.horizontal)
                    
                    // Open in Maps button
                    Button {
                        // This would open the location in Maps in a real implementation
                        showInMaps = true
                    } label: {
                        HStack {
                            Image(systemName: "map.fill")
                                .foregroundColor(.white)
                            
                            Text("Open in Maps")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.orange)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            
            // Close button overlay in top corner
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        // Make sure we call the close action
                        if let onClose = onClose {
                            onClose()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .accessibilityLabel("Close")
                    .padding(.top, 50)
                    .padding(.trailing, 20)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showInMaps) {
            // This would be replaced with actual Maps integration
            VStack {
                Text("Opening Maps...")
                    .font(.headline)
                    .padding()
                
                Text("This is a placeholder for Maps integration")
                    .foregroundColor(.secondary)
                
                Button("Close") {
                    showInMaps = false
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.top, 20)
            }
            .padding()
        }
    }
    
    // Helper function to determine price range based on rating
    private func priceRange(for rating: Double) -> String {
        switch rating {
        case 0..<3.5:
            return "$"
        case 3.5..<4.2:
            return "$$"
        default:
            return "$$$"
        }
    }
}

// Detail row component for FoodSpotDetailView
struct FoodDetailRow: View {
    var icon: String // SF Symbol name for the row icon
    var title: String // Label describing the detail type
    var detail: String // The actual detail information to display
    
    var body: some View {
        // Reusable row component for displaying labeled information
        // Used in detail views with consistent formatting
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.appBlue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(detail)
                    .font(.body)
            }
            
            Spacer()
        }
    }
}

// MARK: - Stop Detail View
struct StopDetailView: View {
    var stop: TourStop
    var onClose: () -> Void
    var onPlayAudio: () -> Void
    
    @State private var showInMaps = false
    
    var body: some View {
        ZStack {
            // Background color
            Color.white.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header image or placeholder
                    ZStack(alignment: .bottom) {
                        if let imageName = stop.imageName {
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                                .overlay(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        } else {
                            // Image placeholder with gradient overlay
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.appBlue.opacity(0.7), Color.appBlue]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 200)
                        }
                        
                        // Stop name and number overlay
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Stop #\(stop.order)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text(stop.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            // Play audio button
                            Button(action: onPlayAudio) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 50, height: 50)
                                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                                    
                                    Image(systemName: "play.fill")
                                        .font(.title3)
                                        .foregroundColor(.appBlue)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Description section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About This Location")
                            .font(.headline)
                            .padding(.top, 16)
                        
                        Text(stop.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                        
                        // Extended description - this would come from a more detailed database in a real app
                        Text("Niagara Falls is a group of three waterfalls at the southern end of Niagara Gorge, spanning the border between the province of Ontario in Canada and the state of New York in the United States. The largest of the three is Horseshoe Falls, which straddles the international border of the two countries. The smaller American Falls and Bridal Veil Falls lie within the United States.\n\nWith a vertical drop of more than 165 feet (50 m) and a width of 2,700 feet (820 m), Horseshoe Falls is the most powerful waterfall in North America, as measured by flow rate. The falls are located 17 miles (27 km) north-northwest of Buffalo, New York, and 75 miles (121 km) south-southeast of Toronto, between the twin cities of Niagara Falls, Ontario, and Niagara Falls, New York.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 16)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Location information section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Location Information")
                            .font(.headline)
                            .padding(.top, 16)
                        
                        // Details rows
                        FoodDetailRow(icon: "location.fill", title: "Address", detail: "Niagara Falls, NY 14303, United States")
                        FoodDetailRow(icon: "clock.fill", title: "Opening Hours", detail: "9:00 AM - 5:00 PM")
                        FoodDetailRow(icon: "dollarsign.circle.fill", title: "Admission", detail: "Adults: $20, Children: $10")
                        FoodDetailRow(icon: "globe", title: "Website", detail: "www.niagarafallsstatepark.com")
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    Divider()
                    
                    // Next stop information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Directions")
                            .font(.headline)
                            .padding(.top, 16)
                        
                        Text(stop.drivingDirections)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Distance to next stop")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(stop.distanceToNextStop)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Estimated time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(stop.estimatedTimeToNextStop)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    .padding(.horizontal)
                    
                    // Open in Maps button
                    Button {
                        // This would open the location in Maps in a real implementation
                        showInMaps = true
                    } label: {
                        HStack {
                            Image(systemName: "map.fill")
                                .foregroundColor(.white)
                            
                            Text("Open in Maps")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.appBlue)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            
            // Close button overlay in top corner
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: onClose) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .accessibilityLabel("Close")
                    .padding(.top, 50)
                    .padding(.trailing, 20)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showInMaps) {
            // This would be replaced with actual Maps integration
            VStack {
                Text("Opening Maps...")
                    .font(.headline)
                    .padding()
                
                Text("This is a placeholder for Maps integration")
                    .foregroundColor(.secondary)
                
                Button("Close") {
                    showInMaps = false
                }
                .padding()
                .background(Color.appBlue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.top, 20)
            }
            .padding()
        }
    }
}

// TourSpotCard component for displaying off-route points of interest
struct TourSpotCard: View {
    var spot: TourSpot
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: categoryIcon(for: spot.category))
                        .font(.title2)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(spot.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(spot.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Text(spot.category.rawValue)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.1))
                            )
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Helper function to determine icon based on category
    private func categoryIcon(for category: TourSpot.SpotCategory) -> String {
        switch category {
        case .nature:
            return "leaf.fill"
        case .attraction:
            return "star.fill"
        case .activity:
            return "figure.walk"
        case .historic:
            return "building.columns.fill"
        case .viewpoint:
            return "binoculars.fill"
        case .restaurant:
            return "fork.knife.circle.fill"
        case .cafe:
            return "cup.and.saucer.fill"
        case .fastFood:
            return "fork.knife"
        }
    }
}

// MARK: - Tour Spot Detail View
struct TourSpotDetailView: View {
    var spot: TourSpot
    var onClose: () -> Void
    @State private var showInMaps = false
    
    var body: some View {
        ZStack {
            // Background color
            Color.white.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header image or placeholder
                    ZStack(alignment: .bottom) {
                        // Image placeholder with gradient overlay
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green.opacity(0.7), Color.green]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 200)
                        
                        // Spot name and category overlay
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(spot.category.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text(spot.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            // Category icon bubble
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 50, height: 50)
                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                                
                                Image(systemName: categoryIcon(for: spot.category))
                                    .font(.title3)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                    }
                    
                    // Description section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About This Location")
                            .font(.headline)
                            .padding(.top, 16)
                        
                        Text(spot.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Location information section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Location Information")
                            .font(.headline)
                            .padding(.top, 16)
                        
                        // Details rows
                        FoodDetailRow(icon: "location.fill", title: "Address", detail: spot.location)
                        FoodDetailRow(icon: "globe", title: "Website", detail: spot.website)
                        FoodDetailRow(icon: "mappin.and.ellipse", title: "Coordinates", detail: String(format: "%.4f, %.4f", spot.coordinate.latitude, spot.coordinate.longitude))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    Divider()
                    
                    // Tips section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tips for Visitors")
                            .font(.headline)
                            .padding(.top, 16)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            tipRow(icon: "clock.fill", tip: "Plan to spend at least 1-2 hours to fully experience this location.")
                            tipRow(icon: "dollarsign.circle", tip: categoryTip(for: spot.category))
                            tipRow(icon: "camera.fill", tip: "This is a great photo opportunity. The best lighting is typically in the morning.")
                            tipRow(icon: "figure.2", tip: "This attraction can get crowded during peak summer months. Consider visiting early in the day.")
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                    
                    // Open in Maps button
                    Button {
                        // This would open the location in Maps in a real implementation
                        showInMaps = true
                    } label: {
                        HStack {
                            Image(systemName: "map.fill")
                                .foregroundColor(.white)
                            
                            Text("Open in Maps")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.green)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            
            // Close button overlay in top corner
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: onClose) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .accessibilityLabel("Close")
                    .padding(.top, 50)
                    .padding(.trailing, 20)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showInMaps) {
            // This would be replaced with actual Maps integration
            VStack {
                Text("Opening Maps...")
                    .font(.headline)
                    .padding()
                
                Text("This is a placeholder for Maps integration")
                    .foregroundColor(.secondary)
                
                Button("Close") {
                    showInMaps = false
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.top, 20)
            }
            .padding()
        }
    }
    
    // Helper function for category icon
    private func categoryIcon(for category: TourSpot.SpotCategory) -> String {
        switch category {
        case .nature:
            return "leaf.fill"
        case .attraction:
            return "star.fill"
        case .activity:
            return "figure.walk"
        case .historic:
            return "building.columns.fill"
        case .viewpoint:
            return "binoculars.fill"
        case .restaurant:
            return "fork.knife.circle.fill"
        case .cafe:
            return "cup.and.saucer.fill"
        case .fastFood:
            return "fork.knife"
        }
    }
    
    // Helper function for tips based on category
    private func categoryTip(for category: TourSpot.SpotCategory) -> String {
        switch category {
        case .nature:
            return "Free to visit. Consider bringing water and comfortable walking shoes."
        case .attraction:
            return "Admission fees apply. Check the website for current prices and possible discounts."
        case .activity:
            return "Tickets range from $20-40 per person. Book ahead during peak season."
        case .historic:
            return "Admission is around $15 for adults with discounts for seniors and children."
        case .viewpoint:
            return "Free access to viewing platforms. Optional paid experiences may be available."
        case .restaurant:
            return "Dining reservations are recommended. The cuisine is exquisite."
        case .cafe:
            return "The ambiance is cozy. Perfect for a quick coffee or light meal."
        case .fastFood:
            return "Fast food options available. Quick and convenient."
        }
    }
    
    // Helper function for tip rows
    private func tipRow(icon: String, tip: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.green)
                .frame(width: 18, height: 18)
            
            Text(tip)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

// TourSpotRow component for displaying tour spots in a list format
struct TourSpotRow: View {
    var spot: TourSpot
    var isSelected: Bool
    var onTap: () -> Void
    var onInfoTap: (() -> Void)?
    
    var body: some View {
        // Row item for displaying a point of interest in a list
        // Used in the Tour Spots tab to show attractions, nature spots, etc.
        HStack(spacing: 15) {
            Button(action: onTap) {
                HStack(spacing: 15) {
                    // Category icon in circle
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.green : Color.green.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: categoryIcon(for: spot.category))
                            .font(.system(size: 16))
                            .foregroundColor(isSelected ? .white : .green)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(spot.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(spot.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if let onInfoTap = onInfoTap {
                Button(action: onInfoTap) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.green)
                        .font(.system(size: 20))
                }
                .padding(.trailing, 10)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(isSelected ? Color.green.opacity(0.1) : Color.white)
    }
    
    // Helper function to determine icon based on category
    private func categoryIcon(for category: TourSpot.SpotCategory) -> String {
        switch category {
        case .nature:
            return "leaf.fill"
        case .attraction:
            return "star.fill"
        case .activity:
            return "figure.walk"
        case .historic:
            return "building.columns.fill"
        case .viewpoint:
            return "binoculars.fill"
        case .restaurant:
            return "fork.knife.circle.fill"
        case .cafe:
            return "cup.and.saucer.fill"
        case .fastFood:
            return "fork.knife"
        }
    }
}

