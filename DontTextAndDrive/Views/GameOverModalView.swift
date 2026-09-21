import SwiftUI

struct GameOverModalView: View {
    var engine: GameEngine
    
    var body: some View {
        ZStack {
            // Dark Backdrop
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Warning Header
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.25))
                            .frame(width: 70, height: 70)
                        Image(systemName: "car.side.front.open.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.red)
                    }
                    
                    Text("TOTAL WRECK!")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.red)
                    
                    Text("Don't Text and Drive...")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.gray)
                }
                
                // Crash Report Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "newspaper.fill")
                            .foregroundColor(.yellow)
                        Text("CRASH POLICE REPORT")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(.yellow)
                    }
                    
                    Divider().background(Color.white.opacity(0.15))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ReportRow(title: "Cause", value: engine.stats.crashInfo.reason, icon: "exclamationmark.triangle.fill", color: .orange)
                        
                        if !engine.stats.crashInfo.unfinishedText.isEmpty {
                            ReportRow(
                                title: "Drafting",
                                value: "\"\(engine.stats.crashInfo.unfinishedText)\"",
                                icon: "message.badge.filled.fill",
                                color: .cyan
                            )
                        }
                        
                        ReportRow(
                            title: "Impact Speed",
                            value: "\(Int(engine.stats.crashInfo.speedAtImpact)) km/h",
                            icon: "speedometer",
                            color: .red
                        )
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.06))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.15), lineWidth: 1))
                
                // Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    StatBox(title: "DISTANCE", value: "\(Int(engine.stats.distanceMeters)) m", icon: "road.lanes", color: .yellow)
                    StatBox(title: "TEXTS SENT", value: "\(engine.stats.textsCompleted)", icon: "checkmark.message.fill", color: .cyan)
                    StatBox(title: "TYPING ACCURACY", value: String(format: "%.0f%%", engine.stats.accuracyPercentage), icon: "character.cursor.ibeam", color: engine.stats.accuracyPercentage > 90 ? .green : .orange)
                    StatBox(title: "TYPOS MADE", value: "\(engine.stats.typosCount)", icon: "exclamationmark.bubble.fill", color: engine.stats.typosCount == 0 ? .green : .red)
                    StatBox(title: "PEDESTRIANS SAVED", value: "\(engine.stats.pedestriansSaved)", icon: "figure.walk.circle.fill", color: .green)
                    StatBox(title: "FINAL SCORE", value: "\(engine.stats.score)", icon: "star.fill", color: .purple)
                }
                
                // High Score Badge
                if engine.stats.score >= engine.stats.highScore && engine.stats.score > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                        Text("NEW HIGH SCORE!")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(20)
                    .overlay(Capsule().stroke(Color.yellow, lineWidth: 1.5))
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
                        .frame(height: 50)
                        .background(
                            LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                        .shadow(color: .cyan.opacity(0.5), radius: 8, y: 3)
                    }
                    
                    Button(action: {
                        engine.status = .menu
                    }) {
                        Text("MAIN MENU")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(.vertical, 6)
                    }
                }
                .padding(.top, 4)
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.12, green: 0.13, blue: 0.16))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.red.opacity(0.4), lineWidth: 1.5))
            )
            .padding(.horizontal, 20)
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
