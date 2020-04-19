//
//  MainView.swift
//  Sex8BlockExtension
//
//  Created by god on 2019/10/7.
//  Copyright © 2019 ascp. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @available(OSX 10.15.0, *)
    @Environment(\.managedObjectContext) var context
    
    var body: some View {
        MainList()
    }
}

struct MainView_Previews: PreviewProvider {
    @available(OSX 10.15.0, *)
    static var previews: some View {
        MainView()
    }
}
