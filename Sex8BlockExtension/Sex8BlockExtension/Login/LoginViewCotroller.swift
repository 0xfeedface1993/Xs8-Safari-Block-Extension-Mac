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
    @IBOutlet weak var userid: NSTextField!
    @IBOutlet weak var password: NSSecureTextField!
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var loginButton: NSButton!
    
    var loginCall : ((LoginResult) -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        progress.isDisplayedWhenStopped = false
        progress.stopAnimation(nil)
    }
    
    @IBAction func forgotPassword(_ sender: Any) {
        toast("敬请期待")
    }
    
    @IBAction func login(_ sender: Any) {
        if userid.stringValue == "" || password.stringValue == "" {
            toast("请填写正确的用户名和密码")
            return
        }
        loginButton.isEnabled = false
        userid.isEnabled = false
        password.isEnabled = false
        
        progress.startAnimation(nil)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
            self.progress.stopAnimation(nil)
            self.loginButton.isEnabled = true
            self.userid.isEnabled = true
            self.password.isEnabled = true
        }
    }
}
