//
//  CalendarView.swift
//  Niagara Falls SightSeeing
//
//  Created by Michael Kot on 4/1/25.
//

import SwiftUI

// MARK: - Event Model
struct Event: Identifiable {
    var id = UUID()
    var title: String
    var date: Date
    var location: String
    var description: String
    var imageName: String
    var isHighlighted: Bool = false
    var category: EventCategory
    var website: String?
    var ticketPrice: String?
    
    enum EventCategory: String, CaseIterable {
        case festival = "Festival"
        case concert = "Concert"
        case tour = "Tour"
        case familyFriendly = "Family Friendly"
        case seasonal = "Seasonal"
        case foodAndDrink = "Food & Drink"
    }
}

// MARK: - Calendar View Model
class CalendarViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var selectedMonth: Date = Date()
    @Published var selectedEvent: Event? = nil
    @Published var showEventDetail: Bool = false
    
    // Get future-oriented dates for testing
    private func getFutureDate(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }
    
    // Sample events
    @Published var events: [Event] = [
        // Near future events (next few days)
        Event(
            title: "Summer Walking Tour",
            date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
            location: "Niagara Falls State Park",
            description: "Join our expert guide for a walking tour of Niagara Falls State Park. Learn about the fascinating history, geology, and ecology of America's oldest state park while enjoying stunning views of the falls.",
            imageName: "niagara-falls-state-park",
            isHighlighted: true,
            category: .tour,
            website: "www.niagarafallsstatepark.com",
            ticketPrice: "$25 per person"
        ),
        Event(
            title: "Local Craft Beer Festival",
            date: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
            location: "Niagara Falls Brewing Company",
            description: "Sample a variety of craft beers from local Niagara region breweries. Enjoy live music, food trucks, and games while tasting some of the best brews the area has to offer.",
            imageName: "brink-of-the-falls",
            category: .foodAndDrink,
            website: "www.niagarabeerweek.com",
            ticketPrice: "$35 per person"
        ),
        Event(
            title: "Hornblower Night Cruise",
            date: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
            location: "Hornblower Landing",
            description: "Experience the magic of Niagara Falls illuminated at night on this special evening cruise. See the colorful light show that transforms the falls into a spectacular nighttime wonder.",
            imageName: "niagara-city-cruises",
            isHighlighted: true,
            category: .tour,
            website: "www.niagaracruises.com",
            ticketPrice: "$45 per person"
        ),
        Event(
            title: "Kids Discovery Day",
            date: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            location: "Niagara Discovery Center",
            description: "A fun-filled day of educational activities for children of all ages. Includes hands-on exhibits about the natural history of Niagara Falls, wildlife demonstrations, and craft activities.",
            imageName: "clifton-hill",
            category: .familyFriendly,
            website: "www.niagaradiscovery.org",
            ticketPrice: "Free"
        ),
        // Original events (further in the future)
        Event(
            title: "Winter Festival of Lights",
            date: Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 15))!,
            location: "Niagara Parks",
            description: "Canada's largest free outdoor light festival features millions of sparkling lights and animated displays along a 8km route. Experience the magic of winter with spectacular illuminations transforming the Niagara Falls area into a winter wonderland.",
            imageName: "niagara-falls-state-park",
            isHighlighted: true,
            category: .festival,
            website: "www.wfol.com",
            ticketPrice: "Free"
        ),
        Event(
            title: "Ice Wine Festival",
            date: Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 20))!,
            location: "Niagara-on-the-Lake",
            description: "Experience the unique flavors of ice wine at this premier event. Sample ice wines from top Niagara region producers paired with gourmet food. Enjoy demonstrations, live entertainment, and more in the heart of wine country.",
            imageName: "niagara-on-the-lake",
            category: .foodAndDrink,
            website: "www.niagaraicewine.com",
            ticketPrice: "$45 per person"
        ),
        Event(
            title: "Niagara Falls Music Festival",
            date: Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 5))!,
            location: "Queen Victoria Park",
            description: "Annual music festival featuring local and international artists with the stunning backdrop of Niagara Falls. Enjoy performances across multiple stages with food trucks, artisan vendors, and family activities.",
            imageName: "brink-of-the-falls",
            category: .concert,
            website: "www.niagaramusicfest.com",
            ticketPrice: "$25-75"
        ),
        Event(
            title: "Butterfly Conservatory Special Tour",
            date: Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 12))!,
            location: "Niagara Parks Butterfly Conservatory",
            description: "A guided tour of the butterfly conservatory with a special focus on the newly arrived tropical species. Learn about butterfly life cycles, conservation efforts, and get up-close photographs with these beautiful creatures.",
            imageName: "niagara-parks-power-station",
            category: .tour,
            website: "www.niagaraparks.com/butterfly",
            ticketPrice: "$20 adults, $10 children"
        ),
        Event(
            title: "Winter Bird Watching Tour",
            date: Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 18))!,
            location: "Niagara River Corridor",
            description: "Join experienced ornithologists for a special winter bird watching tour along the Niagara River. The Niagara River corridor is designated as an Important Bird Area and hosts a diversity of waterfowl and gulls during winter months.",
            imageName: "goat-island",
            category: .tour,
            website: "www.niagarabirdtours.org",
            ticketPrice: "$15 per person"
        ),
        Event(
            title: "Children's Winter Craft Fair",
            date: Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 25))!,
            location: "Niagara Falls Public Library",
            description: "A day of winter-themed crafts, stories, and activities for children of all ages. Create snow globes, paper snowflakes, and more while enjoying hot chocolate and cookies. All materials provided.",
            imageName: "clifton-hill",
            category: .familyFriendly,
            website: "www.niagarafallslibrary.org",
            ticketPrice: "Free"
        ),
        Event(
            title: "Niagara Wine & Culinary Experience",
            date: Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 8))!,
            location: "Various Wineries in Niagara Region",
            description: "Sample the finest wines and local cuisine from the Niagara region. This self-guided tour allows visitors to visit multiple award-winning wineries and restaurants at their own pace with a special passport providing access to exclusive tastings.",
            imageName: "rainbow-bridge",
            category: .foodAndDrink,
            website: "www.niagarawinetrail.org",
            ticketPrice: "$65 per passport"
        ),
        Event(
            title: "Spring Flower Festival",
            date: Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 15))!,
            location: "Niagara Parks Botanical Gardens",
            description: "Celebrate the arrival of spring with displays of thousands of blooming flowers. Enjoy guided tours, gardening workshops, flower arranging demonstrations, and the butterfly conservatory. A perfect event for nature lovers and photographers.",
            imageName: "skylon-tower",
            isHighlighted: true,
            category: .seasonal,
            website: "www.niagaraparks.com/gardens",
            ticketPrice: "$15 admission"
        )
    ]
    
    // Get future events sorted by date
    var upcomingEvents: [Event] {
        let today = Calendar.current.startOfDay(for: Date())
        return events
            .filter { Calendar.current.startOfDay(for: $0.date) >= today }
            .sorted { $0.date < $1.date }
    }
    
    // Check if an event is the first event of its day in the upcoming events list
    func isFirstEventOfDay(_ event: Event) -> Bool {
        guard let index = upcomingEvents.firstIndex(where: { $0.id == event.id }) else {
            return false
        }
        
        if index == 0 {
            return true
        }
        
        let previousEvent = upcomingEvents[index - 1]
        return !Calendar.current.isDate(event.date, inSameDayAs: previousEvent.date)
    }
    
    // Get dates for current month view
    func daysInMonth() -> [Date] {
        let calendar = Calendar.current
        
        // Get the range of days in month
        let interval = calendar.dateInterval(of: .month, for: selectedMonth)!
        let startDate = interval.start
        
        // Find the first date to show (might include some days from previous month)
        let firstWeekday = calendar.component(.weekday, from: startDate)
        let daysToAdd = (firstWeekday - calendar.firstWeekday + 7) % 7
        let startDateInGrid = calendar.date(byAdding: .day, value: -daysToAdd, to: startDate)!
        
        // Create 42 dates (6 weeks)
        var dates: [Date] = []
        for day in 0..<42 {
            if let date = calendar.date(byAdding: .day, value: day, to: startDateInGrid) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    // Get events for a specific date
    func eventsFor(date: Date) -> [Event] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.date, inSameDayAs: date)
        }
    }
    
    // Change month (previous or next)
    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
    
    // Format date for display
    func formatDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}

