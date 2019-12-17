//
//  HomeView.swift
//  CloudFetchBot
//
//  Created by god on 2019/8/6.
//  Copyright © 2019 ascp. All rights reserved.
//

import SwiftUI

struct HomeView: View, CloudSaver {
    @EnvironmentObject var data: LogData
    @State var downloading = false
    
    var body: some View {
        HStack {
            VStack {
                ActionVIew().environmentObject(self.data).frame(width: 80 * (self.data.isOn ? 1.2:1), height: 80 * (self.data.isOn ? 1.2:1)).offset(y: -12).animation(.spring())
                Button(action: {
                    self.downloading.toggle()
                    if self.downloading {
//                        self.testFetchOp()
                        self.downloadAllRecords()
//                        self.removeAllOPRecords()
//                        self.copyAllOPRecords()
//                        CloudDataBase.share.removeAllOPRecords()
                    }   else    {
                        stopFlag = true
                    }
                }) {
                    Text(downloading ? "停止下载":"下载云端数据库")
                }.frame(width: 100)
                Button(action: {
                    self.copyAllOPRecords()
                }) {
                    Text("复制到云端")
                }.frame(width: 100)
                Button(action: {
                    CloudDataBase.share.removeAllCPRecords()
                    self.removeAllOPRecords()
                }) {
                    Text("删除本地缓存数据库")
                }.frame(width: 100)
            }.padding()
            
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
