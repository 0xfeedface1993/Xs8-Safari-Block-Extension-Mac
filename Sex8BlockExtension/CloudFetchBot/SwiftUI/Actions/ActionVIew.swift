//
//  ActionVIew.swift
//  CloudFetchBot
//
//  Created by god on 2019/8/6.
//  Copyright © 2019 ascp. All rights reserved.
//

import SwiftUI

struct ActionVIew: View {
    @EnvironmentObject var data: LogData
    @GestureState var dragState: Bool = false
    var body: some View {
        let dragTap = DragGesture().onEnded({ value in
            print("\(value)")
        })
        let longTap = LongPressGesture(minimumDuration: 0.5, maximumDistance: 1).sequenced(before: dragTap).updating($dragState) { (value, state, transaction) in
            switch value {
            case .first(true):
                state = true
            case .second(true, _):
                state = true
            default:
                state = false
            }
        }.onChanged { value in
            switch value {
            case .first(true):
                self.data.isOn = !self.data.isOn
            default:
                break
            }
        }
        return ZStack {
            Circle().foregroundColor(dragState || self.data.isOn ? Color("ActiveO2"):Color("DeactiveO2")).shadow(color: Color("ShadowX"), radius: 6)
            Text(!self.data.isOn ? "开始采集":"停止采集").foregroundColor(.white)
        }.gesture(longTap)
    }
}

#if DEBUG
struct ActionVIew_Previews: PreviewProvider {
    static var previews: some View {
        ActionVIew().environmentObject(logData)
    }
}
#endif
