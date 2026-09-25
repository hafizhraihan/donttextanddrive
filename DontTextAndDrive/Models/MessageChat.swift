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
            incomingText: "WHERE is the Q3 slide deck?! Board meeting in 5 mins!",
            targetReply: "Sending right now boss!",
            urgencySeconds: 14.0,
            pointsBonus: 30
        ),
        MessagePrompt(
            contactName: "Mom",
            avatarEmoji: "heart.fill",
            incomingText: "Are you driving safely? Did you eat warm soup?",
            targetReply: "Yes mom almost home love u",
            urgencySeconds: 16.0,
            pointsBonus: 25
        ),
        MessagePrompt(
            contactName: "Sarah (Crush)",
            avatarEmoji: "sparkles",
            incomingText: "Are you still coming over tonight or are you busy?",
            targetReply: "On my way right now!",
            urgencySeconds: 12.0,
            pointsBonus: 40
        ),
        MessagePrompt(
            contactName: "Landlord",
            avatarEmoji: "building.2.fill",
            incomingText: "Rent was due yesterday. Where is the transfer?",
            targetReply: "Just transferred check now",
            urgencySeconds: 13.0,
            pointsBonus: 30
        ),
        MessagePrompt(
            contactName: "Best Friend",
            avatarEmoji: "gamecontroller.fill",
            incomingText: "Bro our ranked game starts in 2 mins, lock in!",
            targetReply: "Logging in 2 mins bro",
            urgencySeconds: 11.0,
            pointsBonus: 35
        ),
        MessagePrompt(
            contactName: "Delivery Rider",
            avatarEmoji: "box.truck.fill",
            incomingText: "I am downstairs with pizza, gate is locked!",
            targetReply: "Coming down in 3 mins!",
            urgencySeconds: 12.0,
            pointsBonus: 25
        ),
        MessagePrompt(
            contactName: "Roommate",
            avatarEmoji: "house.fill",
            incomingText: "Whose turn is it to take out the gross trash?",
            targetReply: "I will do it tonight promise",
            urgencySeconds: 14.0,
            pointsBonus: 20
        ),
        MessagePrompt(
            contactName: "Bank Alert",
            avatarEmoji: "creditcard.fill",
            incomingText: "Unusual charge $499.99 detected. Confirm?",
            targetReply: "NO cancel immediately",
            urgencySeconds: 10.0,
            pointsBonus: 45
        )
    ]
    
    static func random(excluding: [UUID] = []) -> MessagePrompt {
        let available = promptBank.filter { !excluding.contains($0.id) }
        return (available.isEmpty ? promptBank : available).randomElement()!
    }
}
