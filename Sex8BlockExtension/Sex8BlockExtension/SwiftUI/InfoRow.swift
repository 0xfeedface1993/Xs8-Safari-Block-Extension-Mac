//
//  InfoRow.swift
//  Sex8BlockExtension
//
//  Created by JohnConner on 2020/3/1.
//  Copyright © 2020 ascp. All rights reserved.
//

import SwiftUI
import KingfisherSwiftUI

extension NDImage: Identifiable {
    
}

extension Image {
    func loadURL(_ url: URL?, completion: ((NSImage?) -> Void)? = nil) {
        guard let url = url else {
            print(">>> 图片链接为空，不加载数据")
            return
        }
        
        URLSession.shared.downloadTask(with: url) { (fileURL, response, netError) in
            if let netError = netError {
                print(">>> \(netError)")
                completion?(nil)
                return
            }
            
            guard let fileURL = fileURL else {
                print(">>> 本地缓存图片链接为空")
                completion?(nil)
                return
            }
            
            
        }
    }
}

struct InfoRow: View {
    @State var movie : NDMoive
    
    var body: some View {
        VStack {
            HStack {
                Text(movie.title ?? "标题遗失").font(.title).foregroundColor(.primary)
                Text("昨天").font(.subheadline).foregroundColor(.gray)
            }
//            HStack {
//                ForEach(movie.images?.allObjects as? [NDImage] ?? []) { img in
//                    KFImage(source: URL(string: img.))
//                }
//            }
        }
    }
}

struct InfoRow_Previews: PreviewProvider {
    static var previews: some View {
        InfoRow(movie: NDMoive())
    }
}
