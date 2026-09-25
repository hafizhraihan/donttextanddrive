import SwiftUI

struct RoadCanvasView: View {
    var engine: GameEngine
    @State private var isHornPressed: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // 1. Road Background & Markings
                RoadSurfaceView(scrollOffset: engine.roadScrollOffset, width: w, height: h)
                
                // 2. Pedestrians
                ForEach(engine.pedestrians) { ped in
                    PedestrianSpriteView(ped: ped, roadWidth: w, roadHeight: h)
                }
                
                // 3. Traffic Vehicles
                ForEach(engine.trafficVehicles) { vehicle in
                    VehicleSpriteView(vehicle: vehicle, roadWidth: w, roadHeight: h)
                }
                
                // 4. Traffic Light Overhead Gantry & Road Stop Line
                if engine.trafficLightPhase != .none {
                    TrafficLightGantryView(
                        phase: engine.trafficLightPhase,
                        yNorm: engine.trafficLightY,
                        roadWidth: w,
                        roadHeight: h,
                        timer: engine.trafficLightTimer
                    )
                }
                
                // 5. Honk Shockwave Rings
                if engine.isHonking {
                    HonkWaveView(
                        playerX: engine.playerX,
                        playerY: 0.80,
                        radiusProgress: engine.honkWaveRadius,
                        roadWidth: w,
                        roadHeight: h
                    )
                }
                
                // 6. Player's Compact Car (Exact same position, size, and design in menu and gameplay)
                PlayerCarView(
                    xNorm: engine.playerX,
                    yNorm: 0.80,
                    steerAngle: engine.playerSteerAngle,
                    roadWidth: w,
                    roadHeight: h
                )
                
