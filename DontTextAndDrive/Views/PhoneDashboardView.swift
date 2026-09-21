import SwiftUI

struct PhoneDashboardView: View {
    var engine: GameEngine
    
    // Focus state for Apple's Native Keyboard
    @FocusState private var isKeyboardFocused: Bool
    @State private var nativeInput: String = ""
    
    var body: some View {
        VStack(spacing: 5) {
            // 1. Messages Header & Urgency Bar
            if let prompt = engine.activePrompt {
                HStack(spacing: 6) {
                    // Contact Avatar
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 26, height: 26)
                        Image(systemName: prompt.avatarEmoji)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(prompt.contactName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(prompt.incomingText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Urgency Timer Pill
                    HStack(spacing: 3) {
                        Image(systemName: "timer")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(urgencyColor(time: engine.messageTimeRemaining, maxTime: prompt.urgencySeconds))
                        Text(String(format: "%.1fs", max(0, engine.messageTimeRemaining)))
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .foregroundColor(urgencyColor(time: engine.messageTimeRemaining, maxTime: prompt.urgencySeconds))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(urgencyColor(time: engine.messageTimeRemaining, maxTime: prompt.urgencySeconds).opacity(0.2))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 10)
                .padding(.top, 4)
                
                // Urgency Progress Bar
                GeometryReader { barGeo in
                    let progress = min(1.0, max(0.0, engine.messageTimeRemaining / prompt.urgencySeconds))
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1)).frame(height: 3)
                        Capsule()
                            .fill(urgencyColor(time: engine.messageTimeRemaining, maxTime: prompt.urgencySeconds))
                            .frame(width: barGeo.size.width * CGFloat(progress), height: 3)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 10)
            } else {
                // Idle / Waiting Header
                HStack(spacing: 6) {
                    Image(systemName: "ellipsis.message.fill")
                        .foregroundColor(.cyan)
                        .font(.system(size: 13))
                    Text("Incoming texts will appear here...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            
            // 2. Monkeytype Prompt & Input Bar (Directly Above Apple Keyboard)
            if let prompt = engine.activePrompt {
                HStack(spacing: 8) {
                    Image(systemName: "pencil.line")
                        .foregroundColor(engine.hasTypingError ? .red : .cyan)
                        .font(.system(size: 12))
                    
                    // Monkeytype Character-by-Character Renderer
                    ScrollView(.horizontal, showsIndicators: false) {
                        MonkeytypePromptText(
                            target: prompt.targetReply,
                            typed: engine.typedText
                        )
                    }
                    
                    Spacer()
                    
                    // SEND Action Button
                    Button(action: {
                        engine.sendCurrentMessage()
                        nativeInput = ""
                        isKeyboardFocused = true
                    }) {
                        HStack(spacing: 3) {
                            Text("SEND")
                                .font(.system(size: 12, weight: .heavy))
                            Image(systemName: engine.isTextCompleteAndValid ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(
                            engine.isTextCompleteAndValid ? Color.green :
                            (!engine.typedText.isEmpty ? Color.blue : Color.gray.opacity(0.35))
                        )
                        .cornerRadius(8)
                        .scaleEffect(!engine.typedText.isEmpty ? 1.04 : 1.0)
                        .animation(.spring(response: 0.2), value: !engine.typedText.isEmpty)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            engine.hasTypingError ? Color.red.opacity(0.8) :
                            (engine.isTextCompleteAndValid ? Color.green.opacity(0.8) : Color.cyan.opacity(0.35)),
                            lineWidth: engine.hasTypingError || engine.isTextCompleteAndValid ? 1.5 : 1.0
                        )
                )
                .offset(
                    x: engine.typingErrorShake > 0 ? CGFloat.random(in: -engine.typingErrorShake * 4...engine.typingErrorShake * 4) : 0
                )
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
                .onTapGesture {
                    isKeyboardFocused = true
                }
                
                // Active Native Keyboard Input Channel
                TextField("", text: $nativeInput)
                    .focused($isKeyboardFocused)
                    .autocorrectionDisabled(true)
                    .disableAutocapitalization()
                    .submitLabel(.send)
                    .onSubmit {
                        engine.sendCurrentMessage()
                        nativeInput = ""
                        isKeyboardFocused = true
                    }
                    .onChange(of: nativeInput) { oldValue, newValue in
                        if newValue.count > oldValue.count {
                            let added = newValue.suffix(newValue.count - oldValue.count)
                            for char in added {
                                engine.handleKeyInput(char)
                            }
                        } else if newValue.count < oldValue.count {
                            let diff = oldValue.count - newValue.count
                            for _ in 0..<diff {
                                engine.handleBackspace()
                            }
                        }
                    }
                    .onChange(of: engine.typedText) { _, newTyped in
                        if nativeInput != newTyped {
                            nativeInput = newTyped
                        }
                    }
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.12))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.18), lineWidth: 1))
                .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
        )
        .padding(.horizontal, 6)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isKeyboardFocused = true
            }
        }
        .onChange(of: engine.activePrompt?.id) { _, _ in
            nativeInput = ""
            isKeyboardFocused = true
        }
    }
    
    private func urgencyColor(time: TimeInterval, maxTime: TimeInterval) -> Color {
        let ratio = time / maxTime
        if ratio > 0.5 { return .cyan }
        if ratio > 0.25 { return .orange }
        return .red
    }
}

