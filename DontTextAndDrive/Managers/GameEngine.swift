import SwiftUI
import Combine

struct ScorePopup: Identifiable {
    let id: UUID = UUID()
    var text: String
    var color: Color
    var x: CGFloat
    var y: CGFloat
    var opacity: Double = 1.0
    var scale: CGFloat = 1.0
}

enum TrafficLightPhase: Equatable {
    case none
    case approaching
    case red
    case yellow
    case green
    
    var isSafeToType: Bool {
        self == .red || self == .yellow || self == .approaching
    }
}

@Observable
final class GameEngine {
    // Sub-systems
    var motionManager = MotionManager()
    var soundManager = SoundManager.shared
    
    // Core Game State
    var status: GameStatus = .playing
    var stats: GameStats = GameStats()
    
    // Traffic Light (Lampu Merah) Safe Zone System
    var trafficLightPhase: TrafficLightPhase = .none
    var trafficLightY: CGFloat = -0.5       // Position of overhead traffic light gantry (0.38 is stop line)
    var trafficLightTimer: TimeInterval = 0.0
    var trafficLightCooldown: TimeInterval = 12.0 // Initial countdown to first red light
    
    // Road & Player Properties
    var playerX: CGFloat = 0.0          // Normalized: -0.85 (far left) to +0.85 (far right)
    var playerSteerAngle: CGFloat = 0.0 // Visual car rotation angle in degrees
    var playerTargetX: CGFloat = 0.0
    var roadScrollOffset: CGFloat = 0.0
    var roadBaseSpeed: CGFloat = 380.0  // pixels per second
    
    // Road entities
    var trafficVehicles: [Vehicle] = []
    var pedestrians: [Pedestrian] = []
    var crosswalkOffsets: [CGFloat] = [0.0, 1200.0]
    
    // Texting / Phone State
    var activePrompt: MessagePrompt?
    var typedText: String = ""
    var messageTimeRemaining: TimeInterval = 0.0
    var chatHistory: [ChatMessage] = []
    private var promptQueueTimer: TimeInterval = 1.0
    
    // Honk (Klakson) State
    var isHonking: Bool = false
    var honkWaveRadius: CGFloat = 0.0
    var honkCooldown: TimeInterval = 0.0
    
    // Effects & Feedback
    var screenShake: CGFloat = 0.0
    var typingErrorShake: CGFloat = 0.0
    var scorePopups: [ScorePopup] = []
    
    // Spawn Timers
    private var vehicleSpawnTimer: TimeInterval = 0.0
    private var pedestrianSpawnTimer: TimeInterval = 0.0
    private var lastUpdateTime: Date = Date()
    
    init() {
        resetGame()
    }
    
    // MARK: - Game Lifecycle
    
    func startGame() {
        resetGame()
        status = .playing
        motionManager.start()
        motionManager.calibrate()
        
        // Spawn first message after 1.5 seconds
        promptQueueTimer = 1.2
    }
    
    func pauseGame() {
        if status == .playing {
            status = .paused
        } else if status == .paused {
            status = .playing
        }
    }
    
    func resetGame() {
        stats.reset()
        playerX = 0.0
        playerSteerAngle = 0.0
        playerTargetX = 0.0
        roadScrollOffset = 0.0
        trafficVehicles.removeAll()
        pedestrians.removeAll()
        scorePopups.removeAll()
        chatHistory.removeAll()
        
        activePrompt = nil
        typedText = ""
        messageTimeRemaining = 0.0
        promptQueueTimer = 0.0
        
        trafficLightPhase = .none
        trafficLightY = -0.5
        trafficLightTimer = 0.0
        trafficLightCooldown = Double.random(in: 12.0...16.0)
        
        isHonking = false
        honkWaveRadius = 0.0
        honkCooldown = 0.0
        screenShake = 0.0
        typingErrorShake = 0.0
        
        vehicleSpawnTimer = 0.5
        pedestrianSpawnTimer = 3.0
    }
    
    // MARK: - Main Game Loop (called from TimelineView / DisplayLink)
    