                // 7. Score Popups (during gameplay)
                if engine.status == .playing {
                    ForEach(engine.scorePopups) { popup in
                        Text(popup.text)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(popup.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.8))
                                    .overlay(Capsule().stroke(popup.color, lineWidth: 1.5))
                            )
                            .position(
                                x: w / 2.0 + popup.x * (w * 0.42),
                                y: h * popup.y
                            )
                            .opacity(popup.opacity)
                            .scaleEffect(1.0 + (1.0 - popup.opacity) * 0.3)
                    }
                }
                
                // 8. Top Road HUD Header (Score, Speed, Distance, Light Banners - only during gameplay)
                if engine.status == .playing || engine.status == .paused {
                    VStack(spacing: 8) {
                        HStack(alignment: .center, spacing: 8) {
                            // Help / Menu
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    engine.goToMenu()
                                }
                            }) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.cyan)
                            }
                            
                            // Speedometer Pill
                            HStack(spacing: 4) {
                                Image(systemName: "speedometer")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(engine.trafficLightPhase == .red ? .red : .cyan)
                                Text("\(Int(engine.stats.currentSpeedKmh))")
                                    .font(.system(size: 15, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                                Text("KM/H")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(engine.trafficLightPhase == .red ? .red : .cyan)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(engine.trafficLightPhase == .red ? Color.red.opacity(0.6) : Color.clear, lineWidth: 1)
                            )
                            
                            Spacer()
                            
                            // Distance Tracker
                            HStack(spacing: 4) {
                                Image(systemName: "road.lanes")
                                    .font(.system(size: 11))
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.0f m", engine.stats.distanceMeters))
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            
                            // Pause Button
                            Button(action: {
                                engine.pauseGame()
                            }) {
                                Image(systemName: engine.status == .paused ? "play.circle.fill" : "pause.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.yellow)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 6)
                        
                        // Traffic Light Safe Zone Status Banners
                        if engine.trafficLightPhase == .red {
                            HStack(spacing: 6) {
                                Circle().fill(Color.red).frame(width: 9, height: 9).shadow(color: .red, radius: 5)
                                Text("RED LIGHT — SAFE TO TYPE!")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                Text(String(format: "%.1fs", max(0, engine.trafficLightTimer)))
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .foregroundColor(.yellow)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color(red: 0.1, green: 0.12, blue: 0.18).opacity(0.95))
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.red, lineWidth: 1.5))
                            .shadow(color: .red.opacity(0.5), radius: 8)
                            .transition(.scale.combined(with: .opacity))
                        } else if engine.trafficLightPhase == .yellow {
                            HStack(spacing: 6) {
                                Circle().fill(Color.yellow).frame(width: 9, height: 9).shadow(color: .yellow, radius: 5)
                                Text("GET READY TO DRIVE!")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.yellow)
                            .cornerRadius(20)
                            .shadow(color: .yellow.opacity(0.6), radius: 6)
                            .transition(.scale.combined(with: .opacity))
                        } else if engine.trafficLightPhase == .green {
                            HStack(spacing: 6) {
                                Circle().fill(Color.green).frame(width: 9, height: 9).shadow(color: .green, radius: 5)
                                Text("GREEN LIGHT — GO!")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.9))
                            .cornerRadius(20)
                            .shadow(color: .green.opacity(0.6), radius: 6)
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Pedestrian Warning Banner
                        if engine.pedestrians.contains(where: { $0.y > 0.15 && $0.y < 0.75 && !$0.isAlerted }) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.yellow)
                                Text("PEDESTRIAN CROSSING! TAP HONK!")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.red.opacity(0.9))
                            .cornerRadius(20)
                            .shadow(color: .red.opacity(0.6), radius: 6)
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        Spacer()
                    }
                }
                
                // 9. Floating Tactile HONK Button (Bottom-Right of Road - only during gameplay)
                if engine.status == .playing {
                    VStack {
                        Spacer()
                        HStack {
                            // Multiplier Pill if > 1.0
                            if engine.stats.currentMultiplier > 1.0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(.orange)
                                    Text(String(format: "%.1fx", engine.stats.currentMultiplier))
                                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                                        .foregroundColor(.orange)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.65))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange, lineWidth: 1.5))
                                .padding(.leading, 12)
                            }
                            
                            Spacer()
                            
                            // Giant Floating HONK Button
                            Button(action: {
                                engine.triggerHonk()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [
                                                    engine.isHonking ? Color.yellow.opacity(0.7) : Color.orange.opacity(0.3),
                                                    Color.clear
                                                ],
                                                center: .center,
                                                startRadius: 15,
                                                endRadius: 45
                                            )
                                        )
                                        .frame(width: 80, height: 80)
                                    
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: engine.isHonking ?
                                                    [Color(red: 1.0, green: 0.85, blue: 0.2), Color(red: 0.95, green: 0.5, blue: 0.0)] :
                                                    [Color(red: 0.95, green: 0.3, blue: 0.1), Color(red: 0.75, green: 0.12, blue: 0.05)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 64, height: 64)
                                        .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 2))
                                        .shadow(color: .black.opacity(0.6), radius: 6, y: 3)
                                    
                                    VStack(spacing: 1) {
                                        Image(systemName: "speaker.wave.3.fill")
                                            .font(.system(size: 20, weight: .black))
                                            .foregroundColor(.white)
                                        Text("HONK")
                                            .font(.system(size: 10, weight: .black, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                }
                                .scaleEffect(isHornPressed || engine.isHonking ? 0.90 : 1.0)
                                .animation(.spring(response: 0.18, dampingFraction: 0.6), value: isHornPressed || engine.isHonking)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in isHornPressed = true }
                                    .onEnded { _ in isHornPressed = false }
                            )
                            .padding(.trailing, 12)
                            .padding(.bottom, 8)
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .offset(
                x: engine.screenShake > 0 ? CGFloat.random(in: -engine.screenShake * 5...engine.screenShake * 5) : 0,
                y: engine.screenShake > 0 ? CGFloat.random(in: -engine.screenShake * 5...engine.screenShake * 5) : 0
            )
            // Seamless Touch/Drag steer across the entire road area (for simulator / touch fallback)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let normVal = (value.location.x / w) * 2.0 - 1.0
                        engine.motionManager.setTouchSteering(normVal)
                    }
                    .onEnded { _ in
                        engine.motionManager.releaseTouchSteering()
                    }
            )
        }
    }
}

// MARK: - Road Surface Canvas

