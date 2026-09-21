import SwiftUI

struct SteeringHornView: View {
    var engine: GameEngine
    
    @State private var touchDragOffset: CGFloat = 0.0
    @State private var isHornPressed: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // 1. Gyro Tilt Indicator / Calibration
            VStack(spacing: 4) {
                // Visual Leveler
                ZStack {
                    Capsule()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 80, height: 16)
                    
                    // Center reference mark
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 2, height: 16)
                    
                    // Bubble / Tilt Indicator
                    Circle()
                        .fill(abs(engine.motionManager.tilt) < 0.15 ? Color.green : Color.cyan)
                        .frame(width: 12, height: 12)
                        .offset(x: engine.motionManager.tilt * 32)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "gyroscope")
                        .font(.system(size: 10))
                        .foregroundColor(.cyan)
                    Text("GYRO TILT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray)
                }
                
                Button(action: {
                    engine.motionManager.calibrate()
                }) {
                    Text("Calibrate")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cyan.opacity(0.2))
                        .cornerRadius(6)
                }
            }
            .frame(width: 90)
            
            // 2. Giant Tactile HONK (Klakson) Button
            Button(action: {
                engine.triggerHonk()
            }) {
                ZStack {
                    // Outer glow when pressed or honking
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    engine.isHonking ? Color.yellow.opacity(0.6) : Color.orange.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 50
                            )
                        )
                        .frame(width: 90, height: 90)
                    
                    // Button Disc
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: engine.isHonking ?
                                    [Color(red: 1.0, green: 0.8, blue: 0.2), Color(red: 0.9, green: 0.5, blue: 0.0)] :
                                    [Color(red: 0.95, green: 0.35, blue: 0.1), Color(red: 0.75, green: 0.15, blue: 0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
                    
                    VStack(spacing: 2) {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(.white)
                        
                        Text("HONK!")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(isHornPressed || engine.isHonking ? 0.92 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isHornPressed || engine.isHonking)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isHornPressed = true }
                    .onEnded { _ in isHornPressed = false }
            )
            
            // 3. Touch Drag Steering Slider (for Simulator testing / fallback)
            VStack(spacing: 3) {
                Text("TOUCH STEER")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray)
                
                GeometryReader { steerGeo in
                    let trackWidth = steerGeo.size.width
                    let knobPos = (engine.motionManager.tilt + 1.0) / 2.0 * trackWidth
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 24)
                        
                        // Center notch
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 2, height: 24)
                            .position(x: trackWidth / 2.0, y: 12)
                        
                        // Draggable Steering Knob
                        Circle()
                            .fill(
                                LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)
                            )
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                            .shadow(color: .cyan.opacity(0.6), radius: 4)
                            .position(x: max(14, min(trackWidth - 14, knobPos)), y: 12)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let clampedX = max(0, min(trackWidth, value.location.x))
                                let normVal = (clampedX / trackWidth) * 2.0 - 1.0
                                engine.motionManager.setTouchSteering(normVal)
                            }
                            .onEnded { _ in
                                engine.motionManager.releaseTouchSteering()
                            }
                    )
                }
                .frame(height: 28)
                
                HStack {
                    Text("◀ LEFT").font(.system(size: 8, weight: .bold)).foregroundColor(.gray)
                    Spacer()
                    Text("RIGHT ▶").font(.system(size: 8, weight: .bold)).foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.1, green: 0.11, blue: 0.14))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.12), lineWidth: 1))
        )
        .padding(.horizontal, 8)
    }
}
