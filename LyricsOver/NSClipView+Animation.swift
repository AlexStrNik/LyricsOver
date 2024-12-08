//
//  NSClipView+Animation.swift
//  LyricsOver
//
//  Created by Aleksandr Strizhnev on 09.12.2024.
//

import AppKit

extension NSClipView {
    static func setAnimationDuration() {
        let originalSelector = #selector(NSClipView.scroll(to:))
        let swizzledSelector = #selector(NSClipView.swizzled_scroll(to:))
        
        let originalMethod = class_getInstanceMethod(NSClipView.self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(NSClipView.self, swizzledSelector)
        
        guard let originalMethod, let swizzledMethod else { return }
        
        class_addMethod(
            NSScrollView.self,
            originalSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        )
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    @objc func swizzled_scroll(to newOrigin: NSPoint) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.5
        self.animator().setBoundsOrigin(newOrigin)
        NSAnimationContext.endGrouping()
    }
}
