import SwiftUI

struct WinnerView: View {
    let playerWon: Bool
    let onNewGame: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            // Result display
            VStack(spacing: 15) {
                Text(playerWon ? "🎉" : "😢")
                    .font(.system(size: 80))
                
                Text(playerWon ? "You Won!" : "You Lost!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(playerWon ? .green : .red)
                
                Text(playerWon ? "Great job!" : "Better luck next time!")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            
            // Action buttons
            HStack(spacing: 20) {
                Button("New Game") {
                    onNewGame()
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle(color: .blue))
                
                Button("Exit") {
                    exit(0)
                }
                .buttonStyle(PrimaryButtonStyle(color: .red))
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
