import SwiftUI

struct Pedestrian: Identifiable {
    let id: UUID = UUID()
    var x: CGFloat            // Horizontal coordinate across road (-1.2 to 1.2)
    var y: CGFloat            // Vertical position down the road
    var direction: CGFloat    // +1 (left to right) or -1 (right to left)
    var walkSpeed: CGFloat    // Crossing velocity
    var isAlerted: Bool = false  // True when frozen by car horn (honk)
    var alertTimer: TimeInterval = 0.0
    var hasCrossed: Bool = false
    var isHit: Bool = false
    var savedByHonk: Bool = false
    var walkCycle: CGFloat = 0.0
    
    var shirtColor: Color
    var pantsColor: Color
    var hatColor: Color?
    var hasUmbrella: Bool
    
    static func random(yPos: CGFloat) -> Pedestrian {
        let direction: CGFloat = Bool.random() ? 1.0 : -1.0
        let startX: CGFloat = direction > 0 ? -1.15 : 1.15
        
        let shirts: [Color] = [
            Color(red: 0.9, green: 0.3, blue: 0.3),
            Color(red: 0.2, green: 0.6, blue: 0.9),
            Color(red: 0.95, green: 0.75, blue: 0.1),
            Color(red: 0.3, green: 0.8, blue: 0.4),
            Color(red: 0.7, green: 0.4, blue: 0.9)
        ]
        
        let pants: [Color] = [
            Color(red: 0.15, green: 0.2, blue: 0.3),
            Color(red: 0.2, green: 0.2, blue: 0.2),
            Color(red: 0.4, green: 0.3, blue: 0.2)
        ]
        
        return Pedestrian(
            x: startX,
            y: yPos,
            direction: direction,
            walkSpeed: CGFloat.random(in: 0.35...0.6),
            shirtColor: shirts.randomElement()!,
            pantsColor: pants.randomElement()!,
            hatColor: Bool.random() ? Color.yellow : nil,
            hasUmbrella: Bool.random()
        )
    }
    
    mutating func triggerHonkAlert() {
        if !isAlerted {
            isAlerted = true
            savedByHonk = true
            alertTimer = 3.5 // Freeze for 3.5 seconds
        }
    }
    
    mutating func update(deltaTime: TimeInterval, roadScrollSpeed: CGFloat) {
        // Move down with the road
        y += roadScrollSpeed * CGFloat(deltaTime)
        
        if isAlerted {
            alertTimer -= deltaTime
            if alertTimer <= 0 {
                isAlerted = false
            }
        } else {
            // Walk horizontally across road
            x += direction * walkSpeed * CGFloat(deltaTime)
            walkCycle += CGFloat(deltaTime) * 8.0
            
            if (direction > 0 && x > 1.25) || (direction < 0 && x < -1.25) {
                hasCrossed = true
            }
        }
    }
}
