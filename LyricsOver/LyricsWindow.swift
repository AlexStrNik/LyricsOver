//
//  LyricsWindow.swift
//  LyricsOver
//
//  Created by Aleksandr Strizhnev on 07.12.2024.
//

import AppKit

extension CGRect {
    var flipped: CGRect {
        let screens = NSScreen.screens
        guard let screenWithWindow = (screens.first {
            NSPointInRect(self.origin, $0.frame)
        }) else {
            return self
        }
        
        return CGRect(
            x: self.minX,
            y: screenWithWindow.frame.height - self.origin.y - self.height,
            width: self.width,
            height: self.height
        )
    }
}

class LyricsWindow: NSPanel {
    public convenience init(rect: CGRect) {
        self.init(
            contentRect: rect.flipped,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        
        self.collectionBehavior = [.stationary, .ignoresCycle, .fullScreenAuxiliary, .canJoinAllSpaces, .canJoinAllApplications]
        self.isOpaque = false
        self.isMovableByWindowBackground = true
        self.hasShadow = false
        self.level = NSWindow.Level(Int(NSWindow.Level.floating.rawValue + 1))
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        
        self.setFrameAutosaveName("LyricsOver")
    }
}