    func update(currentTime: Date) {
        let dt = min(0.05, currentTime.timeIntervalSince(lastUpdateTime))
        lastUpdateTime = currentTime
        
        guard status == .playing else { return }
        
        // 1. Update Player Steering from Gyro / Touch
        let tilt = motionManager.tilt
        playerSteerAngle = tilt * 28.0 // Rotate car visually up to 28 degrees
        
        let steerSpeed: CGFloat = 2.4
        playerX += tilt * steerSpeed * CGFloat(dt)
        playerX = max(-0.85, min(0.85, playerX))
        
        // 2. Traffic Light (Lampu Merah) State Machine & Deceleration / Acceleration
        var speedFactor: CGFloat = 1.0
        switch trafficLightPhase {
        case .none:
            trafficLightCooldown -= dt
            if trafficLightCooldown <= 0 {
                trafficLightPhase = .approaching
                trafficLightY = -0.45
            }
        case .approaching:
            let stopTargetY: CGFloat = 0.38
            let distanceToStop = max(0.0, stopTargetY - trafficLightY)
            // Smoothly decelerate as the overhead light and stop line approach
            speedFactor = max(0.12, distanceToStop / 0.83)
            trafficLightY += (roadBaseSpeed / 600.0) * speedFactor * CGFloat(dt)
            
            if trafficLightY >= stopTargetY {
                trafficLightY = stopTargetY
                trafficLightPhase = .red
                trafficLightTimer = 7.0 // 7.0 seconds of safe, relaxed typing at red light
                soundManager.playRedLightStop()
                addScorePopup(text: "RED LIGHT! 🔴 SAFE TO TYPE", color: .red)
            }
        case .red:
            speedFactor = 0.0
            trafficLightTimer -= dt
            if trafficLightTimer <= 0 {
                trafficLightPhase = .yellow
                trafficLightTimer = 1.8
                soundManager.playLightWarningTick()
                addScorePopup(text: "GET READY! 🟡", color: .yellow)
            }
        case .yellow:
            speedFactor = 0.0
            trafficLightTimer -= dt
            if trafficLightTimer <= 0 {
                trafficLightPhase = .green
                trafficLightTimer = 2.5
                soundManager.playGreenLightGo()
                addScorePopup(text: "GREEN LIGHT! 🟢 GO!", color: .green)
            }
        case .green:
            // Accelerate smoothly back up to speed
            let progress = min(1.0, (2.5 - trafficLightTimer) / 1.5)
            speedFactor = max(0.2, CGFloat(progress))
            trafficLightTimer -= dt
            trafficLightY += (roadBaseSpeed / 600.0) * speedFactor * CGFloat(dt) * 1.5
            
            if trafficLightY > 1.4 || trafficLightTimer <= 0 {
                trafficLightPhase = .none
                trafficLightY = -0.5
                trafficLightCooldown = Double.random(in: 18.0...26.0)
            }
        }
        
        // 3. Road Speed & Distance Progression
        let targetSpeedKmh = 60.0 + min(70.0, stats.distanceMeters * 0.04)
        let currentSpeedKmh = targetSpeedKmh * Double(speedFactor)
        stats.currentSpeedKmh = currentSpeedKmh
        let currentRoadPixelsPerSec = roadBaseSpeed * CGFloat(targetSpeedKmh / 60.0) * speedFactor
        
        if speedFactor > 0 {
            roadScrollOffset += currentRoadPixelsPerSec * CGFloat(dt)
            stats.distanceMeters += (currentSpeedKmh * 1000.0 / 3600.0) * dt
            stats.addScore(Int(10.0 * dt * stats.currentMultiplier), multiplier: 1.0)
        }
        
        // 4. Honk Wave Animation & Cooldown
        if isHonking {
            honkWaveRadius += CGFloat(dt) * 3.0
            if honkWaveRadius >= 1.0 {
                isHonking = false
                honkWaveRadius = 0.0
            }
        }
        if honkCooldown > 0 {
            honkCooldown -= dt
        }
        
        // 5. Update Oncoming Vehicles
        for i in (0..<trafficVehicles.count).reversed() {
            let vSpeed = speedFactor > 0 ? (currentRoadPixelsPerSec + trafficVehicles[i].speed) / 600.0 : (trafficVehicles[i].speed / 600.0 * 0.4)
            trafficVehicles[i].y += vSpeed * CGFloat(dt)
            
            // Check near miss bonus
            if !trafficVehicles[i].passedPlayer && trafficVehicles[i].y > 0.85 {
                trafficVehicles[i].passedPlayer = true
                if abs(trafficVehicles[i].x - playerX) < 0.35 {
                    stats.closeCalls += 1
                    addScorePopup(text: "CLOSE CALL! +50", color: .yellow)
                    stats.addScore(50, multiplier: stats.currentMultiplier)
                }
            }
            
            // Remove vehicles off-screen
            if trafficVehicles[i].y > 1.3 {
                trafficVehicles.remove(at: i)
            }
        }
        
        // 6. Update Pedestrians
        for i in (0..<pedestrians.count).reversed() {
            let relativeScroll = currentRoadPixelsPerSec / 600.0
            pedestrians[i].update(deltaTime: dt, roadScrollSpeed: relativeScroll)
            
            // Remove off-screen
            if pedestrians[i].y > 1.3 || pedestrians[i].hasCrossed {
                pedestrians.remove(at: i)
            }
        }
        
        // 7. Spawn Vehicles & Pedestrians (avoid spawning onto player during red light stop)
        if trafficLightPhase == .none || trafficLightPhase == .green {
            vehicleSpawnTimer -= dt
            if vehicleSpawnTimer <= 0 {
                spawnVehicle()
                vehicleSpawnTimer = Double.random(in: 1.4...2.8) - min(0.8, stats.distanceMeters * 0.001)
            }
            
            pedestrianSpawnTimer -= dt
            if pedestrianSpawnTimer <= 0 {
                spawnPedestrian()
                pedestrianSpawnTimer = Double.random(in: 5.0...9.0)
            }
        }
        
        // 8. Update Texting Prompt
        updateTexting(deltaTime: dt)
        
        // 9. Collision Detection
        checkCollisions()
        
        // 10. Update Screen Shake, Typing Error Shake & Score Popups
        if screenShake > 0 {
            screenShake = max(0, screenShake - CGFloat(dt) * 6.0)
        }
        if typingErrorShake > 0 {
            typingErrorShake = max(0, typingErrorShake - CGFloat(dt) * 8.0)
        }
        
        for i in (0..<scorePopups.count).reversed() {
            scorePopups[i].y -= CGFloat(dt) * 40.0
            scorePopups[i].opacity -= dt * 0.8
            if scorePopups[i].opacity <= 0 {
                scorePopups.remove(at: i)
            }
        }
    }
    