struct RoadSurfaceView: View {
    let scrollOffset: CGFloat
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        Canvas { context, size in
            let roadLeft = size.width * 0.08
            let roadRight = size.width * 0.92
            let roadWidth = roadRight - roadLeft
            
            // Sidewalk / Grass background
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.12, green: 0.16, blue: 0.14)))
            
            // Main Asphalt
            let roadRect = CGRect(x: roadLeft, y: 0, width: roadWidth, height: size.height)
            context.fill(Path(roadRect), with: .color(Color(red: 0.14, green: 0.15, blue: 0.18)))
            
            // Road Curbs
            let curbLeft = CGRect(x: roadLeft - 6, y: 0, width: 6, height: size.height)
            let curbRight = CGRect(x: roadRight, y: 0, width: 6, height: size.height)
            context.fill(Path(curbLeft), with: .color(Color(red: 0.85, green: 0.35, blue: 0.2)))
            context.fill(Path(curbRight), with: .color(Color(red: 0.85, green: 0.35, blue: 0.2)))
            
            // Road Lanes (4 lanes, 3 divider lines)
            let laneWidth = roadWidth / 4.0
            let dashHeight: CGFloat = 32.0
            let gapHeight: CGFloat = 28.0
            let totalUnit = dashHeight + gapHeight
            let offsetMod = scrollOffset.truncatingRemainder(dividingBy: totalUnit)
            
            for laneIdx in 1...3 {
                let lineX = roadLeft + CGFloat(laneIdx) * laneWidth
                let isCenterLine = (laneIdx == 2)
                let lineColor = isCenterLine ? Color.yellow.opacity(0.8) : Color.white.opacity(0.6)
                let lineWidth: CGFloat = isCenterLine ? 3.0 : 2.0
                
                var currentY: CGFloat = -totalUnit + offsetMod
                while currentY < size.height + totalUnit {
                    let dashRect = CGRect(x: lineX - lineWidth / 2.0, y: currentY, width: lineWidth, height: dashHeight)
                    context.fill(Path(dashRect), with: .color(lineColor))
                    currentY += totalUnit
                }
            }
            
            // Crosswalk zebra stripes
            let crosswalkInterval: CGFloat = 1200.0
            let crosswalkY = (scrollOffset.truncatingRemainder(dividingBy: crosswalkInterval)) - 100.0
            if crosswalkY > -100 && crosswalkY < size.height + 100 {
                let stripeWidth: CGFloat = 16.0
                let stripeGap: CGFloat = 14.0
                var sx = roadLeft + 8
                while sx < roadRight - 8 {
                    let stripeRect = CGRect(x: sx, y: crosswalkY, width: stripeWidth, height: 44)
                    context.fill(Path(stripeRect), with: .color(Color.white.opacity(0.65)))
                    sx += (stripeWidth + stripeGap)
                }
            }
        }
    }
}

// MARK: - Player Car View

struct PlayerCarView: View {
    let xNorm: CGFloat
    let yNorm: CGFloat
    let steerAngle: CGFloat
    let roadWidth: CGFloat
    let roadHeight: CGFloat
    
    var body: some View {
        let posX = roadWidth / 2.0 + xNorm * (roadWidth * 0.40)
        let posY = roadHeight * yNorm
        
        ZStack {
            // Headlight beams projected forward
            Path { path in
                path.move(to: CGPoint(x: -12, y: -25))
                path.addLine(to: CGPoint(x: -36, y: -160))
                path.addLine(to: CGPoint(x: 36, y: -160))
                path.addLine(to: CGPoint(x: 12, y: -25))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [Color.yellow.opacity(0.35), Color.yellow.opacity(0.0)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            
            // Car Body Container
            ZStack {
                // Drop Shadow
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.45))
                    .frame(width: 44, height: 74)
                    .offset(y: 4)
                
                // Car Chassis
                RoundedRectangle(cornerRadius: 9)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.1, green: 0.75, blue: 0.95), Color(red: 0.05, green: 0.45, blue: 0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 42, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
                
                // Windshields & Roof
                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.1, green: 0.15, blue: 0.25))
                        .frame(width: 32, height: 14)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.05, green: 0.4, blue: 0.75))
                        .frame(width: 30, height: 18)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.1, green: 0.15, blue: 0.25))
                        .frame(width: 30, height: 10)
                }
                
                // Headlights
                VStack {
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.yellow)
                            .frame(width: 6, height: 4)
                        Spacer()
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.yellow)
                            .frame(width: 6, height: 4)
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 2)
                    
                    Spacer()
                    
                    // Glowing Taillights
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.red)
                            .frame(width: 8, height: 4)
                            .shadow(color: .red, radius: 4)
                        Spacer()
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.red)
                            .frame(width: 8, height: 4)
                            .shadow(color: .red, radius: 4)
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 2)
                }
                .frame(width: 42, height: 72)
            }
            .rotationEffect(.degrees(Double(steerAngle)))
        }
        .position(x: posX, y: posY)
    }
}

// MARK: - Vehicle Sprite View

struct VehicleSpriteView: View {
    let vehicle: Vehicle
    let roadWidth: CGFloat
    let roadHeight: CGFloat
    
    var body: some View {
        let posX = roadWidth / 2.0 + vehicle.x * (roadWidth * 0.40)
        let posY = roadHeight * vehicle.y
        let size = vehicle.type.size
        
        ZStack {
            // Drop Shadow
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.5))
                .frame(width: size.width, height: size.height)
                .offset(y: 4)
            
