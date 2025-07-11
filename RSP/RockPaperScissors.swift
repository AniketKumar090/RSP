import SwiftUI
import AVFoundation

struct RockPaperScissorsView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var borderColorManager = BorderColorManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var cpuChoice: String = "❓"
    @State private var emojis = ["✊", "✋", "✌️"]
    @State private var isAnimating = false
    @State private var timer: Timer?
    @State private var resultMessage: String = ""
    @State private var backgroundColor: Color = .clear
    @State private var showInstructions = true
    @State private var isGameStarted = false
    @State private var showWinnerSheet = false
    @State private var playerWon = false
    @State private var myScore: Int = 0
    @State private var cpuScore: Int = 0
    @State private var roundsPlayed: Int = 0
    
    // New countdown states
    @State private var showCountdown = false
    @State private var countdownValue = 3
    @State private var countdownText = "3"
    @State private var countdownTimer: Timer?
    
    // Camera and prediction lock states
    @State private var lockedPrediction: String?
    @State private var roundComplete = false
    
    // Camera display state
    @State private var showCamera = false
    
    var body: some View {
        ZStack {
            // Conditional camera background
            if showCamera {
                FullScreenVideoPreviewView(
                    cameraManager: cameraManager,
                    borderColorManager: borderColorManager
                )
                .ignoresSafeArea()
            }
            
            // Gradient overlay - always visible
            LinearGradient(
                colors: [
                    Color.black.opacity(0.7),
                    Color.purple.opacity(0.4),
                    Color.blue.opacity(0.3),
                    Color.black.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 25) {
                // Header
                headerView
                
                Spacer()
                
                // Game area with all game elements
                gameAreaView
                
                Spacer()
                
                // Game controls
                gameControlsView
            }
            .padding()
        }
        .sheet(isPresented: $showWinnerSheet) {
            WinnerView(playerWon: playerWon) {
                resetGame()
            }
            .presentationDetents([.fraction(0.4)])
            .presentationDragIndicator(.visible)
        }
        .onDisappear {
            // Stop camera when view disappears
            cameraManager.stopSession()
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .padding(8)
            .background(.ultraThinMaterial, in: Circle())
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Round \(roundsPlayed + 1)")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Best of 3")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            
            Spacer()
            
            // Empty space for balance
            Circle()
                .fill(Color.clear)
                .frame(width: 44, height: 44)
        }
    }
    
    private var gameAreaView: some View {
        VStack(spacing: 25) {
            // Hand detection zone indicator
            RoundedRectangle(cornerRadius: 25)
                .stroke(
                    isGameStarted ?
                    Color(borderColorManager.borderColor) :
                    Color.white.opacity(0.5),
                    lineWidth: 3
                )
                .frame(height: 500)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.clear)
                        .opacity(showInstructions || showCountdown ? 0.9 : 0.2)
                )
                .shadow(color: Color(borderColorManager.borderColor).opacity(0.5), radius: 10)
                .overlay(
                    VStack(spacing: 20) {
                        // Show instructions, countdown, or game content
                        if showInstructions || !showCamera {
                            instructionsOverlay
                        }else{
                            countdownOverlay
                        }
                        gameContentOverlay
                    }
                )
                .animation(.easeInOut(duration: 0.3), value: borderColorManager.borderColor)
        }
    }
    
    private var instructionsOverlay: some View {
        VStack(spacing: 15) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 50))
                .foregroundStyle(.white)
            
            Text("Place your hand in this area")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .transition(.opacity.combined(with: .scale))
    }
    
    private var countdownOverlay: some View {
        VStack(spacing: 15) {
            Text(countdownText)
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .scaleEffect(1.2)
                .shadow(color: .white.opacity(0.5), radius: 10)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: countdownText)
            Text("Get Ready!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .transition(.opacity.combined(with: .scale))
    }
    
    private var gameContentOverlay: some View {
        VStack(spacing: 20) {
            scoreView
            
            HStack(spacing: 10) {
                // CPU choice display
                cpuChoiceView
                
                // Player prediction display
                playerPredictionView
            }
            .padding(.horizontal, 12)
        }
    }
    
    private var scoreView: some View {
        HStack(spacing: 40) {
            VStack(spacing: 5) {
                Text("YOU")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                Text("\(myScore)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.cyan)
            }
            
            VStack(spacing: 5) {
                Text("VS")
                    .font(.headline)
                    .foregroundStyle(.white)
                if !resultMessage.isEmpty {
                    Text(resultMessage)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(getResultColor())
                        .transition(.opacity.combined(with: .scale))
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 5) {
                Text("CPU")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                Text("\(cpuScore)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var cpuChoiceView: some View {
        VStack(spacing: 12) {
            Text("CPU's Choice")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
            
            Text(cpuChoice)
                .font(.system(size: 50))
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isAnimating)
                .id(cpuChoice)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var playerPredictionView: some View {
        VStack(spacing: 12) {
            Text("Your Move")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
            
            if let prediction = lockedPrediction ?? (isGameStarted && !roundComplete ? cameraManager.handPrediction : nil) {
                Text(getEmojiForPrediction(prediction))
                    .font(.system(size: 50))
            } else {
                Text("❓")
                    .font(.system(size: 50))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var gameControlsView: some View {
        Button(action: startGame) {
            HStack(spacing: 12) {
                Image(systemName: roundComplete ? "arrow.clockwise" : "play.fill")
                    .font(.title2)
                
                Text(roundComplete ? "Play Again" : "Start Game")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 35)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [.purple, .pink, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .purple.opacity(0.4), radius: 15, x: 0, y: 8)
        }
        .disabled(isAnimating || showCountdown)
        .opacity(isAnimating || showCountdown ? 0.6 : 1.0)
        .scaleEffect(isAnimating || showCountdown ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isAnimating)
        .animation(.easeInOut(duration: 0.2), value: showCountdown)
    }
    
    // MARK: - Game Logic
    private func startGame() {
        // Reset states for new round
        showInstructions = false
        roundComplete = false
        lockedPrediction = nil
        resultMessage = ""
        backgroundColor = .clear
        
        // Show camera feed
        showCamera = true
        
        // Start camera session
        cameraManager.startSession()
        
        // Clear previous hand prediction
        cameraManager.handPrediction = nil
        
        // Start both countdown and game animation together
        startCountdownAndGame()
    }

    private func startCountdownAndGame() {
        showCountdown = true
        isGameStarted = true
        countdownValue = 3
        countdownText = "3"
        
        // Start border color animation immediately
        borderColorManager.startColorAnimation()
        
        // Start CPU animation immediately
        isAnimating = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            if isAnimating {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    cpuChoice = emojis.randomElement() ?? "❓"
                }
            }
        }
        
        // Handle countdown
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownValue >= 0 {
                countdownText = countdownValue == 0 ? "Go!" : "\(countdownValue)"
                countdownValue -= 1
            } else {
                timer.invalidate()
                countdownTimer = nil
                
                // Stop animations after countdown finishes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    stopAnimation()
                }
            }
        }
    }

    private func stopAnimation() {
        showCountdown = false
        isAnimating = false
        timer?.invalidate()
        timer = nil
        borderColorManager.stopColorAnimation()
        
        // Lock the current prediction
        lockedPrediction = cameraManager.handPrediction
        
        // Stop camera session and hide camera feed
        cameraManager.stopSession()
        showCamera = false
        
        // Mark round as complete
        roundComplete = true
        
        // Finalize CPU choice
        cpuChoice = emojis.randomElement() ?? "❓"
        
        // Determine result
        if let prediction = lockedPrediction {
            let result = determineResult(user: prediction, cpu: cpuChoice)
            resultMessage = result
            updateUI(for: result)
            roundsPlayed += 1
            
            // Check for game end
            if myScore >= 2 || cpuScore >= 2 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    playerWon = myScore > cpuScore
                    showWinnerSheet = true
                }
            }
        } else {
            resultMessage = "No hand detected!"
            backgroundColor = .gray
        }
    }
    
    private func determineResult(user: String, cpu: String) -> String {
        let userEmoji = getEmojiForPrediction(user)
        
        if (user == "Paper" && cpu == "✋") ||
           (user == "Scissors" && cpu == "✌️") ||
           (user == "Rock" && cpu == "✊") {
            return "It's a tie!"
        } else if (user == "Rock" && cpu == "✋") ||
                  (user == "Paper" && cpu == "✌️") ||
                  (user == "Scissors" && cpu == "✊") {
            cpuScore += 1
            return "You lose!"
        } else {
            myScore += 1
            return "You win!"
        }
    }
    
    private func updateUI(for result: String) {
        withAnimation(.easeInOut(duration: 0.5)) {
            if result.contains("win") {
                backgroundColor = .green
                borderColorManager.updateBorderColor(to: .systemGreen)
            } else if result.contains("lose") {
                backgroundColor = .red
                borderColorManager.updateBorderColor(to: .systemRed)
            } else {
                backgroundColor = .yellow
                borderColorManager.updateBorderColor(to: .systemYellow)
            }
        }
    }
    
    private func getEmojiForPrediction(_ prediction: String) -> String {
        switch prediction.lowercased() {
        case "rock": return "✊"
        case "paper": return "✋"
        case "scissors": return "✌️"
        default: return "❓"
        }
    }
    
    private func getResultColor() -> Color {
        if resultMessage.contains("win") {
            return .green
        } else if resultMessage.contains("lose") {
            return .red
        } else {
            return .yellow
        }
    }
    
    private func resetGame() {
        myScore = 0
        cpuScore = 0
        roundsPlayed = 0
        isGameStarted = false
        showInstructions = true
        showCountdown = false
        roundComplete = false
        lockedPrediction = nil
        resultMessage = ""
        backgroundColor = .clear
        cpuChoice = "❓"
        showWinnerSheet = false
        
        // Hide camera feed and stop camera session
        showCamera = false
        cameraManager.stopSession()
        
        // Clean up timers
        countdownTimer?.invalidate()
        countdownTimer = nil
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Supporting Views and Styles
struct PrimaryButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 25)
            .padding(.vertical, 12)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct StyledText: View {
    let text: String
    let backgroundColor: Color
    var body: some View {
        Text(text)
            .font(.largeTitle)
            .multilineTextAlignment(.center)
            .fontWeight(.bold)
            .padding()
            .foregroundStyle(backgroundColor)
            .cornerRadius(10)
            .shadow(radius: 10)
    }
}

struct Glow: ViewModifier {
    @State private var throb = false
    func body (content: Content) -> some View {
        ZStack {
            content
                .blur(radius: throb ? 15 : 5)
                .animation(.easeOut(duration: 0.5),value: throb)
                .onAppear {
                    throb.toggle()
                }
            content
        }
    }
}

extension View {
    func glow()-> some View {
        modifier(Glow())
    }
}

extension Color{
    func gradient()-> some View{LinearGradient(colors: [Color(red: 0.34, green: 0.34, blue: 0.89),Color(red: 0.53, green: 0.53, blue: 0.93),Color(red: 0.75, green: 0.75, blue: 0.99)], startPoint: .leading, endPoint: .trailing)
    }
}
