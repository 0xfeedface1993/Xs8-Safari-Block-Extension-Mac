//
//  ActionVIew.swift
//  CloudFetchBot
//
//  Created by god on 2019/8/6.
//  Copyright © 2019 ascp. All rights reserved.
//

import SwiftUI

struct ActionVIew: View {
    @Binding var actionState: ActionState
    var body: some View {
        HStack {
            Button(action: {
                if self.actionState != .running {
                    coodinator.start()
                    self.actionState = .running
                }   else   {
                    coodinator.stop()
                    self.actionState = .stop
                }
            }) {
                Text(actionState != .running ? "开始采集":"停止采集")
            }
        }.padding()
    }
}

#if DEBUG
struct ActionVIew_Previews: PreviewProvider {
    static var previews: some View {
        ActionVIew(actionState: .constant(.hange))
    }
}
#endif
