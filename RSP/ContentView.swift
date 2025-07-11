import SwiftUI

struct ContentView: View {
    @State var isModalVideoShowed = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Animated gradient background
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
                
                // Background image with overlay
                Image("imggg")
                    .resizable()
                    .edgesIgnoringSafeArea(.all)
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .opacity(0.3)
                    
                    
                  
                
                // Main content
                VStack {
                    Spacer()
                    // Title
                    VStack(spacing: 10) {
                        Text("ROCK PAPER")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .cyan, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        
                        Text("SCISSORS")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 5, y: 5)
                    .offset(y: 35)
                    Spacer()
                    // Play button
                    Button {
                        isModalVideoShowed.toggle()
                    } label: {
                        HStack(spacing: 15) {
                            Image(systemName: "play.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                            
                            Text("LET'S PLAY")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .purple.opacity(0.5), radius: 15, x: 0, y: 10)
                    }
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: UUID())
                }
                .frame(maxHeight: .infinity)
                .fullScreenCover(isPresented: $isModalVideoShowed) {
                    RockPaperScissorsView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
            }
        }
    }
}
