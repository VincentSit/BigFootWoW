//
//  ConsoleView.swift
//  BigFootWow
//
//  Created by VincentXue on 17/03/2018.
//  Copyright © 2018 VincentXue. All rights reserved.
//

import Cocoa

public class ConsoleView: NSView {
  private let textView: NSTextView
  private let scrollView: NSScrollView
  
  
  required public init?(coder decoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init() {
    textView = NSTextView()
    textView.isEditable = false
    
    textView.backgroundColor = NSColor(white: 0.13, alpha: 1.0)
    
    scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.autohidesScrollers = true
    scrollView.documentView = textView
    
    super.init(frame: .zero)
    
    addSubview(scrollView)
  }
  
  public override func layout() {
    super.layout()
    
    self.textView.frame = self.bounds
  }
  
  public override func updateConstraints() {
    scrollView.snp.updateConstraints { (make) in
      make.edges.equalTo(0)
    }
    
    super.updateConstraints()
  }
  
  public func log(message: String, isError: Bool = false) {
    DispatchQueue.main.async {
      let formater = DateFormatter()
      formater.dateFormat = "hh:mm:ss"
      let time = formater.string(from: Date())
      
      let attributes = [NSAttributedStringKey.font: NSFont.systemFont(ofSize: 14.0),
                        NSAttributedStringKey.foregroundColor: isError ? NSColor.red : NSColor(white: 0.9, alpha: 1.0)]
      
      let astring = NSAttributedString(string: "\(time): \(message)\n", attributes: attributes)
      self.textView.textStorage?.append(astring)
      
      guard (self.scrollView.verticalScroller != nil) else {
        return
      }
      
      self.textView.scrollRangeToVisible(NSMakeRange(self.textView.string.count, 0))
    }
  }
}
