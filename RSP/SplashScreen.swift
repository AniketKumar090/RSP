import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @State private var size = 2.0
    @State private var opacity = 0.5
    var body: some View {
        if isActive{
            ContentView()
        }else{
            VStack {
                VStack {
                    Image("imggg")
                        .edgesIgnoringSafeArea(.all)
                        .scaledToFill()
                  }
                        .scaleEffect(size)
                        .opacity(opacity)
                        .onAppear {
                            withAnimation(.easeIn(duration: 1.2)) {
                                self.size = 0.64
                                self.opacity = 1.0
                            }
                        }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline:.now() + 2.0) {
                        withAnimation(.easeOut(duration: 0.5)){
                            self.isActive = true
                        }
                    }
                
            }
        }
    }
}
