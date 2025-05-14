import SwiftUI
import MapKit

// Fix for ShapeStyle extension
extension ShapeStyle where Self == Color {
    static var appBlue: Color { Color.appBlue }
}

// MARK: - Attraction Model
struct AttractionModel: Identifiable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var description: String
    var coordinate: CLLocationCoordinate2D
    var order: Int
    var imageName: String
    
    static func == (lhs: AttractionModel, rhs: AttractionModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Explore View with Map
struct ExploreView: View {
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: 43.0828,
                longitude: -79.0742
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.05,
                longitudeDelta: 0.05
            )
        )
    )
    
    // Points of interest - all 9 stops from the tour
    let attractions: [AttractionModel] = [
        AttractionModel(
            name: "Niagara Parks Power Station & Tunnel",
            description: "This 115-year-old former hydroelectric station offers tours of its preserved generator hall and a 2,200-foot tailrace tunnel.",
            coordinate: CLLocationCoordinate2D(latitude: 43.074895, longitude: -79.078176),
            order: 1,
            imageName: "niagara-parks-power-station"
        ),
        AttractionModel(
            name: "Brink of the Falls (Table Rock)",
            description: "Stand mere meters from the thundering cascade as 2,800 m³ of water plunge over the crest each second.",
            coordinate: CLLocationCoordinate2D(latitude: 43.079154, longitude: -79.078442),
            order: 2,
            imageName: "brink-of-the-falls"
        ),
        AttractionModel(
            name: "Niagara City Cruises (Hornblower)",
            description: "Embark on a breathtaking 20-minute voyage to the base of the falls with 360° views of all three waterfalls.",
            coordinate: CLLocationCoordinate2D(latitude: 43.089151, longitude: -79.073060),
            order: 3,
            imageName: "niagara-city-cruises"
        ),
        AttractionModel(
            name: "Clifton Hill Entertainment Strip",
            description: "Niagara Falls' famous tourist promenade packed with attractions, arcades, and themed restaurants.",
            coordinate: CLLocationCoordinate2D(latitude: 43.0912, longitude: -79.0745),
            order: 4,
            imageName: "clifton-hill"
        ),
        AttractionModel(
            name: "Skylon Tower",
            description: "A 160m observation tower offering panoramic views of the falls and surrounding areas up to 125km away.",
            coordinate: CLLocationCoordinate2D(latitude: 43.085280, longitude: -79.079720),
            order: 5,
            imageName: "skylon-tower"
        ),
        AttractionModel(
            name: "Historic Niagara-on-the-Lake",
            description: "A well-preserved 19th-century village with heritage buildings, boutiques, and waterfront views.",
            coordinate: CLLocationCoordinate2D(latitude: 43.255111, longitude: -79.071490),
            order: 6,
            imageName: "niagara-on-the-lake"
        ),
        AttractionModel(
            name: "Rainbow Bridge",
            description: "Cross the Rainbow Bridge for spectacular views of all three falls as you enter the USA.",
            coordinate: CLLocationCoordinate2D(latitude: 43.090233, longitude: -79.067744),
            order: 7,
            imageName: "rainbow-bridge"
        ),
        AttractionModel(
            name: "Niagara Falls State Park (USA)",
            description: "The oldest state park in the USA offers unparalleled views of American Falls and access to Maid of the Mist boats.",
            coordinate: CLLocationCoordinate2D(latitude: 43.083714, longitude: -79.065147),
            order: 8,
            imageName: "niagara-falls-state-park"
        ),
        AttractionModel(
            name: "Goat Island & Terrapin Point",
            description: "Stand at the brink of Horseshoe Falls from the U.S. side and experience the Hurricane Deck near Bridal Veil Falls.",
            coordinate: CLLocationCoordinate2D(latitude: 43.080060, longitude: -79.074140),
            order: 9,
            imageName: "goat-island"
        )
    ]
    
    @State private var selectedAttraction: AttractionModel?
    @State private var showAttractionDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Using a proper interactive Map implementation
                Map(position: $position, selection: $selectedAttraction) {
                    ForEach(attractions) { attraction in
                        Annotation(attraction.name, coordinate: attraction.coordinate) {
                            Button {
                                selectedAttraction = attraction
                                showAttractionDetail = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.appBlue)
                                        .frame(width: 30, height: 30)
                                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                                    
                                    Text("\(attraction.order)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .tag(attraction)
                    }
                }
                .mapStyle(.standard)
                .mapControls {
                    MapCompass()
                    MapScaleView()
                    MapUserLocationButton()
                }
                .onChange(of: selectedAttraction) { oldValue, newValue in
                    if newValue != nil {
                        showAttractionDetail = true
                        
                        // Center the map on the selected attraction
                        if let attraction = newValue {
                            withAnimation {
                                position = .region(MKCoordinateRegion(
                                    center: attraction.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                ))
                            }
                        }
                    }
                }
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(attractions) { attraction in
                                AttractionCard(
                                    attraction: attraction,
                                    onViewButtonTapped: {
                                        // First set the selected attraction, then show the detail sheet
                                        selectedAttraction = attraction
                                        showAttractionDetail = true
                                    }
                                )
                                .onTapGesture {
                                    withAnimation {
                                        position = .region(MKCoordinateRegion(
                                            center: attraction.coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                        ))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .background(
                        Rectangle()
                            .fill(Color.black.opacity(0.05))
                            .background(.ultraThinMaterial)
                    )
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Reset to original position
                        position = .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: 43.0828, longitude: -79.0742),
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        ))
                    }) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.appBlue)
                    }
                }
            }
            // Using if-let binding to ensure the attraction is always available
            .sheet(isPresented: $showAttractionDetail, onDismiss: {
                // Reset selected attraction when sheet is dismissed
                selectedAttraction = nil
            }) {
                if let attraction = selectedAttraction {
                    AttractionDetailView(attraction: attraction)
                }
            }
        }
    }
}

