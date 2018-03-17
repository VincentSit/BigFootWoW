//
//  Application.swift
//  BigFootWow
//
//  Created by VincentXue on 15/03/2018.
//  Copyright © 2018 VincentXue. All rights reserved.
//

import Cocoa

class Application: NSApplication {
  private let strongDelegate = AppDelegate()
  
  override init() {
    super.init()
    
    self.delegate = strongDelegate
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
