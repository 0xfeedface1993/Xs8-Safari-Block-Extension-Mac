//
//  MainList.swift
//  Sex8BlockExtension
//
//  Created by JohnConner on 2020/2/27.
//  Copyright © 2020 ascp. All rights reserved.
//

import SwiftUI

extension NDMoive: Identifiable {
    
}

struct MainList: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(entity: NDMoive.entity(), sortDescriptors: []) var movies: FetchedResults<NDMoive>
    
    var body: some View {
        VStack {
            List {
                ForEach(movies) { movie in
                    Text(movie.title ?? "无标题").font(.title).lineLimit(3).padding()
                }
            }
        }
    }
}

struct MainList_Previews: PreviewProvider {
    static var previews: some View {
        MainList()
    }
}
