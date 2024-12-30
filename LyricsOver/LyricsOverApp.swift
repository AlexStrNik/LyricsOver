//
//  LyricsOverApp.swift
//  LyricsOver
//
//  Created by Aleksandr Strizhnev on 06.12.2024.
//

import AppKit
import SwiftUI
import Combine
import ApplicationServices

func lyricsObserverCallback(_ observer: AXObserver, _ element: AXUIElement, _ event: CFString, _ refcon: UnsafeMutableRawPointer?) {
    if event == kAXUIElementDestroyedNotification as CFString {
        AXObserverRemoveNotification(observer, element, kAXUIElementDestroyedNotification as CFString)
        
        observeLyrics(
            lyricsObserver: observer,
            refcon: refcon!
        )
        return
    } else if event == kAXValueChangedNotification as CFString {
        calculateCurrentLyrics(refcon: refcon!)
    }
}

func observeLyrics(
    lyricsObserver: AXObserver,
    refcon: UnsafeMutableRawPointer
) {
    let lyricsApp = Unmanaged<LyricsOverApp>.fromOpaque(refcon).takeUnretainedValue()
    guard let lyricsScroll = lyricsApp.lyricsScroll else {
        return
    }

    guard let firstChild = lyricsScroll.children?.first else {
        return
    }
    
    let scrollBar = lyricsScroll.children?.first { $0.role == kAXScrollBarRole }
    guard let scrollBar else {
        return
    }
    
    AXObserverAddNotification(
        lyricsObserver,
        firstChild,
        kAXUIElementDestroyedNotification as CFString,
        refcon
    )
    AXObserverAddNotification(
        lyricsObserver,
        scrollBar,
        kAXValueChangedNotification as CFString,
        refcon
    )
    
    guard let children = lyricsScroll.children else {
        return
    }
    
    let lyrics = children.map { $0.title ?? "" }.reversed().drop(while: \.isEmpty).reversed()
    
    DispatchQueue.main.async {
        lyricsApp.lyricsSubject.send(
            Array(lyrics)
        )
    }
    
    calculateCurrentLyrics(refcon: refcon)
}

func calculateCurrentLyrics(refcon: UnsafeMutableRawPointer) {
    let lyricsApp = Unmanaged<LyricsOverApp>.fromOpaque(refcon).takeUnretainedValue()
    guard let lyricsScroll = lyricsApp.lyricsScroll else {
        return
    }
    guard let children = lyricsScroll.children else {
        return
    }
    
    for (offset, child) in children.enumerated() {
        let childY = child.frame.minY - lyricsScroll.frame.minY
        
        if childY > 50 {
            DispatchQueue.main.async {
                lyricsApp.currentSubject.send(offset)
            }
            
            break
        }
    }
}

class LyricsOverApp: NSObject, NSApplicationDelegate {
    private var applicationsObserver: NSKeyValueObservation?
    private var musicApp: NSRunningApplication?
    
    private var lyricsObserver: AXObserver?
    fileprivate var lyricsScroll: AXUIElement?
    
    private var lyricsWindow: NSWindow?
    
    private var lyricsPublisher: AnyPublisher<[String], Never> {
        lyricsSubject.eraseToAnyPublisher()
    }
    fileprivate let lyricsSubject = PassthroughSubject<[String], Never>()
    
    private var currentPublisher: AnyPublisher<Int, Never> {
        currentSubject.eraseToAnyPublisher()
    }
    fileprivate let currentSubject = PassthroughSubject<Int, Never>()

    private var statusMenu: NSMenu!
    private var statusBarItem: NSStatusItem!
    private var toggleMenuItem: NSMenuItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        requestAccesibility()
        
        lyricsWindow = LyricsWindow(
            rect: CGRect(x: 100, y: 100, width: 300, height: 150)
        )
        lyricsWindow?.contentView = NSHostingView(
            rootView: LyricsOverlay(
                lyricsPublisher: lyricsPublisher,
                currentPublisher: currentPublisher
            )
        )
        lyricsWindow?.orderFrontRegardless()
        
