import SwiftUI



struct ContentView: View {
    @State var isModalVideoShowed = false
    
    var body: some View {
        GeometryReader{ geo in
            ZStack{
                Image("imggg")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .frame(width: geo.size.width, height:geo.size.height, alignment: .center)
                    .opacity (1.0)
                    .offset(x:-40)
                Button{
                    isModalVideoShowed.toggle()
                } label: {
                    Image(systemName: "octagon.fill").foregroundStyle(Color.black)
                        .padding(.leading,20)
                    Text("Let's Rock")
                        .foregroundColor(.black)
                        .padding(.trailing, 20)
                        .padding(.vertical, 10)
                }
                .background(.gray)
                .cornerRadius(13.0)
                
                
                .fullScreenCover(isPresented: $isModalVideoShowed, content: {
                    

                    RockPaperScissorsView()
                        .transition(.slide)
                })
            }
        }
    }
}

#Preview {
    ContentView()
}