// MARK: - Calendar View
struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var showingFutureEvents = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Featured Events section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Upcoming Events")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.appBlue)
                            
                            Spacer()
                            
                            Button(action: {
                                showingFutureEvents.toggle()
                            }) {
                                Text(showingFutureEvents ? "Show Calendar" : "View All")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.appBlue)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 15)
                        
                        if showingFutureEvents {
                            // Full list of future events
                            FutureEventsListView(viewModel: viewModel)
                        } else {
                            // Preview of upcoming events with horizontal scroll
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(viewModel.upcomingEvents.prefix(5)) { event in
                                        UpcomingEventCard(event: event)
                                            .onTapGesture {
                                                viewModel.selectedEvent = event
                                                viewModel.showEventDetail = true
                                            }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 5)
                            }
                            
                            // Calendar view
                            if !showingFutureEvents {
                                // Calendar header
                                VStack(spacing: 10) {
                                    Divider()
                                        .padding(.vertical, 10)
                                    
                                    Text("Calendar")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.appBlue)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal)
                                    
                                    HStack {
                                        Button(action: {
                                            viewModel.changeMonth(by: -1)
                                        }) {
                                            Image(systemName: "chevron.left")
                                                .font(.title3)
                                                .foregroundColor(.appBlue)
                                                .padding(8)
                                                .background(Color.white)
                                                .cornerRadius(10)
                                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(viewModel.formatDate(viewModel.selectedMonth, format: "MMMM yyyy"))
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.appBlue)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            viewModel.changeMonth(by: 1)
                                        }) {
                                            Image(systemName: "chevron.right")
                                                .font(.title3)
                                                .foregroundColor(.appBlue)
                                                .padding(8)
                                                .background(Color.white)
                                                .cornerRadius(10)
                                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                        }
                                    }
                                    .padding(.horizontal)
                                    
                                    // Weekday headers
                                    HStack(spacing: 0) {
                                        ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                                            Text(day)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.secondary)
                                                .frame(maxWidth: .infinity)
                                        }
                                    }
                                    .padding(.top, 8)
                                    .padding(.bottom, 5)
                                }
                                
                                // Calendar grid
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                                    ForEach(viewModel.daysInMonth(), id: \.self) { date in
                                        VStack(spacing: 5) {
                                            let calendar = Calendar.current
                                            let day = calendar.component(.day, from: date)
                                            let isCurrentMonth = calendar.isDate(date, equalTo: viewModel.selectedMonth, toGranularity: .month)
                                            let isSelected = calendar.isDate(date, inSameDayAs: viewModel.selectedDate)
                                            let hasEvents = !viewModel.eventsFor(date: date).isEmpty
                                            let isToday = calendar.isDateInToday(date)
                                            
                                            // Day number with selection indicator
                                            Text("\(day)")
                                                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                                                .foregroundColor(isCurrentMonth ? (isSelected ? .white : .primary) : .gray.opacity(0.5))
                                                .frame(width: 32, height: 32)
                                                .background(
                                                    ZStack {
                                                        if isSelected {
                                                            Circle()
                                                                .fill(Color.appBlue)
                                                        } else if isToday {
                                                            Circle()
                                                                .stroke(Color.appBlue, lineWidth: 1)
                                                        }
                                                    }
                                                )
                                            
                                            // Event indicator
                                            if hasEvents {
                                                let events = viewModel.eventsFor(date: date)
                                                HStack(spacing: 4) {
                                                    ForEach(0..<min(events.count, 3), id: \.self) { index in
                                                        Circle()
                                                            .fill(events[index].isHighlighted ? Color.orange : Color.appBlue)
                                                            .frame(width: 6, height: 6)
                                                    }
                                                }
                                                .padding(.top, 2)
                                            } else {
                                                Spacer()
                                                    .frame(height: 8)
                                            }
                                        }
                                        .frame(height: 45)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            viewModel.selectedDate = date
                                        }
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.top, 10)
                                
                                Divider()
                                    .padding(.vertical, 8)
                                
                                // Events list for selected day
                                VStack(alignment: .leading, spacing: 15) {
                                    Text(viewModel.formatDate(viewModel.selectedDate, format: "EEEE, MMMM d, yyyy"))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .padding(.horizontal)
                                    
                                    let eventsForSelectedDate = viewModel.eventsFor(date: viewModel.selectedDate)
                                    
                                    if eventsForSelectedDate.isEmpty {
                                        VStack(spacing: 20) {
                                            Image(systemName: "calendar.badge.exclamationmark")
                                                .font(.system(size: 50))
                                                .foregroundColor(.gray.opacity(0.5))
                                                .padding(.top, 30)
                                            
                                            Text("No events scheduled for this day")
                                                .font(.title3)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal)
                                            
                                            Text("Check other dates or come back later")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary.opacity(0.8))
                                                .padding(.top, 5)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                    } else {
                                        ForEach(eventsForSelectedDate) { event in
                                            EventCard(event: event)
                                                .onTapGesture {
                                                    viewModel.selectedEvent = event
                                                    viewModel.showEventDetail = true
                                                }
                                                .padding(.horizontal)
                                        }
                                        .padding(.bottom, 20)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Events Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showEventDetail) {
                if let event = viewModel.selectedEvent {
                    EventDetailView(event: event)
                }
            }
        }
    }
}

