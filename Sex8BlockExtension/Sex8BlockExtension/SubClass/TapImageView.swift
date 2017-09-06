//
//  TapImageView.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2017/9/6.
//  Copyright © 2017年 ascp. All rights reserved.
//

import AppKit

class TapImageView: NSImageView {
    var tapBlock : ((NSImageView) -> Void)?
    override func mouseDown(with event: NSEvent) {
        guard let block = tapBlock else {
            super.mouseDown(with: event)
            return
        }
        block(self)
    }
}
