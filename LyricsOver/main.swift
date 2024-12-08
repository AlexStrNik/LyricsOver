//
//  main.swift
//  LyricsOver
//
//  Created by Aleksandr Strizhnev on 06.12.2024.
//

import Foundation
import AppKit

let app = NSApplication.shared
let delegate = LyricsOverApp()

app.delegate = delegate
app.setActivationPolicy(.accessory)

NSClipView.setAnimationDuration()

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
