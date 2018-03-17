//
//  ViewController.swift
//  BigFootWow
//
//  Created by VincentXue on 15/03/2018.
//  Copyright © 2018 VincentXue. All rights reserved.
//

import Cocoa
import SnapKit
import Then

class ViewController: NSViewController {
  private let consoleView = ConsoleView()
  private let pathTextField = NSTextField().then {
    $0.placeholderString = "请选择游戏根目录"
    $0.isEditable = false
    
    if let path = Installer.gameRootPath {
      $0.stringValue = path
    }
  }
  
  private let checkBoxButton = NSButton().then {
    $0.title = "更新前将旧插件目录移动到垃圾桶"
    $0.setButtonType(.switch)
  }
  
  override func loadView() {
    self.view = NSView()
    self.view.frame = Application.shared.windows.first!.frame
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupContents()
  }
  
  private func setupContents() {
    let selectPathButton = NSButton().then {
      $0.title = "选择路径"
      $0.target = self
      $0.action = #selector(selectPathButtonDidClicked)
      $0.bezelStyle = .smallSquare
      $0.focusRingType = .none
      $0.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
    
    let downloadButton = NSButton().then {
      $0.title = "开始更新"
      $0.target = self
      $0.action = #selector(downloadButtonDidClicked)
      $0.bezelStyle = .smallSquare
    }
    
    let stackView = NSStackView(views: [selectPathButton, downloadButton]).then {
      $0.orientation = .vertical
      $0.distribution = .equalSpacing
      $0.alignment = .left
    }
    
    let showAppHomePageButton = NSButton().then {
      $0.title = "项目主页"
      $0.target = self
      $0.action = #selector(showAppHomePage)
      $0.bezelStyle = .smallSquare
    }
    
    
    self.view.addSubview(pathTextField)
    self.view.addSubview(stackView)
    self.view.addSubview(checkBoxButton)
    self.view.addSubview(consoleView)
    self.view.addSubview(showAppHomePageButton)
    
    pathTextField.snp.makeConstraints { (make) in
      make.centerY.equalTo(selectPathButton)
      make.leading.equalTo(selectPathButton.snp.trailing).offset(10)
      make.trailing.equalTo(-20)
    }
    
    stackView.snp.makeConstraints { (make) in
      make.top.leading.equalTo(20)
      make.bottom.equalTo(consoleView.snp.top).offset(-20)
    }
    
    checkBoxButton.snp.makeConstraints { (make) in
      make.leading.equalTo(pathTextField)
      make.centerY.equalTo(downloadButton)
    }
    
    consoleView.snp.makeConstraints { (make) in
      make.leading.equalTo(stackView)
      make.trailing.equalTo(-20)
      make.bottom.equalTo(-30)
    }
    
    showAppHomePageButton.snp.makeConstraints { (make) in
      make.trailing.bottom.equalTo(-5)
    }
    
  }
  
  // MARK: - Actions
  
  @objc private func selectPathButtonDidClicked() {
    let panel = NSOpenPanel().then {
      $0.prompt = "选择"
      $0.showsResizeIndicator = true
      $0.canChooseDirectories = true
      $0.canChooseFiles = false
      $0.allowsMultipleSelection = false
    }
    
    panel.begin(completionHandler: { (result) in
      guard result.rawValue == NSFileHandlingPanelOKButton, panel.urls.isEmpty == false, let path = panel.urls.first?.path else {
        return
      }
      
      self.pathTextField.stringValue = path
      Installer.gameRootPath = path
      self.consoleView.log(message: "您选择的路径是 " + path)
    })
  }
  
  @objc private func downloadButtonDidClicked() {
    guard nil != Installer.gameRootPath else {
      self.consoleView.log(message: "请先选择游戏根目录！", isError: true)
      return
    }
    
    let installer = Installer()
    
    /// 检查已安装版本.
    self.consoleView.log(message: "开始检测当前插件库版本。")
    
    if let currentVersion = installer.currentVersion {
      self.consoleView.log(message: "您当前插件库版本为：\(currentVersion)。")
    } else {
      self.consoleView.log(message: "未检测到当前插件库版本。")
    }
    
    /// 检查新版本
    self.consoleView.log(message: "开始向服务器查询最新插件库版本。")
    
    installer.checkNewVersion { (success, newVersion, message) in
      self.consoleView.log(message: message, isError: !success)
      
      guard success else {
        return
      }
      
      /// 有新版本就开始下载.
      self.consoleView.log(message: "开始下载新版本。")
      
      var previousProgress = 0.0
      installer.download(version: newVersion!, progress: { (progress) in
        if progress.fractionCompleted - previousProgress > 0.1 {
          self.consoleView.log(message: "下载进度：\(String(format: "%.1f%%", progress.fractionCompleted * 100))")
          previousProgress = progress.fractionCompleted
        }
      }, completionHandler: { (success, fileURL, message) in
        self.consoleView.log(message: message, isError: !success)
        
        guard success && nil != fileURL else {
          return
        }
        
        /// 下载完成后解压文件.
        self.consoleView.log(message: "开始解压文件。")
        
        previousProgress = 0.0
        installer.unzip(fileURL: fileURL!, clear: self.checkBoxButton.state == .on, progress: { (progress) in
          if progress - previousProgress > 0.1 {
            self.consoleView.log(message: "解压进度：\(String(format: "%.1f%%", progress * 100))")
            previousProgress = progress
          }
        }, completionHandler: { (success, message) in
          self.consoleView.log(message: message, isError: !success)
          
          if success {
            /// 保存本次更新的版本号以备下一次检查使用.
            installer.currentVersion = newVersion
            self.consoleView.log(message: "更新完成！\n")
          }
        })
      })
    }
  }
  
  @objc private func showAppHomePage() {
    NSWorkspace.shared.open(URL(string: "https://github.com/VincentSit/BigFootWoW")!)
  }
}
