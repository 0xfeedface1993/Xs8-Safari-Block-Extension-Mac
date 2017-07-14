//
//  SwiftToaster.swift
//  SwiftToaster
//
//  Created by Meniny on 12/08/16.
//  Copyright © 2016 Meniny. All rights reserved.
//

//#if os(OSX)
//#else
import Foundation
import UIKit

open class SwiftToasterDefault {
    static var message: String = ""
    static var cornerRadius: CGFloat = 10
    static var textColor: UIColor = UIColor.white
    static var backgroundColor: UIColor = UIColor.black
    static var alpha: CGFloat = 1
    static var fadeInTime: TimeInterval = 0.250
    static var fadeOutTime: TimeInterval = 0.250
    static var duration: TimeInterval = 2
}

open class SwiftToaster: NSObject {
    
    // Variables
    fileprivate var message: String = SwiftToasterDefault.message
    fileprivate var cornerRadius: CGFloat = SwiftToasterDefault.cornerRadius
    fileprivate var textColor: UIColor = SwiftToasterDefault.textColor
    fileprivate var backgroundColor: UIColor = SwiftToasterDefault.backgroundColor
    fileprivate var alpha: CGFloat = SwiftToasterDefault.alpha
    open var fadeInTime: TimeInterval = SwiftToasterDefault.fadeInTime
    open var fadeOutTime: TimeInterval = SwiftToasterDefault.fadeOutTime
    open var duration: TimeInterval = SwiftToasterDefault.duration
//    fileprivate var animateFromBottom: Bool = true
    
    // UI Components
    fileprivate var toastView: SwiftToasterView!
    
    // MARK: Initializations
    static let shared = SwiftToaster()
    public override init() {}
    
    public init(_ message: String,
                duration: TimeInterval = SwiftToasterDefault.duration,
                textColor: UIColor = SwiftToasterDefault.textColor,
                backgroundColor: UIColor = SwiftToasterDefault.backgroundColor,
                alpha: CGFloat = SwiftToasterDefault.alpha) {
        self.message = message
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.alpha = alpha
    }
    
    open func show(inView aView: UIView) {
        self.toastView = SwiftToasterView(message: self.message,
                                         textColor: self.textColor,
                                         backgroundColor: self.backgroundColor,
                                         cornerRadius: self.cornerRadius)
        aView.addSubview(self.toastView)
        self.toastView.addConstraint(NSLayoutConstraint(item: self.toastView,
                                                        attribute: .width,
                                                        relatedBy: .lessThanOrEqual,
                                                        toItem: nil,
                                                        attribute: .width,
                                                        multiplier: 1,
                                                        constant: 300))
        aView.addConstraint(NSLayoutConstraint(item: self.toastView,
                                                        attribute: .centerX,
                                                        relatedBy: .equal,
                                                        toItem: aView,
                                                        attribute: .centerX,
                                                        multiplier: 1,
                                                        constant: 0))
        self.toastView.useVFLs(["V:[self]-20-|"])
        self.toastView.alpha = 0
        aView.bringSubview(toFront: self.toastView)
        UIView.animate(withDuration: self.fadeInTime, animations: {
            self.toastView.alpha = self.alpha
        }) { (animateCompleted) in
            self.perform(#selector(self.hide), with: nil, afterDelay: self.duration)
        }
    }
    
    open func show(inController viewController: UIViewController) {
        self.show(inView: viewController.view)
    }
    
    @objc fileprivate func hide() {
        UIView.animate(withDuration: self.fadeOutTime, animations: {
            self.toastView.alpha = 0
        }) { (animationComplete) in
            self.toastView.removeFromSuperview()
        }
    }
}

//  Toast View
fileprivate class SwiftToasterView: UIView {
    fileprivate var toastLabel: UILabel!
    
    // Init
    init(message: String, textColor: UIColor, backgroundColor: UIColor, cornerRadius: CGFloat) {
        super.init(frame:CGRect.zero)
        self.layer.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        
        self.toastLabel = UILabel()
        self.toastLabel.text = message
        self.toastLabel.textColor = textColor
        self.toastLabel.textAlignment = .center
        self.toastLabel.lineBreakMode = .byCharWrapping
        self.toastLabel.numberOfLines = 0
        self.toastLabel.backgroundColor = UIColor.clear
        self.addSubview(self.toastLabel)
        self.toastLabel.useVFLs(["V:|-15-[self]-15-|", "H:|-10-[self]-10-|"])
    }
    
    // Decode
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

// MARK: UIView Extensions
extension UIView {
    // Set Constraints
    public func useVFLs(_ vfls: [String], options opts: NSLayoutFormatOptions = [.alignAllBottom], metrics: [String : Any]? = nil, views: [String: Any]? = nil) {
        self.translatesAutoresizingMaskIntoConstraints = false
        for vfl in vfls {
            let constraints = NSLayoutConstraint.constraints(withVisualFormat: vfl, options: opts , metrics: metrics, views: views == nil ? ["self": self, "super": self.superview!] : views!)
            NSLayoutConstraint.activate(constraints)
        }
    }
    
    public func toast(_ message: String, textColor: UIColor = UIColor.white, backgroundColor: UIColor = UIColor.black, alpha: CGFloat = 1) {
        let t = SwiftToaster(message, textColor: textColor, backgroundColor: backgroundColor, alpha: alpha)
        t.show(inView: self)
    }
}

extension UIViewController {
    public func toast(_ message: String, textColor: UIColor = UIColor.white, backgroundColor: UIColor = UIColor.black, alpha: CGFloat = 1) {
        let t = SwiftToaster(message, textColor: textColor, backgroundColor: backgroundColor, alpha: alpha)
        t.show(inController: self)
    }
}
//#endif
