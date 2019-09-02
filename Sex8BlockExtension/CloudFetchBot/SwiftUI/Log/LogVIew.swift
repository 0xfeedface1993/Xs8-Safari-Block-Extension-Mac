//
//  LogVIew.swift
//  CloudFetchBot
//
//  Created by god on 2019/8/6.
//  Copyright © 2019 ascp. All rights reserved.
//

import SwiftUI

struct LogVIew: View {
    var items : [LogItem]
    var body: some View {
        List {
            ForEach(self.items) { i in
                HStack(alignment: .top) {
                    Text("[\(i.date.formartYYYYMMDDHHMMSSSSS())]: ").font(.caption).foregroundColor(.gray).opacity(0.6)
                    Text(i.message).lineLimit(nil).font(.caption)
                }.transition(.scaleAndFade)
            }
        }.frame(minWidth: 400)
    }
}

#if DEBUG
struct LogVIew_Previews: PreviewProvider {
    static var previews: some View {
        LogVIew(items: logData.logs)
    }
}
#endif
