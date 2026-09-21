import SwiftUI

enum VehicleType: CaseIterable {
    case player
    case sedan
    case sportsCar
    case truck
    case deliveryVan
    case taxi
    
    var size: CGSize {
        switch self {
        case .player:
            return CGSize(width: 44, height: 72)
        case .sedan:
            return CGSize(width: 44, height: 74)
        case .sportsCar:
            return CGSize(width: 42, height: 70)
        case .truck:
            return CGSize(width: 52, height: 110)
        case .deliveryVan:
            return CGSize(width: 48, height: 86)
        case .taxi:
            return CGSize(width: 44, height: 74)
        }
    }
    
    var displayName: String {
        switch self {
        case .player: return "Your Compact Car"
        case .sedan: return "Sedan"
        case .sportsCar: return "Sports Car"
        case .truck: return "Semi-Truck"
        case .deliveryVan: return "Amazon Delivery Van"
        case .taxi: return "Yellow Taxi"
        }
    }
}

struct Vehicle: Identifiable {
    let id: UUID = UUID()
    var type: VehicleType
    var lane: Int
    var x: CGFloat       // Normalized -1.0 to 1.0 or pixel relative
    var y: CGFloat       // Vertical position on road (0.0 = top, 1.0 = bottom)
    var speed: CGFloat   // Relative downward/upward speed
    var baseColor: Color
    var roofColor: Color
    var indicatorLeft: Bool = false
    var indicatorRight: Bool = false
    var passedPlayer: Bool = false
    
    static func randomTraffic(lane: Int, yPos: CGFloat, playerSpeed: CGFloat) -> Vehicle {
        let types: [VehicleType] = [.sedan, .sedan, .sportsCar, .truck, .deliveryVan, .taxi]
        let chosenType = types.randomElement() ?? .sedan
        
        let colorPair: (Color, Color)
        switch chosenType {
        case .player:
            colorPair = (Color(red: 0.1, green: 0.7, blue: 1.0), Color(red: 0.05, green: 0.5, blue: 0.9))
        case .sedan:
            let sedans = [
                (Color(red: 0.95, green: 0.25, blue: 0.25), Color(red: 0.80, green: 0.15, blue: 0.15)), // Crimson Red
                (Color(red: 0.25, green: 0.55, blue: 0.95), Color(red: 0.15, green: 0.40, blue: 0.85)), // Royal Blue
                (Color(red: 0.96, green: 0.97, blue: 1.0), Color(red: 0.82, green: 0.85, blue: 0.90)),   // Bright White
                (Color(red: 0.10, green: 0.75, blue: 0.45), Color(red: 0.05, green: 0.60, blue: 0.35)), // Emerald Green
                (Color(red: 0.65, green: 0.35, blue: 0.95), Color(red: 0.50, green: 0.20, blue: 0.85)), // Vivid Purple
                (Color(red: 1.0, green: 0.55, blue: 0.15), Color(red: 0.85, green: 0.40, blue: 0.05))   // Sunset Orange
            ]
            colorPair = sedans.randomElement()!
        case .sportsCar:
            let sports = [
                (Color(red: 1.0, green: 0.20, blue: 0.15), Color(red: 0.85, green: 0.10, blue: 0.05)), // Racing Red
                (Color(red: 0.98, green: 0.88, blue: 0.10), Color(red: 0.85, green: 0.75, blue: 0.05)), // Acid Yellow
                (Color(red: 0.10, green: 0.85, blue: 0.90), Color(red: 0.05, green: 0.70, blue: 0.75))  // Electric Cyan
            ]
            colorPair = sports.randomElement()!
        case .truck:
            let trucks = [
                (Color(red: 0.95, green: 0.96, blue: 0.98), Color(red: 0.20, green: 0.55, blue: 0.90)), // White container + Blue cab
                (Color(red: 0.95, green: 0.25, blue: 0.20), Color(red: 0.92, green: 0.92, blue: 0.95))  // Red cab + Silver container
            ]
            colorPair = trucks.randomElement()!
        case .deliveryVan:
            let vans = [
                (Color(red: 0.96, green: 0.97, blue: 1.0), Color(red: 0.25, green: 0.65, blue: 0.85)),  // Bright White Delivery
                (Color(red: 0.20, green: 0.45, blue: 0.92), Color(red: 0.95, green: 0.75, blue: 0.10))  // Royal Blue & Gold Courier
            ]
            colorPair = vans.randomElement()!
        case .taxi:
            colorPair = (Color(red: 1.0, green: 0.82, blue: 0.0), Color(red: 0.90, green: 0.72, blue: 0.0)) // High-Vis Yellow Taxi
        }
        
        let trafficSpeed: CGFloat = CGFloat.random(in: 0.45...0.75) * playerSpeed
        
        return Vehicle(
            type: chosenType,
            lane: lane,
            x: 0, // Will be set by lane
            y: yPos,
            speed: trafficSpeed,
            baseColor: colorPair.0,
            roofColor: colorPair.1
        )
    }
}