            // Car Body Chassis with High-Contrast Rim
            RoundedRectangle(cornerRadius: 8)
                .fill(vehicle.baseColor)
                .frame(width: size.width, height: size.height)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1.2)
                )
            
            if vehicle.type == .truck {
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.18, green: 0.24, blue: 0.32))
                        .frame(width: size.width - 8, height: 26)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(vehicle.roofColor)
                        .frame(width: size.width - 6, height: 60)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.white.opacity(0.3), lineWidth: 0.8))
                }
            } else if vehicle.type == .taxi {
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.15, green: 0.22, blue: 0.30))
                        .frame(width: size.width - 10, height: 12)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.yellow)
                        .frame(width: 16, height: 7)
                        .overlay(Text("TAXI").font(.system(size: 5, weight: .black)).foregroundColor(.black))
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.black.opacity(0.4), lineWidth: 0.5))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.15, green: 0.22, blue: 0.30))
                        .frame(width: size.width - 10, height: 10)
                }
            } else {
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.15, green: 0.22, blue: 0.32))
                        .frame(width: size.width - 10, height: 12)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(vehicle.roofColor)
                        .frame(width: size.width - 12, height: 16)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 0.15, green: 0.22, blue: 0.32))
                        .frame(width: size.width - 10, height: 8)
                }
            }
            
            // Glowing Headlights & Taillights
            VStack {
                // Front Headlights (Facing Downwards towards player)
                HStack {
                    RoundedRectangle(cornerRadius: 2).fill(Color.yellow).frame(width: 6, height: 3)
                    Spacer()
                    RoundedRectangle(cornerRadius: 2).fill(Color.yellow).frame(width: 6, height: 3)
                }
                .padding(.horizontal, 4)
                .padding(.top, 2)
                
                Spacer()
                
                // Rear Taillights
                HStack {
                    Circle().fill(Color.red).frame(width: 5, height: 5).shadow(color: .red, radius: 3)
                    Spacer()
                    Circle().fill(Color.red).frame(width: 5, height: 5).shadow(color: .red, radius: 3)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 2)
            }
            .frame(width: size.width, height: size.height)
        }
        .position(x: posX, y: posY)
    }
}

// MARK: - Pedestrian Sprite View

struct PedestrianSpriteView: View {
    let ped: Pedestrian
    let roadWidth: CGFloat
    let roadHeight: CGFloat
    
    var body: some View {
        let posX = roadWidth / 2.0 + ped.x * (roadWidth * 0.42)
        let posY = roadHeight * ped.y
        
        ZStack {
            if ped.isAlerted {
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.yellow)
                        Text("STOPPED")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.yellow, lineWidth: 1.5))
                    
                    Spacer().frame(height: 28)
                }
            }
            
            ZStack {
                Capsule()
                    .fill(ped.shirtColor)
                    .frame(width: 22, height: 12)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                
                Circle()
                    .fill(ped.hatColor ?? Color(red: 0.3, green: 0.2, blue: 0.1))
                    .frame(width: 11, height: 11)
                
                if ped.hasUmbrella {
                    Circle()
                        .fill(Color.purple.opacity(0.7))
                        .frame(width: 24, height: 24)
                        .offset(x: 4, y: -4)
                }
            }
            .rotationEffect(.degrees(ped.direction > 0 ? 90 : -90))
        }
        .position(x: posX, y: posY)
    }
}

// MARK: - Honk Wave Animation View

struct HonkWaveView: View {
    let playerX: CGFloat
    let playerY: CGFloat
    let radiusProgress: CGFloat
    let roadWidth: CGFloat
    let roadHeight: CGFloat
    
