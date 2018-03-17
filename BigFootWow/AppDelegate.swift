//
//  AppDelegate.swift
//  BigFootWow
//
//  Created by VincentXue on 15/03/2018.
//  Copyright © 2018 VincentXue. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  var window: NSWindow!

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let windowSize = CGSize(width: 480, height: 280)
    let screenSize = NSScreen.main!.frame.size
    let screenCenter = NSPoint(x: (screenSize.width - windowSize.width) / 2.0,
                               y: (screenSize.height - windowSize.height) / 2.0)
    window = NSWindow(contentRect: NSRect(origin: screenCenter, size: windowSize),
                      styleMask: [.closable, .miniaturizable, .titled],
                      backing: .buffered,
                      defer: false)
    window.backgroundColor = .white
    window.title = "魔兽大脚 for Mac"
    window.isMovableByWindowBackground = true
    window.makeKeyAndOrderFront(self)

    window.contentViewController = ViewController()
  }
}
