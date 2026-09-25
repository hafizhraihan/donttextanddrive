import SwiftUI

enum MessageUrgency {
    case normal
    case urgent
    case panic
    
    var color: Color {
        switch self {
        case .normal: return Color.blue
        case .urgent: return Color.orange
        case .panic: return Color.red
        }
    }
}

struct ChatMessage: Identifiable, Equatable {
    let id: UUID = UUID()
    var senderName: String
    var avatarEmoji: String
    var text: String
    var isFromPlayer: Bool
    var timeString: String = "Now"
}

struct MessagePrompt: Identifiable, Equatable {
    let id: UUID = UUID()
    var contactName: String
    var avatarEmoji: String
    var incomingText: String
    var targetReply: String
    var urgencySeconds: TimeInterval
    var pointsBonus: Int
    
    static let promptBank: [MessagePrompt] = [
        MessagePrompt(
            contactName: "Boss",
            avatarEmoji: "briefcase.fill",
            incomingText: "Where are you? Meeting is starting!",
            targetReply: "driving right now",
            urgencySeconds: 12.0,
            pointsBonus: 25
        ),
        MessagePrompt(
            contactName: "Mom",
            avatarEmoji: "heart.fill",
            incomingText: "Are you on your way home for dinner?",
            targetReply: "on my way almost there",
            urgencySeconds: 14.0,
            pointsBonus: 30
        ),
        MessagePrompt(
            contactName: "Sarah",
            avatarEmoji: "sparkles",
            incomingText: "Did you hit traffic on the bridge?",
            targetReply: "stuck in heavy traffic",
            urgencySeconds: 14.0,
            pointsBonus: 30
        ),
        MessagePrompt(
            contactName: "Best Friend",
            avatarEmoji: "gamecontroller.fill",
            incomingText: "Bro are you at the lobby yet?",
            targetReply: "cant text while driving",
            urgencySeconds: 15.0,
            pointsBonus: 35
        ),
        MessagePrompt(
            contactName: "Partner",
            avatarEmoji: "house.fill",
            incomingText: "When will you reach home?",
            targetReply: "heading home now",
            urgencySeconds: 13.0,
            pointsBonus: 25
        ),
        MessagePrompt(
            contactName: "Coworker",
            avatarEmoji: "person.2.fill",
            incomingText: "Client is asking for our ETA!",
            targetReply: "five minutes away",
            urgencySeconds: 13.0,
            pointsBonus: 25
        ),
        MessagePrompt(
            contactName: "Dad",
            avatarEmoji: "car.fill",
            incomingText: "Call me when you get a chance.",
            targetReply: "will call when i park",
            urgencySeconds: 14.0,
            pointsBonus: 30
        ),
        MessagePrompt(
            contactName: "Alex",
            avatarEmoji: "clock.fill",
            incomingText: "The movie starts in ten minutes!",
            targetReply: "running late see you soon",
            urgencySeconds: 15.0,
            pointsBonus: 35
        ),
        MessagePrompt(
            contactName: "Sister",
            avatarEmoji: "bubble.left.fill",
            incomingText: "Are you still near downtown?",
            targetReply: "on the highway right now",
            urgencySeconds: 14.0,
            pointsBonus: 30
        ),
        MessagePrompt(
            contactName: "David",
            avatarEmoji: "phone.fill",
            incomingText: "Can we talk about the project?",
            targetReply: "at a red light talk soon",
            urgencySeconds: 14.0,
            pointsBonus: 30
        ),
        MessagePrompt(
            contactName: "Sam",
            avatarEmoji: "mappin.and.ellipse",
            incomingText: "We are waiting outside for you!",
            targetReply: "pulling up in two minutes",
            urgencySeconds: 15.0,
            pointsBonus: 35
        ),
        MessagePrompt(
            contactName: "Manager",
            avatarEmoji: "building.2.fill",
            incomingText: "Did you head out for the venue?",
            targetReply: "just left will be there soon",
            urgencySeconds: 16.0,
            pointsBonus: 40
        )
    ]
    
    static func random(excluding: [UUID] = []) -> MessagePrompt {
        let available = promptBank.filter { !excluding.contains($0.id) }
        return (available.isEmpty ? promptBank : available).randomElement()!
    }
}
