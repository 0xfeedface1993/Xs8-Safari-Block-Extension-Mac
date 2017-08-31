//
//  LoginViewCotroller.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2017/7/15.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Cocoa

struct LoginResult {
    var code : String
    var describle : String
}

class LoginViewCotroller: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func login(callback: ((LoginResult) -> Void)?) -> Void {
        
    }
}