    // MARK: - Honk (Klakson) Mechanic
    
    func triggerHonk() {
        guard status == .playing else { return }
        
        isHonking = true
        honkWaveRadius = 0.0
        honkCooldown = 0.3
        soundManager.playHonk()
        
        // Check pedestrians ahead of player
        // Player is around Y = 0.80. Ahead means Y between 0.30 and 0.82
        var alertedCount = 0
        for i in 0..<pedestrians.count {
            let ped = pedestrians[i]
            let isAhead = ped.y > 0.25 && ped.y < 0.85
            let isCloseX = abs(ped.x - playerX) < 0.75
            
            if isAhead && isCloseX {
                if !pedestrians[i].isAlerted {
                    pedestrians[i].triggerHonkAlert()
                    stats.pedestriansSaved += 1
                    stats.addScore(150, multiplier: stats.currentMultiplier)
                    addScorePopup(text: "PEDESTRIAN STOPPED! 🛑 +150", color: .green)
                    alertedCount += 1
                }
            }
        }
        
        if alertedCount > 0 {
            soundManager.playPedestrianSaved()
        }
    }
    
    // MARK: - Texting Mechanics
    
    private func updateTexting(deltaTime: TimeInterval) {
        if activePrompt == nil {
            promptQueueTimer -= deltaTime
            if promptQueueTimer <= 0 {
                loadNextPrompt()
            }
        } else {
            // During Red Light (and Yellow), message timer is FROZEN so the player can type with full comfort!
            if trafficLightPhase != .red && trafficLightPhase != .yellow {
                messageTimeRemaining -= deltaTime
            }
            
            if messageTimeRemaining <= 0 && trafficLightPhase != .red {
                // Time Expired Penalty
                soundManager.playCrash()
                screenShake = 1.0
                addScorePopup(text: "MISSED MESSAGE! ⚠️", color: .red)
                stats.currentMultiplier = max(1.0, stats.currentMultiplier - 0.5)
                
                if let prompt = activePrompt {
                    chatHistory.append(ChatMessage(
                        senderName: prompt.contactName,
                        avatarEmoji: prompt.avatarEmoji,
                        text: "HELLO?! ARE YOU IGNORING ME?!",
                        isFromPlayer: false
                    ))
                }
                
                activePrompt = nil
                typedText = ""
                promptQueueTimer = 2.0
            }
        }
    }
    
