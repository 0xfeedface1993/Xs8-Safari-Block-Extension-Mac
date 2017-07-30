//
//  SwiftToaster-macOS.swift
//  SwiftToaster
//
//  Created by Meniny on 12/08/16.
//  Copyright © 2016 Meniny. All rights reserved.
//

//#if os(iOS)
//#else
import Cocoa

open class SwiftToasterDefault {
    
    static var message: String = ""
    static var cornerRadius: CGFloat = 10
    static var textColor: NSColor = NSColor.white
    static var backgroundColor: NSColor = NSColor.black
    static var alpha: CGFloat = 1
    static var fadeInTime: TimeInterval = 0.250
    static var fadeOutTime: TimeInterval = 0.250
    static var duration: TimeInterval = 1.25
}

open class SwiftToaster: NSObject {
    
    // Variables
    fileprivate var message: String = SwiftToasterDefault.message
    fileprivate var cornerRadius: CGFloat = SwiftToasterDefault.cornerRadius
    fileprivate var textColor: NSColor = SwiftToasterDefault.textColor
    fileprivate var backgroundColor: NSColor = SwiftToasterDefault.backgroundColor
    fileprivate var alpha: CGFloat = SwiftToasterDefault.alpha
    open var fadeInTime: TimeInterval = SwiftToasterDefault.fadeInTime
    open var fadeOutTime: TimeInterval = SwiftToasterDefault.fadeOutTime
    open var duration: TimeInterval = SwiftToasterDefault.duration
//    fileprivate var animateFromBottom: Bool = true
    
    // NS Components
    fileprivate var toastView: SwiftToasterView!
    
    // MARK: Initializations
    static let shared = SwiftToaster()
    public override init() {}
    
    public init(_ message: String,
                duration: TimeInterval?,
                textColor: NSColor?,
                backgroundColor: NSColor?,
                alpha: CGFloat?) {
//        duration = SwiftToasterDefault.duration
//        textColor = SwiftToasterDefault.textColor,
//        backgroundColor = SwiftToasterDefault.backgroundColor,
//        alpha = SwiftToasterDefault.alpha
        self.message = message
        self.textColor = textColor ?? SwiftToasterDefault.textColor
        self.backgroundColor = backgroundColor ?? SwiftToasterDefault.backgroundColor
        self.alpha = alpha ?? SwiftToasterDefault.alpha
    }
    
    open func show(inView aView: NSView) {
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
        self.toastView.alphaValue = 0
        self.toastView.animator().alphaValue = self.alpha
        self.perform(#selector(self.hide), with: nil, afterDelay: self.duration)
    }
    
    open func show(inController viewController: NSViewController) {
        self.show(inView: viewController.view)
    }
    
    @objc fileprivate func hide() {
        self.toastView.animator().alphaValue = 0
        self.toastView.removeFromSuperview()
    }
}

//  Toast View
fileprivate class SwiftToasterView: NSView {
    fileprivate var toastLabel: NSTextField!
    
    // Init
    init(message: String, textColor: NSColor, backgroundColor: NSColor, cornerRadius: CGFloat) {
        super.init(frame:CGRect.zero)
        self.wantsLayer = true
        self.layer?.cornerRadius = cornerRadius
        self.layer?.backgroundColor = backgroundColor.cgColor
        
        self.toastLabel = NSTextField()
        self.toastLabel.isBordered = false
        self.toastLabel.isEditable = false
        self.toastLabel.drawsBackground = false
        self.toastLabel.stringValue = message
        self.toastLabel.textColor = textColor
        self.toastLabel.alignment = .center
        self.toastLabel.lineBreakMode = .byCharWrapping
//        self.toastLabel.numberOfLines = 0
        self.toastLabel.backgroundColor = NSColor.clear
        self.addSubview(self.toastLabel)
        self.toastLabel.useVFLs(["V:|-15-[self]-15-|", "H:|-10-[self]-10-|"])
    }
    
    // Decode
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

// MARK: NSView Extensions
extension NSView {
    // Set Constraints
    public func useVFLs(_ vfls: [String], options opts: NSLayoutConstraint.FormatOptions = [NSLayoutConstraint.FormatOptions.alignAllBottom], metrics: [String : NSNumber]? = nil, views: [String: Any]? = nil) {
        self.translatesAutoresizingMaskIntoConstraints = false
        for vfl in vfls {
            let constraints = NSLayoutConstraint.constraints(withVisualFormat: vfl, options: opts , metrics: metrics, views: views == nil ? ["self": self, "super": self.superview!] : views!)
            NSLayoutConstraint.activate(constraints)
        }
    }
    
    public func toast(_ message: String, textColor: NSColor = NSColor.white, backgroundColor: NSColor = NSColor.black, alpha: CGFloat = 1) {
        let t = SwiftToaster(message, duration: SwiftToasterDefault.duration, textColor: textColor, backgroundColor: backgroundColor, alpha: alpha)
        t.show(inView: self)
    }
}

extension NSViewController {
    public func toast(_ message: String, textColor: NSColor = NSColor.white, backgroundColor: NSColor = NSColor.black, alpha: CGFloat = 1) {
        let t = SwiftToaster(message, duration: SwiftToasterDefault.duration, textColor: textColor, backgroundColor: backgroundColor, alpha: alpha)
        t.show(inController: self)
    }
}
//#endif
