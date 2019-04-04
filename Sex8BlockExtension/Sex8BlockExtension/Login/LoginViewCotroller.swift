//
//  LoginViewCotroller.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2017/7/15.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Cocoa
import CryptoSwift

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
        
        let encryptPassword = password.stringValue.sha256().uppercased()
        print(password.stringValue + " &&& " + encryptPassword)
        
        let webservice = Webservice.share
//        let caller = WebserviceCaller<LoginResopnse>(baseURL: WebserviceBaseURL.main, way: WebServiceMethod.post, method: "login", paras: ["account":userid.stringValue, "password":encryptPassword], rawData: nil) { (data, err, severErr) in
//            DispatchQueue.main.async {
//                self.progress.stopAnimation(nil)
//                self.loginButton.isEnabled = true
//                self.userid.isEnabled = true
//                self.password.isEnabled = true
//            }
//            if let e = err {
//                DispatchQueue.main.async {
//                    let alert = NSAlert()
//                    alert.alertStyle = .warning
//                    alert.addButton(withTitle: "OK")
//                    guard e is WebserviceError else {
//                        alert.messageText = e.localizedDescription
//                        alert.beginSheetModal(for: NSApplication.shared.keyWindow!, completionHandler: { (response) in
//                            
//                        })
//                        return
//                    }
//                    
//                    switch e as! WebserviceError {
//                    case .badResponseJson(let message):
//                        alert.messageText = message
//                        break
//                    case .badURL(let message):
//                        alert.messageText = message
//                        break
//                    case .badSendJson(let message):
//                        alert.messageText = message
//                        break
//                    case .emptyResponseData(let message):
//                        alert.messageText = message
//                        break
//                    }
//                    
//                    alert.beginSheetModal(for: NSApplication.shared.keyWindow!, completionHandler: { (response) in
//                        
//                    })
//                }
//                return
//            }
//            if let err = severErr {
//                DispatchQueue.main.async {
//                    let alert = NSAlert()
//                    alert.alertStyle = .warning
//                    alert.addButton(withTitle: "OK")
//                    alert.messageText = "错误码：\(err.code), \(err.info)"
//                    alert.beginSheetModal(for: NSApplication.shared.keyWindow!, completionHandler: { (response) in
//                        
//                    })
//                }
//                return
//            }
//            if let user = data {
//                print("id: \(user.id), name: \(user.name)")
//                DispatchQueue.main.async {
//                    self.view.window?.close()
//                }
//            }
//        }
//        do {
//            try webservice.read(caller: caller)
//        } catch {
//            print(error)
//        }
    }
}
