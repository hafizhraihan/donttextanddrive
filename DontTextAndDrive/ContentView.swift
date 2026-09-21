import SwiftUI

struct ContentView: View {
    @State private var engine = GameEngine()
    
    var body: some View {
        TimelineView(.animation) { timeline in
            ZStack {
                // Cockpit Background
                Color(red: 0.05, green: 0.06, blue: 0.08)
                    .ignoresSafeArea()
                
                VStack(spacing: 4) {
                    // Top: Road Simulation View (Windshield, Oncoming Traffic, Floating HONK & HUD)
                    RoadCanvasView(engine: engine)
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: .infinity)
                    
                    // Bottom: Compact Smartphone Texting Interface
                    PhoneDashboardView(engine: engine)
                        .padding(.bottom, 2)
                }
                .padding(.top, 2)
                .padding(.horizontal, 4)
                
                // Menu / Tutorial Modal Overlay
                if engine.status == .menu {
                    ZStack {
                        Color.black.opacity(0.85)
                            .ignoresSafeArea()
                        HowToPlayView {
                            engine.startGame()
                        }
                    }
                    .transition(.opacity)
                }
                
                // Game Over Modal Overlay
                if engine.status == .gameOver {
                    GameOverModalView(engine: engine)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .onChange(of: timeline.date) { oldDate, newDate in
                engine.update(currentTime: newDate)
            }
            .onAppear {
                engine.motionManager.checkAvailability()
            }
            .onDisappear {
                engine.motionManager.stop()
            }
            // Hardware keyboard typing support for Xcode Simulator
            .onKeyPress { keyPress in
                if engine.status == .playing {
                    if keyPress.key == .space {
                        engine.handleKeyInput(" ")
                        return .handled
                    } else if keyPress.key == .return {
                        engine.sendCurrentMessage()
                        return .handled
                    } else if keyPress.key == .delete {
                        engine.handleBackspace()
                        return .handled
                    } else if let char = keyPress.characters.first {
                        engine.handleKeyInput(char)
                        return .handled
                    }
                }
                return .ignored
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