// MARK: - Attraction Card
struct AttractionCard: View {
    var attraction: AttractionModel
    var onViewButtonTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(attraction.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 100)
                    .clipped()
                    .cornerRadius(12)
                
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 36, height: 36)
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        
                        Text("\(attraction.order)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.appBlue)
                    }
                    .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(attraction.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(attraction.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption2)
                    Text("Point of Interest")
                        .font(.caption)
                    Spacer()
                    Button(action: onViewButtonTapped) {
                        Text("View")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.appBlue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .frame(width: 200)
    }
}

// MARK: - Attraction Detail View
struct AttractionDetailView: View {
    var attraction: AttractionModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header with attraction image
                ZStack(alignment: .bottom) {
                    Image(attraction.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Stop #\(attraction.order)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text(attraction.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                
                // Description section
                VStack(alignment: .leading, spacing: 16) {
                    Text("About This Location")
                        .font(.headline)
                        .padding(.top, 16)
                    
                    Text(attraction.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 8)
                    
                    // Extended description - this would come from a more detailed database in a real app
                    Text("Niagara Falls is a group of three waterfalls at the southern end of Niagara Gorge, spanning the border between the province of Ontario in Canada and the state of New York in the United States. The largest of the three is Horseshoe Falls, which straddles the international border of the two countries. The smaller American Falls and Bridal Veil Falls lie within the United States.\n\nWith a vertical drop of more than 165 feet (50 m) and a width of 2,700 feet (820 m), Horseshoe Falls is the most powerful waterfall in North America, as measured by flow rate.")
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
                    DetailRow(icon: "location.fill", text: "Niagara Falls, NY 14303, United States")
                    DetailRow(icon: "clock.fill", text: "Open daily: 9:00 AM - 5:00 PM")
                    DetailRow(icon: "dollarsign.circle.fill", text: "Admission: Free")
                    DetailRow(icon: "info.circle.fill", text: "Point of interest")
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                
                // Open in Maps button
                Button {
                    // This would open the location in Maps in a real implementation
                    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: attraction.coordinate))
                    mapItem.name = attraction.name
                    mapItem.openInMaps(launchOptions: [:])
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    var icon: String
    var text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 24, height: 24)
                .foregroundColor(.appBlue)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
    }
}