// MARK: - Future Events List View
struct FutureEventsListView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            if viewModel.upcomingEvents.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.top, 30)
                    
                    Text("No upcoming events")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(viewModel.upcomingEvents) { event in
                    VStack(alignment: .leading, spacing: 0) {
                        // Date header
                        if viewModel.isFirstEventOfDay(event) {
                            Text(viewModel.formatDate(event.date, format: "EEEE, MMMM d, yyyy"))
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                                .padding(.top, 15)
                                .padding(.bottom, 5)
                        }
                        
                        EventCard(event: event)
                            .onTapGesture {
                                viewModel.selectedEvent = event
                                viewModel.showEventDetail = true
                            }
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Upcoming Event Card
struct UpcomingEventCard: View {
    var event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            Image(event.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 160, height: 100)
                .cornerRadius(10)
                .clipped()
                .overlay(
                    VStack {
                        Spacer()
                        
                        HStack {
                            if event.isHighlighted {
                                Text("Featured")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.orange)
                                    .cornerRadius(8)
                            }
                            
                            Spacer()
                            
                            CategoryPill(category: event.category)
                                .scaleEffect(0.8)
                                .offset(x: 4)
                        }
                        .padding(8)
                    }
                )
            
            // Date
            Text(DateFormatter.dateOnly.string(from: event.date))
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Title
            Text(event.title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            // Location
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .font(.caption2)
                    .foregroundColor(.appBlue)
                
                Text(event.location)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 160)
        .padding(.bottom, 10)
    }
}

