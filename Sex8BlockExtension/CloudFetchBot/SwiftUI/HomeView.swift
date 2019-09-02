//
//  HomeView.swift
//  CloudFetchBot
//
//  Created by god on 2019/8/6.
//  Copyright © 2019 ascp. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var data: LogData
    
    var body: some View {
        HStack {
            ActionVIew().environmentObject(self.data).frame(width: 80 * (self.data.isOn ? 1.2:1), height: 80 * (self.data.isOn ? 1.2:1)).offset(y: -12).animation(.spring())
            
               VStack {
                    if self.data.isOn {
                        TopView(actionState: self.data.state).padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 14))
                        LogVIew(items: data.logs)
                    }
                }.transition(transition).animation(.spring())
                
        }
        .padding()
    }
    
    var transition: AnyTransition {
        AnyTransition.asymmetric(insertion: AnyTransition.move(edge: .trailing).combined(with: AnyTransition.opacity), removal: AnyTransition.move(edge: .trailing).combined(with: AnyTransition.opacity))
    }
}



#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
#endif
