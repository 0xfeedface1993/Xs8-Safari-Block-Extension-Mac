//
//  ImageCollectionItem.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2017/6/25.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Cocoa

class ImageCollectionItem: NSCollectionViewItem {
    let maleImageView = NSImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        view.addSubview(maleImageView)
        maleImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let views = ["view":maleImageView] as [String:Any]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: views))
    }
    
}