    func loadNextPrompt() {
        let prompt = MessagePrompt.random()
        activePrompt = prompt
        typedText = ""
        messageTimeRemaining = prompt.urgencySeconds
        
        // Add to chat history
        chatHistory.append(ChatMessage(
            senderName: prompt.contactName,
            avatarEmoji: prompt.avatarEmoji,
            text: prompt.incomingText,
            isFromPlayer: false
        ))
        
        soundManager.playIncomingMessage()
    }
    
    // MARK: - Monkeytype Typing Helpers
    
    /// Returns true if any typed character does not match the target character at that index or if extra characters exist
    var hasTypingError: Bool {
        guard let prompt = activePrompt else { return false }
        let target = prompt.targetReply
        if typedText.count > target.count { return true }
        
        for (i, char) in typedText.enumerated() {
            let targetIndex = target.index(target.startIndex, offsetBy: i)
            if String(char).lowercased() != String(target[targetIndex]).lowercased() {
                return true
            }
        }
        return false
    }
    
    /// Returns true if the message is fully typed with 0 uncorrected errors
    var isTextCompleteAndValid: Bool {
        guard let prompt = activePrompt else { return false }
        return typedText.count == prompt.targetReply.count && !hasTypingError
    }
    
    /// Returns the index of the first mistyped character if one exists
    var firstTypoIndex: Int? {
        guard let prompt = activePrompt else { return nil }
        let target = prompt.targetReply
        for (i, char) in typedText.enumerated() {
            if i >= target.count { return i }
            let targetIndex = target.index(target.startIndex, offsetBy: i)
            if String(char).lowercased() != String(target[targetIndex]).lowercased() {
                return i
            }
        }
        return nil
    }
    
    func handleKeyInput(_ char: Character) {
        guard status == .playing, let prompt = activePrompt else { return }
        
        stats.totalKeystrokes += 1
        let target = prompt.targetReply
        let nextIndex = typedText.count
        
        if nextIndex < target.count {
            let targetChar = target[target.index(target.startIndex, offsetBy: nextIndex)]
            
            // Check character match (case-insensitive for arcade fluidity)
            let isMatch = String(char).lowercased() == String(targetChar).lowercased()
            
            if isMatch {
                typedText.append(targetChar)
                soundManager.playKeyClick()
                stats.addScore(15, multiplier: stats.currentMultiplier)
            } else {
                // Monkeytype typo: record wrong letter, sound error buzz, trigger shake
                typedText.append(char)
                stats.typosCount += 1
                stats.currentMultiplier = max(1.0, stats.currentMultiplier - 0.25)
                typingErrorShake = 1.0
                soundManager.playTypoError()
            }
        } else if typedText.count < target.count + 5 {
            // Typing beyond message length: register overflow typo
            typedText.append(char)
            stats.typosCount += 1
            typingErrorShake = 1.0
            soundManager.playTypoError()
        }
    }
    
