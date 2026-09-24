import SwiftUI

enum GameStatus: Equatable {
    case menu
    case playing
    case paused
    case gameOver
}

struct CrashInfo {
    var reason: String
    var unfinishedText: String
    var contactName: String
    var speedAtImpact: Double
    var vehicleHit: String
    
    static let `default` = CrashInfo(
        reason: "Crashed into oncoming traffic!",
        unfinishedText: "",
        contactName: "Unknown",
        speedAtImpact: 85.0,
        vehicleHit: "Sedan"
    )
}

struct GameStats {
    var score: Int = 0
    var highScore: Int = UserDefaults.standard.integer(forKey: "DTAD_HighScore")
    var distanceMeters: Double = 0
    var textsCompleted: Int = 0
    var pedestriansSaved: Int = 0
    var closeCalls: Int = 0
    var currentMultiplier: Double = 1.0
    var currentSpeedKmh: Double = 30.0
    var totalKeystrokes: Int = 0
    var typosCount: Int = 0
    var crashInfo: CrashInfo = .default
    
    var accuracyPercentage: Double {
        guard totalKeystrokes > 0 else { return 100.0 }
        let valid = max(0, totalKeystrokes - typosCount)
        return (Double(valid) / Double(totalKeystrokes)) * 100.0
    }
    
    mutating func addScore(_ points: Int, multiplier: Double = 1.0) {
        let earned = Int(Double(points) * multiplier)
        score += earned
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "DTAD_HighScore")
        }
    }
    
    mutating func reset() {
        score = 0
        distanceMeters = 0
        textsCompleted = 0
        pedestriansSaved = 0
        closeCalls = 0
        currentMultiplier = 1.0
        currentSpeedKmh = 30.0
        totalKeystrokes = 0
        typosCount = 0
        crashInfo = .default
    }
}
