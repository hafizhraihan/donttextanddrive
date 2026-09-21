import SwiftUI

struct PhoneDashboardView: View {
    var engine: GameEngine
    
    // Keyboard Mode: false = In-Game Arcade Keyboard (compact), true = Apple Native Keyboard
    @AppStorage("useNativeKeyboard") private var useNativeKeyboard: Bool = false
    
    // Focus state for Apple's Native Keyboard
    @FocusState private var isNativeKeyboardFocused: Bool
    @State private var nativeInputBuffer: String = ""
    
    // Standard iOS Keyboard layout for arcade mode
    private let row1: [Character] = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
    private let row2: [Character] = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
    private let row3: [Character] = ["Z", "X", "C", "V", "B", "N", "M"]
    
    var body: some View {
        VStack(spacing: 4) {
            // 1. Messages Header & Urgency Bar
            if let prompt = engine.activePrompt {
                HStack(spacing: 6) {
                    // Contact Avatar
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 24, height: 24)
                        Image(systemName: prompt.avatarEmoji)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(prompt.contactName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(prompt.incomingText)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Keyboard Mode Toggle
                    Button(action: {
                        useNativeKeyboard.toggle()
                        if useNativeKeyboard {
                            isNativeKeyboardFocused = true
                        } else {
                            isNativeKeyboardFocused = false
                        }
                    }) {
                        HStack(spacing: 2) {
                            Image(systemName: useNativeKeyboard ? "apple.logo" : "gamecontroller.fill")
                                .font(.system(size: 9))
                            Text(useNativeKeyboard ? "Apple" : "Arcade")
                                .font(.system(size: 8, weight: .black))
                        }
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(Color.cyan.opacity(0.2))
                        .cornerRadius(6)
                    }
                    
                    // Urgency Timer Pill
                    HStack(spacing: 3) {
                        Image(systemName: "timer")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(urgencyColor(time: engine.messageTimeRemaining, maxTime: prompt.urgencySeconds))
                        Text(String(format: "%.1fs", max(0, engine.messageTimeRemaining)))
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(urgencyColor(time: engine.messageTimeRemaining, maxTime: prompt.urgencySeconds))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(urgencyColor(time: engine.messageTimeRemaining, maxTime: prompt.urgencySeconds).opacity(0.2))
                    .cornerRadius(6)
                }
                .padding(.horizontal, 8)
                .padding(.top, 2)
                
                // Urgency Progress Bar
                GeometryReader { barGeo in
                    let progress = min(1.0, max(0.0, engine.messageTimeRemaining / prompt.urgencySeconds))
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1)).frame(height: 2.5)
                        Capsule()
                            .fill(urgencyColor(time: engine.messageTimeRemaining, maxTime: prompt.urgencySeconds))
                            .frame(width: barGeo.size.width * CGFloat(progress), height: 2.5)
                    }
                }
                .frame(height: 2.5)
                .padding(.horizontal, 8)
            } else {
                // Idle / Waiting Header
                HStack(spacing: 6) {
                    Image(systemName: "ellipsis.message.fill")
                        .foregroundColor(.cyan)
                        .font(.system(size: 12))
                    Text("Incoming texts will appear here...")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
            }
            
            // 2. Target Text Prompt Box (Monkeytype Engine)
            if let prompt = engine.activePrompt {
                HStack(spacing: 6) {
                    Image(systemName: "pencil.line")
                        .foregroundColor(engine.hasTypingError ? .red : .cyan)
                        .font(.system(size: 10))
                    
                    // Monkeytype Character-by-Character Renderer
                    ScrollView(.horizontal, showsIndicators: false) {
                        MonkeytypePromptText(
                            target: prompt.targetReply,
                            typed: engine.typedText
                        )
                    }
                    
                    Spacer()
                    
                    // Quick Sparkle Auto-type / Auto-fix Assist
                    Button(action: {
                        engine.autoTypeNextChar()
                    }) {
                        Image(systemName: engine.hasTypingError ? "delete.left.fill" : "sparkles")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(engine.hasTypingError ? Color.red.opacity(0.6) : Color.cyan.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.45))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            engine.hasTypingError ? Color.red.opacity(0.8) :
                            (engine.isTextCompleteAndValid ? Color.green.opacity(0.8) : Color.cyan.opacity(0.3)),
                            lineWidth: engine.hasTypingError || engine.isTextCompleteAndValid ? 1.5 : 1.0
                        )
                )
                .offset(
                    x: engine.typingErrorShake > 0 ? CGFloat.random(in: -engine.typingErrorShake * 4...engine.typingErrorShake * 4) : 0
                )
                .padding(.horizontal, 6)
                .onTapGesture {
                    if useNativeKeyboard {
                        isNativeKeyboardFocused = true
                    }
                }
                
                // Native Hidden TextField
                if useNativeKeyboard {
                    TextField("", text: $nativeInputBuffer)
                        .focused($isNativeKeyboardFocused)
                        .autocorrectionDisabled(true)
                        .disableAutocapitalization()
                        .submitLabel(.send)
                        .onSubmit {
                            engine.sendCurrentMessage()
                            nativeInputBuffer = ""
                        }
                        .onChange(of: nativeInputBuffer) { oldValue, newValue in
                            if newValue.count > oldValue.count {
                                if let lastChar = newValue.last {
                                    engine.handleKeyInput(lastChar)
                                }
                            } else if newValue.count < oldValue.count {
                                engine.handleBackspace()
                            }
                        }
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                }
            }
            
