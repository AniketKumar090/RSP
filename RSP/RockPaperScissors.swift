//
//  RockPaperScissors.swift
//  RSP
//
//  Created by Aniket Kumar on 26/07/24.
//
import SwiftUI

struct RockPaperScissorsView: View {
    @StateObject private var cameramanager = CameraManager()
    @StateObject private var borderColorManager = BorderColorManager()
    @State private var cpuChoice: String = "❓"
    @State private var emojis = ["✊", "✋", "✌️"]
    @State private var isAnimating = false
    @State private var timer: Timer?
    @State private var resultMessage: String = ""
    @State private var score: Int = 0
    @State private var previousScore: Int = 0
    @State private var backgroundColor: Color = .white
    let previewSize = CGSize(width: 300, height: 400)
    @State var onceTapped = false
    @State var isStarted = false
    @State private var showScreen = false
    @State private var resulT = false
    @State private var myScore: Int = 0
    @State private var cpuScore: Int = 0
    
    var body: some View {
        VStack {
            ZStack{
                
                VideoPreviewView(cameraManager: cameramanager,borderColorManager: borderColorManager, previewSize: previewSize)
                    .padding(.leading, 50)
                
                Rectangle()
                    .frame(width: 300, height: 404)
                    .foregroundStyle(LinearGradient(colors: [Color(red: 0.34, green: 0.34, blue: 0.89),Color(red: 0.53, green: 0.53, blue: 0.93),Color(red: 0.75, green: 0.75, blue: 0.99)], startPoint: .leading, endPoint: .trailing))
                    .offset(x:5,y:-10)
                    .opacity(onceTapped ? 0 : 1)
                    .animation(.smooth, value: onceTapped)
                    
                Text(" Place\n  your\n Hand\n  here")
                    .font(.system(size: 25).bold())
                    .foregroundStyle(.black)
                    .opacity(onceTapped ? 0 : 1)
                    .animation(.smooth, value: onceTapped)
                
            }
            HStack{
                Text("\(myScore)")
                StyledText(text: "RSP",backgroundColor: backgroundColor)
                Text("\(cpuScore)")
            }
            HStack{
                Text("CPU's Choice  : ")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text(cpuChoice)
                    .font(.system(size: 50))
                    .padding()
                    .transition(.scale)
                    .id(cpuChoice)
                
            }
            VStack {
                if let prediction = cameramanager.handPrediction, isStarted == true{
                    VStack {
                        Text("\(prediction)")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .opacity(onceTapped ? 1 : 0)
                            .animation(.smooth(duration: 1.0), value: onceTapped)
                        if !resultMessage.isEmpty {
                            Text(resultMessage)
                                .font(.title)
                        }else{
                            Text(" ")
                                .font(.title)
                        }
                    }
                } else {
                    VStack {
                        Text(" ")
                            .font(.largeTitle)
                        Text(" ")
                            .font(.title)
                    }
                }
            }
            HStack{
                Button(action: {
                    borderColorManager.startColorAnimation()
                    startAnimation()
                    cameramanager.handPrediction = " "
                    resultMessage = " "
                    isStarted = true
                    onceTapped = true
                }) {
                    Text(isStarted ? "Again             " : "Start             ")
                        .font(.title2)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
                .glow()
            }
        }
        .background(.ultraThinMaterial)
       
        .sheet(isPresented: $showScreen, content: {
           Winner(text: resulT)
                .presentationDetents([.fraction(0.20)])
        })
    }
    
    func startAnimation() {
        isAnimating = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if self.isAnimating {
                withAnimation {
                    self.cpuChoice = self.emojis.randomElement() ?? "❓"
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.stopAnimation()
            
        }
    }
    
    func stopAnimation() {
        isAnimating = false
        timer?.invalidate()
        timer = nil
        onceTapped = false
        
        if let prediction = cameramanager.handPrediction {
            let result = determineResult(user: prediction, cpu: cpuChoice)
            self.resultMessage = result
            updateBackgroundColor()
            if myScore == 2{
                showScreen = true
                resulT = true
                resetgame()
            }else if cpuScore == 2{
                showScreen = true
                resulT = false
                resetgame()
            }else{}
        }
        
    }
    func resetgame(){
        score = 0
        myScore = 0
        cpuScore = 0
        previousScore = 0
        isStarted = false
    }
    
    func determineResult(user: String, cpu: String) -> String {
        if (user == "Paper" && cpu == "✋") ||
            (user == "Scissors" && cpu == "✌️") ||
            (user == "Rock" && cpu == "✊") {
            previousScore = score
            return "It's a tie!"
        } else if (user == "Rock" && cpu == "✋") ||
                    (user == "Paper" && cpu == "✌️") ||
                    (user == "Scissors" && cpu == "✊") {
            previousScore = score
            score-=1
            cpuScore+=1
            return "You lose!"
        } else {
            previousScore = score
            score+=1
            myScore+=1
            return "You win!"
            
        }
    }
    
    func updateBackgroundColor() {
        if score > previousScore {
            backgroundColor = .green
            borderColorManager.updateBorderColor(to: UIColor.green)
        } else if score < previousScore {
            backgroundColor = .red
            borderColorManager.updateBorderColor(to: UIColor.red)
        } else {
            backgroundColor = .gray
            borderColorManager.updateBorderColor(to: UIColor.gray)
        }
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


struct RockPaperScissorsView_Previews: PreviewProvider {
    static var previews: some View {
        RockPaperScissorsView()
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
