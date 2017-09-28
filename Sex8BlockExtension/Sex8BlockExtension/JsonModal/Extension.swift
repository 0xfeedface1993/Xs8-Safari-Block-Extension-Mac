//
//  Extension.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2017/9/28.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Foundation

extension Dictionary {
    func postParams() -> String {
        if let dic = self as? [String:String] {
            var paras = ""
            dic.forEach({ (item) in
                paras += "\(item.key)=\(item.value)&"
            })
            return paras
        }
        return ""
    }
}