            // 3. Compact Keyboard Section
            if !useNativeKeyboard {
                VStack(spacing: 3) {
                    // Row 1: Q W E R T Y U I O P
                    HStack(spacing: 3) {
                        ForEach(row1, id: \.self) { char in
                            KeyButton(
                                char: char,
                                isHighlighted: isNextTarget(char),
                                action: { engine.handleKeyInput(char) }
                            )
                        }
                    }
                    
                    // Row 2: A S D F G H J K L
                    HStack(spacing: 3) {
                        Spacer(minLength: 4)
                        ForEach(row2, id: \.self) { char in
                            KeyButton(
                                char: char,
                                isHighlighted: isNextTarget(char),
                                action: { engine.handleKeyInput(char) }
                            )
                        }
                        Spacer(minLength: 4)
                    }
                    
                    // Row 3: Shift + Z X C V B N M + Delete Key
                    HStack(spacing: 3) {
                        // Left Shift / Caps icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 34, height: 28)
                            Image(systemName: "arrow.up")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        ForEach(row3, id: \.self) { char in
                            KeyButton(
                                char: char,
                                isHighlighted: isNextTarget(char),
                                action: { engine.handleKeyInput(char) }
                            )
                        }
                        
                        // Delete / Backspace Button beside M (Glows Red on Error)
                        Button(action: {
                            engine.handleBackspace()
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(engine.hasTypingError ? Color.red.opacity(0.55) : Color.white.opacity(0.18))
                                    .frame(width: 34, height: 28)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(engine.hasTypingError ? Color.red : Color.clear, lineWidth: 1.5)
                                    )
                                Image(systemName: "delete.backward.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(engine.hasTypingError ? .yellow : .white)
                            }
                            .shadow(color: engine.hasTypingError ? .red.opacity(0.7) : .clear, radius: 4)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Row 4: Dedicated Bottom Row with Long Spacebar & SEND Button
                    HStack(spacing: 4) {
                        // Quick 123 / Sparkle Assist button on bottom left
                        Button(action: {
                            engine.autoTypeNextChar()
                        }) {
                            Text("123")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 38, height: 28)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(5)
                        }
                        
                        // Long Spacebar (Wide button)
                        Button(action: {
                            engine.handleKeyInput(" ")
                        }) {
                            Text("space")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 28)
                                .background(isNextTarget(" ") ? Color.cyan.opacity(0.8) : Color.white.opacity(0.2))
                                .cornerRadius(5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(isNextTarget(" ") ? Color.white : Color.clear, lineWidth: 1.2)
                                )
                                .shadow(color: isNextTarget(" ") ? .cyan.opacity(0.6) : .clear, radius: 4)
                        }
                        
                        // SEND Action Button on bottom right
                        Button(action: {
                            engine.sendCurrentMessage()
                        }) {
                            HStack(spacing: 3) {
                                Text("SEND")
                                    .font(.system(size: 11, weight: .heavy))
                                Image(systemName: engine.isTextCompleteAndValid ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.white)
                            .frame(width: 64, height: 28)
                            .background(
                                engine.isTextCompleteAndValid ? Color.green :
                                (isSendReady ? Color.blue : Color.gray.opacity(0.35))
                            )
                            .cornerRadius(5)
                            .scaleEffect(isSendReady ? 1.05 : 1.0)
                            .animation(.spring(response: 0.2), value: isSendReady)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            } else {
                // Native Keyboard Banner
                HStack(spacing: 6) {
                    Button(action: {
                        isNativeKeyboardFocused = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "keyboard.fill")
                                .foregroundColor(.cyan)
                            Text(isNativeKeyboardFocused ? "Apple Keyboard Active (Type on iOS keyboard)" : "Tap to Open iOS Keyboard")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                    }
                    
                    Button(action: {
                        engine.sendCurrentMessage()
                        nativeInputBuffer = ""
                    }) {
                        Text("SEND")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .frame(height: 28)
                            .background(engine.isTextCompleteAndValid ? Color.green : (isSendReady ? Color.blue : Color.gray.opacity(0.35)))
                            .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 4)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.12))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.18), lineWidth: 1))
                .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
        )
        .padding(.horizontal, 6)
    }
    
    private var isSendReady: Bool {
        return !engine.typedText.isEmpty
    }
    
    private func isNextTarget(_ char: Character) -> Bool {
        guard let prompt = engine.activePrompt else { return false }
        let nextIndex = engine.typedText.count
        guard nextIndex < prompt.targetReply.count else { return false }
        let targetChar = prompt.targetReply[prompt.targetReply.index(prompt.targetReply.startIndex, offsetBy: nextIndex)]
        return String(char).lowercased() == String(targetChar).lowercased()
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

// MARK: - Key Button Component

struct KeyButton: View {
    let char: Character
    let isHighlighted: Bool
    let action: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Text(String(char))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 28)
                .background(
                    isHighlighted ?
                    Color.cyan.opacity(0.85) :
                    Color.white.opacity(0.16)
                )
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isHighlighted ? Color.white : Color.clear, lineWidth: 1.2)
                )
                .shadow(color: isHighlighted ? .cyan.opacity(0.6) : .clear, radius: 3)
                .scaleEffect(isPressed ? 0.90 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
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
