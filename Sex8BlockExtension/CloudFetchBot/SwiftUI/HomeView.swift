//
//  HomeView.swift
//  CloudFetchBot
//
//  Created by god on 2019/8/6.
//  Copyright © 2019 ascp. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    @State var state: ActionState = .hange
    @State var isOn: Bool = false {
        willSet {
            if newValue == isOn {
                return
            }
            
            if newValue {
                coodinator.start()
            }   else    {
                coodinator.stop()
            }
        }
    }
    @EnvironmentObject var data: LogData
    
    var body: some View {
        VStack {
            TopView(actionState: state)
            LogVIew(items: data.logs)
            ActionVIew(actionState: $state, isOn: $isOn)
        }.padding()
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
#endif
