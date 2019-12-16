//
//  StringArrayTransformer.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2019/12/16.
//  Copyright © 2019 ascp. All rights reserved.
//

import Cocoa

class StringArrayTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let value = value as? Data else { return nil }
        do {
            let items = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(value)
            return items
        } catch {
            print(error)
            return nil
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let value = value as? [String] else { return nil }
        do {
            let items = try NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false)
            return items
        } catch {
            print(error)
            return nil
        }
    }
}
 