    func handleBackspace() {
        guard status == .playing, !typedText.isEmpty else { return }
        typedText.removeLast()
        soundManager.playKeyClick()
    }
    
    func sendCurrentMessage() {
        guard status == .playing, let prompt = activePrompt else { return }
        
        guard !typedText.isEmpty else {
            typingErrorShake = 0.6
            soundManager.playTypoError()
            addScorePopup(text: "TYPE SOMETHING FIRST! ⌨️", color: .orange)
            return
        }
        
        let target = prompt.targetReply
        let totalChars = max(target.count, typedText.count)
        
        // Calculate character accuracy for this specific message
        var correctChars = 0
        for (i, char) in typedText.enumerated() {
            if i < target.count {
                let targetIndex = target.index(target.startIndex, offsetBy: i)
                if String(char).lowercased() == String(target[targetIndex]).lowercased() {
                    correctChars += 1
                }
            }
        }
        
        let messageAccuracy = totalChars > 0 ? Double(correctChars) / Double(totalChars) : 0.0
        
        // Record in chat history (preserving any humorous typos!)
        chatHistory.append(ChatMessage(
            senderName: "Me",
            avatarEmoji: "🚗",
            text: typedText,
            isFromPlayer: true
        ))
        
        stats.textsCompleted += 1
        
        // Red light safe stop bonus
        if trafficLightPhase == .red {
            let redBonus = 100
            stats.addScore(redBonus, multiplier: stats.currentMultiplier)
            addScorePopup(text: "SAFE STOP BONUS! 🚦 +\(redBonus)", color: .green)
        }
        
        // Tiered scoring based on typo accuracy
        if messageAccuracy >= 0.95 && typedText.count >= target.count {
            // Tier 1: Perfect / Flawless (100% or near 100%)
            stats.currentMultiplier = min(4.0, stats.currentMultiplier + 0.5)
            let earned = Int(Double(prompt.pointsBonus) * stats.currentMultiplier)
            stats.addScore(earned, multiplier: 1.0)
            addScorePopup(text: "PERFECT TEXT! ✨ +\(earned)", color: .cyan)
            soundManager.playMessageSent()
        } else if messageAccuracy >= 0.70 {
            // Tier 2: Good with minor typos (70% - 94%)
            stats.currentMultiplier = min(4.0, stats.currentMultiplier + 0.2)
            let baseBonus = max(25, Int(Double(prompt.pointsBonus) * 0.70))
            let earned = Int(Double(baseBonus) * stats.currentMultiplier)
            stats.addScore(earned, multiplier: 1.0)
            addScorePopup(text: "TYPO TEXT! 💬 +\(earned)", color: .green)
            soundManager.playMessageSent()
        } else if messageAccuracy >= 0.40 {
            // Tier 3: Messy / Typos (40% - 69%)
            stats.currentMultiplier = max(1.0, stats.currentMultiplier - 0.25)
            let baseBonus = max(15, Int(Double(prompt.pointsBonus) * 0.40))
            let earned = Int(Double(baseBonus) * stats.currentMultiplier)
            stats.addScore(earned, multiplier: 1.0)
            addScorePopup(text: "MESSY TYPO! ⚠️ +\(earned)", color: .yellow)
            soundManager.playMessageSent()
        } else {
            // Tier 4: Mangled (< 40% accuracy)
            stats.currentMultiplier = 1.0 // reset combo
            let earned = max(10, Int(Double(prompt.pointsBonus) * 0.15))
            stats.addScore(earned, multiplier: 1.0)
            addScorePopup(text: "MANGLED TEXT! 🤡 +\(earned)", color: .orange)
            soundManager.playMessageSent()
        }
        
        activePrompt = nil
        typedText = ""
        promptQueueTimer = 2.0
    }
    
