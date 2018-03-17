//
//  Installer.swift
//  BigFootWow
//
//  Created by VincentXue on 15/03/2018.
//  Copyright © 2018 VincentXue. All rights reserved.
//

import Cocoa
import SwiftSoup
import Alamofire
import Zip

public class Installer {
  public static var gameRootPath: String? {
    get {
      let path = UserDefaults.standard.string(forKey: "defaultGameRootPath")
      
      if nil == path {
        let defaultPath = "/Applications/World of Warcraft"
        var isDirectory = ObjCBool(true)
        let exists = FileManager.default.fileExists(atPath: defaultPath, isDirectory: &isDirectory)
        
        return (exists && isDirectory.boolValue) ? defaultPath : nil
      }
      
      return path
    }
    
    set {
      UserDefaults.standard.set(newValue, forKey: "defaultGameRootPath")
      UserDefaults.standard.synchronize()
    }
  }
  
  private static let addonsPath = "/Interface/AddOns"
  
  private let updatePageURLString = "http://bigfoot.178.com/wow/update.html"
  private let downloadPrefixURLString = "http://wow.bfupdate.178.com/BigFoot/Interface/3.1/Interface."
  private let versionFileName = "BigFootVersion.lock"
  public var currentVersion: String? {
    get {
      guard let gameRootPath = Installer.gameRootPath else {
        return nil
      }
      
      let versionPath = gameRootPath + "/Interface/" + versionFileName
      let fm = FileManager.default
      
      guard fm.fileExists(atPath: versionPath) &&
        fm.isReadableFile(atPath: versionPath) else {
          return nil
      }
      
      do {
        let version = try String(contentsOfFile: versionPath, encoding: .utf8)
        return version
      } catch {
        print(error)
        return nil
      }
    }
    
    set {
      guard let gameRootPath = Installer.gameRootPath else {
        return
      }
      
      let versionPath = gameRootPath + "/Interface/" + versionFileName
      do {
        try newValue?.write(toFile: versionPath, atomically: false, encoding: .utf8)
      } catch {
        print(error)
      }
    }
  }
  
  public func checkNewVersion(_ completionHandler: @escaping (Bool, String?, String) -> Void) {
    Alamofire.request(updatePageURLString).responseString(encoding: .utf8) { (response) in
      guard nil != response.value else {
        completionHandler(false, nil, "服务器响应内容为空。")
        return
      }
      
      do {
        let html = response.value!
        let doc = try SwiftSoup.parse(html)
        let text = try doc.getElementById("0")?.getElementsByClass("tit").text()
        
        guard nil != text else {
          completionHandler(false, nil, "获取最新版本号失败。")
          return
        }
        
        let decimals = Set("0123456789.")
        let newVersion = String(text!.filter{ decimals.contains($0) })
        
        if let currentVersion = self.currentVersion {
          if currentVersion.compare(newVersion, options: .numeric) == .orderedAscending {
            completionHandler(true, newVersion, "新版本号为：\(newVersion)，开始更新。")
          } else {
            completionHandler(false, nil, "获取到的版本号为：\(newVersion)，您当前已经是最新版本。")
          }
        } else {
          completionHandler(true, newVersion, "新版本号为：\(newVersion)，开始更新。")
        }
      } catch {
        completionHandler(false, nil, "解析响应失败，错误为：\(error.localizedDescription)。")
      }
    }
  }
  
  @discardableResult
  public func download(version: String, progress: @escaping Alamofire.Request.ProgressHandler, completionHandler: @escaping (Bool, URL?, String) -> Void) -> DownloadRequest {
    let filename = version + ".zip"
    let url = downloadPrefixURLString + filename
    let destination: DownloadRequest.DownloadFileDestination = { _, _ in
      let documentsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
      let fileURL = documentsURL.appendingPathComponent("BitFoot WoW \(filename)")
      
      return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
    }
    
    return Alamofire.download(url, to: destination)
      .downloadProgress (closure: progress)
      .responseData { response in
        guard nil == response.error, let fileURL = response.destinationURL else {
          completionHandler(false, nil, "下载失败，错误信息：\(response.error?.localizedDescription ?? "")。")
          return
        }
        
        completionHandler(true, fileURL, "下载完成。文件保存路径：\(fileURL.path)。")
    }
  }
  
  public func unzip(fileURL: URL, clear: Bool, progress: @escaping (Double) -> Void, completionHandler: @escaping (Bool, String) -> Void) {
    DispatchQueue.global().async {
      do {
        let destination = Installer.gameRootPath!
        
        if clear {
          let url = URL(fileURLWithPath: destination + Installer.addonsPath, isDirectory: true)
          do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
          } catch {
            completionHandler(false, "清空原插件目录失败, 错误信息：\(error.localizedDescription)。")
          }
        }
        
        try Zip.unzipFile(fileURL,
                          destination: URL(fileURLWithPath: destination),
                          overwrite: true,
                          password: nil,
                          progress: progress)
        
        completionHandler(true, "解压完成，解压路径是：\(destination)。")
      } catch {
        completionHandler(false, "解压失败, 错误信息：\(error.localizedDescription)。")
      }
    }
  }
}
