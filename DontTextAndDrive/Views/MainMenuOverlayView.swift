import SwiftUI

struct MainMenuOverlayView: View {
    var engine: GameEngine
    @State private var isStartPressed: Bool = false
    @State private var floatingOffset: CGFloat = 0.0
    
    var body: some View {
        VStack {
            // 1. Top Section: Floating Logo SVG
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 320, maxHeight: 180)
                .shadow(color: Color.cyan.opacity(0.45), radius: 18, y: 6)
                .offset(y: floatingOffset)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                        floatingOffset = -8
                    }
                }
                .padding(.top, 56)
            
            Spacer()
            
            // 2. Bottom Section: START DRIVING Button
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    engine.startGame()
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 22, weight: .black))
                    Text("START DRIVING")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.1, green: 0.85, blue: 0.4), Color(red: 0.05, green: 0.6, blue: 0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                .shadow(color: Color.green.opacity(0.6), radius: 16, y: 6)
                .scaleEffect(isStartPressed ? 0.94 : 1.0)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isStartPressed = true }
                    .onEnded { _ in isStartPressed = false }
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}