    // Quick auto-type next char helper for fast gameplay testing / tap assist
    func autoTypeNextChar() {
        guard let prompt = activePrompt else { return }
        let target = prompt.targetReply
        if typedText.count < target.count {
            let nextIndex = target.index(target.startIndex, offsetBy: typedText.count)
            handleKeyInput(target[nextIndex])
        }
    }
    
    // MARK: - Spawners
    
    private func spawnVehicle() {
        // 4 lanes: -0.65, -0.22, 0.22, 0.65
        let lanes: [CGFloat] = [-0.62, -0.21, 0.21, 0.62]
        guard let laneIdx = (0..<lanes.count).randomElement() else { return }
        
        // Don't spawn on top of existing vehicle
        let xPos = lanes[laneIdx]
        if trafficVehicles.contains(where: { $0.lane == laneIdx && $0.y < 0.2 }) {
            return
        }
        
        var vehicle = Vehicle.randomTraffic(lane: laneIdx, yPos: -0.25, playerSpeed: 1.0)
        vehicle.x = xPos
        trafficVehicles.append(vehicle)
    }
    
    private func spawnPedestrian() {
        let ped = Pedestrian.random(yPos: -0.2)
        pedestrians.append(ped)
    }
    
    // MARK: - Collision Detection
    
    private func checkCollisions() {
        let playerWidth: CGFloat = 0.16
        let playerHeight: CGFloat = 0.14
        let playerY: CGFloat = 0.80
        
        let playerMinX = playerX - playerWidth / 2.0
        let playerMaxX = playerX + playerWidth / 2.0
        let playerMinY = playerY - playerHeight / 2.0
        let playerMaxY = playerY + playerHeight / 2.0
        
        // 1. Check Traffic Collisions
        for vehicle in trafficVehicles {
            let vWidth: CGFloat = 0.16
            let vHeight: CGFloat = 0.14
            let vMinX = vehicle.x - vWidth / 2.0
            let vMaxX = vehicle.x + vWidth / 2.0
            let vMinY = vehicle.y - vHeight / 2.0
            let vMaxY = vehicle.y + vHeight / 2.0
            
            if !(playerMaxX < vMinX || playerMinX > vMaxX || playerMaxY < vMinY || playerMinY > vMaxY) {
                triggerGameOver(
                    reason: "Rear-ended into a \(vehicle.type.displayName)!",
                    vehicleHit: vehicle.type.displayName
                )
                return
            }
        }
        
        // 2. Check Pedestrian Collisions
        for ped in pedestrians {
            // If pedestrian is stopped outside our lane, safe!
            let pedWidth: CGFloat = 0.11
            let pedHeight: CGFloat = 0.08
            let pMinX = ped.x - pedWidth / 2.0
            let pMaxX = ped.x + pedWidth / 2.0
            let pMinY = ped.y - pedHeight / 2.0
            let pMaxY = ped.y + pedHeight / 2.0
            
            if !(playerMaxX < pMinX || playerMinX > pMaxX || playerMaxY < pMinY || playerMinY > pMaxY) {
                let note = ped.isAlerted ? "Crashed into a waiting pedestrian!" : "Hit a pedestrian because you didn't HONK!"
                triggerGameOver(
                    reason: note,
                    vehicleHit: "Crossing Pedestrian"
                )
                return
            }
        }
    }
    
    private func triggerGameOver(reason: String, vehicleHit: String) {
        status = .gameOver
        motionManager.stop()
        soundManager.playCarCrashHaptic()
        soundManager.playCrash()
        screenShake = 2.5
        
        let unfinished = activePrompt != nil ? "\(typedText)... (Target: '\(activePrompt?.targetReply ?? "")')" : "None"
        let contact = activePrompt?.contactName ?? "Nobody"
        
        stats.crashInfo = CrashInfo(
            reason: reason,
            unfinishedText: unfinished,
            contactName: contact,
            speedAtImpact: stats.currentSpeedKmh,
            vehicleHit: vehicleHit
        )
    }
    
    private func addScorePopup(text: String, color: Color) {
        scorePopups.append(ScorePopup(
            text: text,
            color: color,
            x: playerX,
            y: 0.75
        ))
    }
}
