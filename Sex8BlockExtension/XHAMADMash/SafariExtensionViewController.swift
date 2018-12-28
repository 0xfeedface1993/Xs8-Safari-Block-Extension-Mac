//
//  SafariExtensionViewController.swift
//  XHAMADMash
//
//  Created by virus1994 on 2018/12/9.
//  Copyright © 2018 ascp. All rights reserved.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width:320, height:240)
        return shared
    }()

}
