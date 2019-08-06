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
    @EnvironmentObject var data: [LogItem] = logs
    
    var body: some View {
        VStack {
            TopView(actionState: state)
            LogVIew(items: data)
            ActionVIew(actionState: state)
        }
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
#endif