// MARK: - Monkeytype Character Renderer

struct MonkeytypePromptText: View {
    let target: String
    let typed: String
    
    var body: some View {
        HStack(spacing: 0) {
            let maxLen = max(target.count, typed.count)
            
            ForEach(0..<maxLen, id: \.self) { i in
                // Caret insertion point before this character if this is the active cursor
                if i == typed.count {
                    CaretCursorView()
                }
                
                if i < typed.count {
                    let typedIndex = typed.index(typed.startIndex, offsetBy: i)
                    let typedChar = typed[typedIndex]
                    
                    if i < target.count {
                        let targetIndex = target.index(target.startIndex, offsetBy: i)
                        let targetChar = target[targetIndex]
                        let isMatch = String(typedChar).lowercased() == String(targetChar).lowercased()
                        
                        if isMatch {
                            // Correct Character (Bright White / Cyan)
                            Text(String(targetChar))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        } else {
                            // Monkeytype Error (Bright Red with Red Underline)
                            Text(typedChar == " " ? "␣" : String(typedChar))
                                .font(.system(size: 13, weight: .black, design: .monospaced))
                                .foregroundColor(Color(red: 1.0, green: 0.25, blue: 0.25))
                                .padding(.horizontal, 1)
                                .background(Color.red.opacity(0.3))
                                .cornerRadius(2)
                                .overlay(
                                    Rectangle()
                                        .fill(Color.red)
                                        .frame(height: 1.5)
                                        .offset(y: 7)
                                )
                        }
                    } else {
                        // Extra characters typed past target length
                        Text(typedChar == " " ? "␣" : String(typedChar))
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color(red: 1.0, green: 0.2, blue: 0.2))
                            .background(Color.red.opacity(0.4))
                            .cornerRadius(2)
                    }
                } else {
                    // Untyped Target Character ahead
                    let targetIndex = target.index(target.startIndex, offsetBy: i)
                    let targetChar = target[targetIndex]
                    Text(String(targetChar))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.32))
                }
            }
            
            // Caret cursor at the very end
            if typed.count >= maxLen {
                CaretCursorView()
            }
        }
        .padding(.vertical, 1)
    }
}

struct CaretCursorView: View {
    @State private var isVisible = true
    
    var body: some View {
        Rectangle()
            .fill(Color.cyan)
            .frame(width: 2, height: 14)
            .padding(.horizontal, 0.5)
            .opacity(isVisible ? 1.0 : 0.2)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isVisible = false
                }
            }
    }
}

// MARK: - Cross-Platform Compatibility Extension

extension View {
    @ViewBuilder
    func disableAutocapitalization() -> some View {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        self.textInputAutocapitalization(.never)
        #else
        self
        #endif
    }
}
