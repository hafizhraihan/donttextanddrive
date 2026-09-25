import SwiftUI

struct GameOverModalView: View {
    var engine: GameEngine
    
    var body: some View {
        ZStack {
            // Dark Backdrop
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                // Warning Header
                VStack(spacing: 4) {
                
                    Text("CRASHED!")
                        .font(.system(size: 27, weight: .black, design: .rounded))
                        .foregroundColor(.red)

                    Text("Don't Text and Drive")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.gray)
                }
                
                // Big Overall Score in the Middle
                VStack(spacing: 2) {
                    HStack(spacing: 6) {
                        Text("FINAL SCORE")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundColor(.yellow)
                            .tracking(1.2)
                    }
                    
                    Text("\(engine.stats.score)")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(red: 1.0, green: 0.88, blue: 0.35)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.yellow.opacity(0.45), radius: 10, y: 2)
                    
                    if engine.stats.score >= engine.stats.highScore && engine.stats.score > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 10))
                            Text("NEW HIGH SCORE!")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                        }
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color.yellow.opacity(0.25))
                        .cornerRadius(10)
                        .overlay(Capsule().stroke(Color.yellow.opacity(0.8), lineWidth: 1))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color.yellow.opacity(0.12), Color.purple.opacity(0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.6), Color.purple.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                
                // Other Detailed Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    StatBox(title: "DISTANCE", value: "\(Int(engine.stats.distanceMeters)) m", icon: "road.lanes", color: .yellow)
                    StatBox(title: "TEXTS SENT", value: "\(engine.stats.textsCompleted)", icon: "checkmark.message.fill", color: .yellow)
                    StatBox(title: "ACCURACY", value: engine.stats.accuracyDisplay, icon: "character.cursor.ibeam", color: .yellow)
                    StatBox(title: "TYPOS MADE", value: "\(engine.stats.typosCount)", icon: "exclamationmark.bubble.fill", color: .yellow)
                }
                
                // Action Buttons
                VStack(spacing: 8) {
                    Button(action: {
                        engine.startGame()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 18))
                            Text("TRY AGAIN")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                        .shadow(color: .cyan.opacity(0.5), radius: 8, y: 3)
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            engine.goToMenu()
                        }
                    }) {
                        Text("MAIN MENU")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(.vertical, 4)
                    }
                }
                .padding(.top, 2)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(red: 0.11, green: 0.12, blue: 0.15))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.red.opacity(0.4), lineWidth: 1.5))
            )
            .padding(.horizontal, 16)
        }
    }
}

struct ReportRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
                .frame(width: 16)
            
            Text("\(title):")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gray)
            
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.gray)
            }
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

#Preview {
    GameOverModalView(engine: GameEngine())
}
