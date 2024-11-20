//
//  Winner.swift
//  RSP
//
//  Created by Aniket Kumar on 29/07/24.
//

import SwiftUI

struct Winner: View {
    @Environment(\.dismiss) var dismiss
    let text: Bool
    var body: some View {
            VStack{
                if text{
                    StyledText(text: "Win", backgroundColor: .green)
                }else{
                    StyledText(text: "Lost", backgroundColor: .red)
                }
                HStack{
                    Button("NewGame"){
                        AppState.shared.gameID = UUID()
                    
                    }.padding()
                        .background(Color.purple,in: RoundedRectangle(cornerRadius: 25))
                        .foregroundStyle(.black)
                        .padding(.leading,20)
                    Spacer()
                    Button("EXIT"){
                        exit(0)
                    }.padding().foregroundStyle(.black)
                        .background(Color.red,in: RoundedRectangle(cornerRadius: 25))
                        .padding(.trailing,20)
                }
              
        }
    }
}
#Preview {
    Winner(text: true)
}

