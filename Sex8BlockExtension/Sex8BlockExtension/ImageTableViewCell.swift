//
//  ImageTableViewCell.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2017/7/8.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Cocoa

class ImageTableViewCell: NSTableCellView {
    let playboy = NSImageView()
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
        backgroundStyle = .dark
        
        addSubview(playboy)
        playboy.translatesAutoresizingMaskIntoConstraints = false
        
        let views = ["view":playboy] as [String:Any]
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[view]-|", options: [], metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[view]-|", options: [], metrics: nil, views: views))
    }
    
}