        applicationsObserver = NSWorkspace.shared.observe(
            \.runningApplications,
             options: [.initial]
        ) { (model, change) in
            self.observeApplications()
        }
        
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let statusButton = statusBarItem!.button
        statusButton!.image = NSImage(systemSymbolName: "quote.bubble", accessibilityDescription: "LyricsOver")
        
        toggleMenuItem = NSMenuItem(title: "Movable", action: #selector(toggle), keyEquivalent: "")
        toggleMenuItem.onStateImage = NSImage(systemSymbolName: "checkmark", accessibilityDescription: "LyricsOver")
        toggleMenuItem.state = .off

        let quit = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "")
        
        let restart = NSMenuItem(title: "Restart", action: #selector(restartApp), keyEquivalent: "")
        
        statusMenu = NSMenu()
        
        statusMenu!.addItem(toggleMenuItem)
        statusMenu!.addItem(.separator())
        statusMenu!.addItem(restart)
        statusMenu!.addItem(quit)
        
        statusBarItem!.menu = statusMenu!
    }
    
    func observeApplications() {
        guard let musicApp = NSWorkspace.shared.runningApplications.first (where: {
            $0.bundleIdentifier == "com.apple.Music"
        }) else {
            self.musicApp = nil
            self.lyricsObserver = nil
            return
        }
        
        if self.musicApp == nil {
            self.musicApp = musicApp
            self.connectToAppleMusic(app: musicApp)
        }
    }
    
    @objc func toggle() {
        guard let lyricsWindow else { return }
        
        lyricsWindow.ignoresMouseEvents.toggle()
        lyricsWindow.backgroundColor = lyricsWindow.ignoresMouseEvents ? .clear : .red.withAlphaComponent(0.5)
        if !lyricsWindow.ignoresMouseEvents {
            lyricsWindow.styleMask.update(with: .resizable)
        } else {
            lyricsWindow.styleMask.remove(.resizable)
        }
        
        toggleMenuItem.state = lyricsWindow.ignoresMouseEvents ? .off : .on
    }
        
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc func restartApp() {
        self.musicApp = nil
        self.lyricsObserver = nil
        observeApplications()
    }
    
    func requestAccesibility() {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true
        ]
        AXIsProcessTrustedWithOptions(options)
    }
    
    func connectToAppleMusic(app: NSRunningApplication) {
        print("Connecting to \(app)")
        
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        
        let windowElement = appElement.children?.first { $0.role == kAXWindowRole }
        guard let windowElement else {
            return
        }
        
        let splitGroup = windowElement.children?.first { $0.role == kAXSplitGroupRole }
        guard let splitGroup else {
            return
        }
        
        let lyricsGroupDescription = getLyricsDescription(prefferedLanguage: appElement.prefferedLanguage ?? "en")
        
        let lyricsGroup = splitGroup.children?.first { $0.role == kAXGroupRole && $0.description == lyricsGroupDescription }
        guard let lyricsGroup else {
            return
        }
        self.lyricsScroll = lyricsGroup.children?.first { $0.role == kAXScrollAreaRole }

        let refcon = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
        
        AXObserverCreate(
            app.processIdentifier,
            lyricsObserverCallback,
            &lyricsObserver
        )
        
        guard let lyricsObserver else {
            return
        }
        
        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            AXObserverGetRunLoopSource(lyricsObserver),
            .defaultMode
        );
        
        observeLyrics(
            lyricsObserver: lyricsObserver,
            refcon: refcon
        )
    }
    
    func getLyricsDescription(prefferedLanguage: String) -> String {
        let musicApp = URL(fileURLWithPath: "/System/Applications/Music.app")
        let musicBundle = Bundle(url: musicApp)?.path(forResource: prefferedLanguage, ofType: "lproj")
        
        guard let musicBundle else {
            return "Lyrics"
        }
        
        return NSLocalizedString("xmft2x35ce", bundle: Bundle(path: musicBundle)!, comment: "")
    }
}
