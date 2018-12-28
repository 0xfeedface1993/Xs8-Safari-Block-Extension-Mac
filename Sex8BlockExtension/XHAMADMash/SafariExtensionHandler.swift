//
//  SafariExtensionHandler.swift
//  XHAMADMash
//
//  Created by virus1994 on 2018/12/9.
//  Copyright © 2018 ascp. All rights reserved.
//

import SafariServices

class SafariExtensionHandler: SFSafariExtensionHandler {
    
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        // This method will be called when a content script provided by your extension calls safari.extension.dispatchMessage("message").
        page.getPropertiesWithCompletionHandler { properties in
            NSLog("The extension received a message (\(messageName)) from a script injected into (\(String(describing: properties?.url))) with userInfo (\(userInfo ?? [:]))")
        }
    }
    
    override func toolbarItemClicked(in window: SFSafariWindow) {
        // This method will be called when your toolbar item is clicked.
        NSLog("The extension's toolbar item was clicked")
        window.getActiveTab(completionHandler: {
            tab in
            tab?.getPagesWithCompletionHandler({ pages in
                print(pages?.count ?? 0)
                pages?.forEach({ (page) in
                    page.getPropertiesWithCompletionHandler({
                        info in
                        print(info?.title ?? "xxxxxxx")
                        print(info?.url?.absoluteString ?? "yyyy")
                    })
                    page.dispatchMessageToScript(withName: "", userInfo: ["b":"a"])
                    print("post it!")
                })
            })
//            tab?.getActivePage(completionHandler: {
//                page in
//                page!.dispatchMessageToScript(withName: "", userInfo: ["b":"a"])
//                print("post it!")
//            })
        })
    }
    
    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        // This is called when Safari's state changed in some way that would require the extension's toolbar item to be validated again.
        validationHandler(true, "")
    }
    
    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }

}
