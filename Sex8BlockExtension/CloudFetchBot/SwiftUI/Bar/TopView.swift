//
//  TopView.swift
//  CloudFetchBot
//
//  Created by god on 2019/8/6.
//  Copyright © 2019 ascp. All rights reserved.
//

import SwiftUI

enum ActionState: String {
    case hange = "无操作"
    case stop = "已停止"
    case running = "采集中"
    case error = "发生错误"
}

struct TopView: View {
    var actionState: ActionState
    var body: some View {
        ZStack(alignment: .center) {
            Rectangle().foregroundColor(Color("Rouge")).cornerRadius(4)
            Text(actionState.rawValue).font(.headline)
        }.frame(height: 44)
    }
}

#if DEBUG
struct TopView_Previews: PreviewProvider {
    static var previews: some View {
        TopView(actionState: .hange)
    }
}
#endif