    var body: some View {
        let posX = roadWidth / 2.0 + playerX * (roadWidth * 0.40)
        let posY = roadHeight * playerY - 30
        let radius = radiusProgress * 220.0
        
        Circle()
            .stroke(
                LinearGradient(
                    colors: [Color.yellow, Color.orange.opacity(0.6), Color.cyan.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: max(1.0, (1.0 - radiusProgress) * 4.0)
            )
            .frame(width: radius * 2, height: radius * 1.6)
            .opacity(Double(1.0 - radiusProgress))
            .position(x: posX, y: posY)
    }
}

// MARK: - Traffic Light Overhead Gantry & Stop Line View

struct TrafficLightGantryView: View {
    let phase: TrafficLightPhase
    let yNorm: CGFloat
    let roadWidth: CGFloat
    let roadHeight: CGFloat
    let timer: TimeInterval
    
    var body: some View {
        let posY = roadHeight * yNorm
        let roadLeft = roadWidth * 0.08
        let roadRight = roadWidth * 0.92
        let roadSpan = roadRight - roadLeft
        
        ZStack {
            // 1. Asphalt White STOP Line and "STOP" Stencil (on road surface)
            VStack(spacing: 4) {
                // STOP stencil painted on asphalt
                Text("STOP")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .tracking(6)
                    .foregroundColor(Color.white.opacity(0.65))
                
                // Solid stop bar across all lanes
                Rectangle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: roadSpan, height: 7)
                    .shadow(color: .white.opacity(0.35), radius: 3)
            }
            .position(x: roadWidth / 2.0, y: posY + 46)
            
            // 2. Overhead Metal Truss & Gantry Structure
            ZStack {
                // Drop shadow for the gantry truss
                Rectangle()
                    .fill(Color.black.opacity(0.55))
                    .frame(width: roadSpan + 14, height: 16)
                    .offset(y: 8)
                
                // Steel Truss Bar
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.35, green: 0.38, blue: 0.42), Color(red: 0.18, green: 0.20, blue: 0.24)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: roadSpan + 14, height: 14)
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    
                    // Diagonal Hazard Stripes on sides
                    HStack {
                        HazardStripesView().frame(width: 22, height: 10)
                        Spacer()
                        HazardStripesView().frame(width: 22, height: 10)
                    }
                    .frame(width: roadSpan + 10)
                }
                
                // 3. Traffic Light Signal Head Units (Dual Head: Left & Right Lanes)
                HStack(spacing: roadSpan * 0.42) {
                    SingleTrafficSignalHead(phase: phase, timer: timer)
                    SingleTrafficSignalHead(phase: phase, timer: timer)
                }
            }
            .position(x: roadWidth / 2.0, y: posY)
        }
    }
}

struct SingleTrafficSignalHead: View {
    let phase: TrafficLightPhase
    let timer: TimeInterval
    
    var isRed: Bool { phase == .red || phase == .approaching }
    var isYellow: Bool { phase == .yellow }
    var isGreen: Bool { phase == .green }
    
    var body: some View {
        VStack(spacing: 3) {
            // Signal Housing
            VStack(spacing: 4) {
                // RED Light Lens
                TrafficLensView(
                    activeColor: .red,
                    isActive: isRed,
                    haloColor: Color(red: 1.0, green: 0.2, blue: 0.2)
                )
                
                // YELLOW Light Lens
                TrafficLensView(
                    activeColor: .yellow,
                    isActive: isYellow,
                    haloColor: Color(red: 1.0, green: 0.85, blue: 0.1)
                )
                
                // GREEN Light Lens
                TrafficLensView(
                    activeColor: Color(red: 0.15, green: 0.95, blue: 0.4),
                    isActive: isGreen,
                    haloColor: Color(red: 0.2, green: 1.0, blue: 0.5)
                )
            }
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.15, green: 0.16, blue: 0.18), Color(red: 0.08, green: 0.09, blue: 0.10)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.yellow.opacity(0.85), lineWidth: 1.2)
                    )
                    .shadow(color: .black.opacity(0.8), radius: 6, y: 3)
            )
            
            // Timer countdown tag under signal if in Red light
            if phase == .red {
                Text(String(format: "%.1fs", max(0, timer)))
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.red.opacity(0.9))
                    .cornerRadius(4)
            }
        }
    }
}

struct TrafficLensView: View {
    let activeColor: Color
    let isActive: Bool
    let haloColor: Color
    
    var body: some View {
        ZStack {
            // Lens Socket
            Circle()
                .fill(Color.black.opacity(0.9))
                .frame(width: 18, height: 18)
            
            if isActive {
                // Glowing bloom
                Circle()
                    .fill(haloColor.opacity(0.5))
                    .frame(width: 28, height: 28)
                    .blur(radius: 3)
                
                // Vibrant Lit Lamp
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white, activeColor, activeColor.opacity(0.85)],
                            center: .center,
                            startRadius: 2,
                            endRadius: 9
                        )
                    )
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1))
                    .shadow(color: haloColor, radius: 6)
            } else {
                // Dimmed / Inactive Lens
                Circle()
                    .fill(activeColor.opacity(0.18))
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
            }
        }
    }
}

struct HazardStripesView: View {
    var body: some View {
        Canvas { context, size in
            let stripeWidth: CGFloat = 3.5
            var x: CGFloat = -size.height
            while x < size.width + size.height {
                var path = Path()
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                path.addLine(to: CGPoint(x: x + size.height + stripeWidth, y: 0))
                path.addLine(to: CGPoint(x: x + stripeWidth, y: size.height))
                path.closeSubpath()
                context.fill(path, with: .color(.yellow.opacity(0.85)))
                x += stripeWidth * 2.5
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}
