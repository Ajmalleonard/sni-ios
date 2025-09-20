// Route information model
struct RouteInfo {
    let fromLocation: SearchLocation
    let toLocation: SearchLocation
    let distance: String
    let duration: String
    let estimatedCost: String
    let routePolyline: String? // For drawing the route on map
    
    var summary: String {
        "\(distance) • \(duration) • \(estimatedCost)"
    }
}
