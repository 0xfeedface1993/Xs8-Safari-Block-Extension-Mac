//
//  LogVIew.swift
//  CloudFetchBot
//
//  Created by god on 2019/8/6.
//  Copyright © 2019 ascp. All rights reserved.
//

import SwiftUI

struct LogVIew: View {
    @Binding var items : [LogItem]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(items) { i in
                    Text("\(i.date): \(i.message)").lineLimit(nil).font(.body)
                }
            }
        }
    }
}

#if DEBUG
struct LogVIew_Previews: PreviewProvider {
    static var previews: some View {
        LogVIew(items: .constant(logs))
    }
}
#endif
