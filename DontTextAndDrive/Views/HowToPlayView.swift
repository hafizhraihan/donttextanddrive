import SwiftUI

struct HowToPlayView: View {
    var onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "car.fill")
                        .foregroundColor(.cyan)
                    Image(systemName: "ellipsis.message.fill")
                        .foregroundColor(.yellow)
                }
                .font(.system(size: 28))
                
                Text("DON'T TEXT & DRIVE")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("A Fast-Paced Multitasking Survival Game")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.cyan)
            }
            
            // 3 Core Mechanics Cards
            VStack(spacing: 12) {
                InstructionCard(
                    stepNumber: "1",
                    icon: "iphone.radiowaves.left.and.right",
                    title: "TILT TO DRIVE",
                    description: "Tilt your iPhone left or right to steer your compact car and dodge incoming traffic.",
                    accentColor: .cyan
                )
                
                InstructionCard(
                    stepNumber: "2",
                    icon: "keyboard.fill",
                    title: "TYPE & TEXT",
                    description: "Reply to urgent chats from Boss, Mom, or Crush. Red lights halt traffic giving you safe time to type!",
                    accentColor: .orange
                )
                
                InstructionCard(
                    stepNumber: "3",
                    icon: "speaker.wave.3.fill",
                    title: "HONK (KLAKSON)",
                    description: "Pedestrians cross the street! Tap the giant HONK button to freeze them in their tracks.",
                    accentColor: .red
                )
            }
            .padding(.horizontal, 10)
            
            // Start Game Button
            Button(action: {
                onStart()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                    Text("START DRIVING")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.1, green: 0.8, blue: 0.4), Color(red: 0.05, green: 0.6, blue: 0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.green.opacity(0.4), radius: 10, y: 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.1, green: 0.11, blue: 0.14))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.15), lineWidth: 1))
        )
        .padding(.horizontal, 16)
    }
}

struct InstructionCard: View {
    let stepNumber: String
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
    }
}