// MARK: - Event Card
struct EventCard: View {
    var event: Event
    
    var body: some View {
        HStack(spacing: 15) {
            // Event image
            Image(event.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .cornerRadius(10)
                .clipped()
            
            // Event details
            VStack(alignment: .leading, spacing: 5) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundColor(.appBlue)
                    
                    Text(event.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    CategoryPill(category: event.category)
                    
                    if event.isHighlighted {
                        Text("Featured")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Arrow indicator
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Category Pill
struct CategoryPill: View {
    var category: Event.EventCategory
    
    var backgroundColor: Color {
        switch category {
        case .festival:
            return Color.purple.opacity(0.8)
        case .concert:
            return Color.blue.opacity(0.8)
        case .tour:
            return Color.green.opacity(0.8)
        case .familyFriendly:
            return Color.pink.opacity(0.8)
        case .seasonal:
            return Color.orange.opacity(0.8)
        case .foodAndDrink:
            return Color.red.opacity(0.8)
        }
    }
    
    var body: some View {
        Text(category.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(backgroundColor)
            .cornerRadius(8)
    }
}

// MARK: - Event Detail View
struct EventDetailView: View {
    var event: Event
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header with event image
                ZStack(alignment: .bottomLeading) {
                    Image(event.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            CategoryPill(category: event.category)
                            
                            if event.isHighlighted {
                                Text("Featured")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.orange)
                                    .cornerRadius(8)
                            }
                        }
                        
                        Text(event.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding()
                }
                
                // Event details
                VStack(alignment: .leading, spacing: 20) {
                    // Date, time, location section
                    VStack(alignment: .leading, spacing: 15) {
                        DetailRow(icon: "calendar", text: DateFormatter.dateOnly.string(from: event.date))
                        DetailRow(icon: "mappin.and.ellipse", text: event.location)
                        if let price = event.ticketPrice {
                            DetailRow(icon: "ticket.fill", text: price)
                        }
                        if let website = event.website {
                            DetailRow(icon: "link", text: website)
                        }
                    }
                    .padding(.top)
                    
                    Divider()
                    
                    // Description section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("About This Event")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(event.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 15) {
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "bell.badge")
                                Text("Reminder")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.secondary.opacity(0.1))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.appBlue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.top, 10)
                }
                .padding()
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

// Date formatter extension
extension DateFormatter {
    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
} 
