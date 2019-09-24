
//
//  AYFileTool.swift
//  AYDownLoader
//
//  Created by Andy on 2019/3/19.
//  Copyright © 2019 wangyawei. All rights reserved.
//

import UIKit

class AYFileTool: NSObject {

    /// 获取文件大小
    static func getFileSize(filePath: String) -> Int64 {
        if !FileManager.default.fileExists(atPath: filePath) {
            return 0
        }
        var fileDict = [FileAttributeKey: Any]()
        do {
          fileDict = try FileManager.default.attributesOfItem(atPath: filePath)
        } catch(let error) {
            print("error========\(error.localizedDescription)")
            return 0
        }
        return fileDict[FileAttributeKey.size] as? Int64 ?? 0
    }

    /// 删除文件
    static func removeFile(filePath: String) {
        do {
            try FileManager.default.removeItem(atPath: filePath)
        } catch (let error) {
            print("error========\(error.localizedDescription)")
        }
    }

    /// 转换文件大小
    static func calculateFileSizeInUnit(contentLength: Double) -> CGFloat {
        if contentLength >= pow(1024, 3) {
            return CGFloat(contentLength) / (pow(1024, 3))
        } else if contentLength > pow(1024, 2) {
            return CGFloat(contentLength) / (pow(1024, 2))
        } else if contentLength > 1024 {
            return CGFloat(contentLength) / 1024
        } else {
            return CGFloat(contentLength)
        }
    }

    /// 转换单位
    static func calculateUnit(contentLength: Double) -> String {
        if contentLength >= pow(1024, 3) {
            return "GB"
        } else if contentLength >= pow(1024, 2) {
            return "MB"
        } else if contentLength >= 1024 {
            return "KB"
        } else {
            return "Bytes"
        }
    }

}
