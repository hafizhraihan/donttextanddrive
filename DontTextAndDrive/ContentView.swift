import SwiftUI

struct ContentView: View {
    @State private var engine = GameEngine()
    
    var body: some View {
        TimelineView(.animation) { timeline in
            ZStack {
                // Cockpit Background
                Color(red: 0.05, green: 0.06, blue: 0.08)
                    .ignoresSafeArea()
                
                // Unified Layout: RoadCanvasView maintains the EXACT same size, position, and aspect ratio
                VStack(spacing: 4) {
                    RoadCanvasView(engine: engine)
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: .infinity)
                    
                    if engine.status == .playing || engine.status == .paused {
                        PhoneDashboardView(engine: engine)
                            .padding(.bottom, 2)
                            .transition(.opacity)
                    } else {
                        // In Menu: Reserve the exact bottom area for the START button, keeping the road canvas at its exact gameplay size & position
                        Color.clear
                            .frame(height: 75)
                            .padding(.bottom, 2)
                    }
                }
                .padding(.top, 2)
                .padding(.horizontal, 4)
                
                // Main Menu Overlay: Floating Logo at Top, START button at Bottom
                if engine.status == .menu {
                    MainMenuOverlayView(engine: engine)
                        .transition(.opacity)
                        .zIndex(10)
                }
                
                // Game Over Modal Overlay
                if engine.status == .gameOver {
                    GameOverModalView(engine: engine)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(20)
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
