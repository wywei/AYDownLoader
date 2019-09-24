
//
//  AYDownLoader.swift
//  AYDownLoader
//
//  Created by Andy on 2019/3/18.
//  Copyright © 2019 wangyawei. All rights reserved.
//  下载器

import UIKit

var kLocalPath = NSTemporaryDirectory()
let kHeaderFilePath = "headerMsg.plist"
class AYDownLoader: NSObject {

    // 下载链接
    var downLoadURL: URL?

    // 下载进度
    var progress: CGFloat = 0

    // 用于记录是否正在下载
    var isDowning: Bool = false

    // 文件名称
    private var fileFullPath: String?

    // 存储文件总大小
    private var fileTotalSize: Int64 = 0

    // 当前文件已下载大小
    private var fileCurrentSize: Int64 = 0

    // 下载任务
    private var downLoadTask: URLSessionDataTask?

    // 文件输出流
    private var stream: OutputStream?

    // 进度代码块
    private var progressBlock: ((CGFloat) -> Void)?

    // 下载成功的代码块
    private var successBlock: ((String) -> Void)?

    // 下载失败的代码块
    private var failBlock: (() -> Void)?


    func downLoad(url: URL?, progressBlock: ((_ progress: CGFloat) -> Void)?, successBlock: ((_ downLoadPath : String) -> Void)?, failBlock: (() -> Void)?) {

        downLoadURL = url
        self.progressBlock = progressBlock
        self.successBlock = successBlock
        self.failBlock = failBlock

        if self.isDowning {
            print("正在下载....")
            return
        }


        // 1. 获取需要下载的文件头信息
        let result = getRemoteFileMessage()
        if !result {
            print("下载出错，请重新尝试")
            self.failBlock?()
            isDowning = false
            return
        }

        // 2. 根据需要下载的文件头信息，验证本地信息
        // 2.1 如果本地文件存在
        //           进行一下验证:
        //              文件大小 == 服务器文件大小；文件已经存在，不需要处理
        //              文件大小 > 服务器文件大小；删除本地文件，重新下载
        //              文件大小 < 服务器文件大小；根据本地缓存，继续断点下载
        // 2.2 如果文件不存在，则直接下载

        let isRequireDownLoad = checkLocalFile()
        if isRequireDownLoad {
            print("根据文件缓存大小， 执行下载操作")
            startDownLoad()
        } else {
            print("文件已经存在---\(String(describing: self.fileFullPath))")
            self.successBlock?(self.fileFullPath!)
        }

    }

    /// 开始下载
    func startDownLoad() {
        isDowning = true
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)

        guard let url = self.downLoadURL else { return  }
        let request = NSMutableURLRequest(url: url)
        request.setValue(NSString(format: "bytes=%lld-", self.fileCurrentSize) as String, forHTTPHeaderField: "Range")

        self.downLoadTask = session.dataTask(with: request as URLRequest)
        self.downLoadTask?.resume()

        print("down======\(String(describing: self.downLoadTask?.state))")
    }


    /// 暂停下载
    func pauseDownLoad() {
        print("暂停")
        isDowning = false
        self.downLoadTask?.suspend()
        print("pauseDownLoad======\(String(describing: self.downLoadTask?.state))")
    }


    /// 继续下载
    func resumeDownLoad() {
        print("继续")
        isDowning = true
        if self.downLoadTask != nil {
            self.downLoadTask!.resume()
        } else {
            downLoad(url: self.downLoadURL, progressBlock: self.progressBlock, successBlock: self.successBlock, failBlock: self.failBlock)
        }

        print("------\(String(describing: self.downLoadTask?.state))")
    }


    /// 取消下载
    func cancelDownLoad() {

        print("取消")
        isDowning = false
        self.downLoadTask?.cancel()
        print("-----\(String(describing: self.downLoadTask?.state))")
        self.downLoadTask = nil

        try? FileManager.default.removeItem(atPath: self.fileFullPath ?? "")
    }


    /// 获取下载文件的信息
    ///
    /// - Returns: 是否获取成功
    func getRemoteFileMessage() -> Bool {

        // 对信息进行本地缓存， 方便下次使用
        let headerMsgPath = (kLocalPath as NSString).appendingPathComponent(kHeaderFilePath)

        guard let fileName = self.downLoadURL?.lastPathComponent else {
            return false
        }

        var dic = NSMutableDictionary(contentsOfFile: headerMsgPath)
        if dic == nil {
            dic = NSMutableDictionary()
        }

        let containsKey = dic?.allKeys.contains {
            return $0 as? String == fileName
        }

        if let isContains = containsKey, isContains == true  {
            self.fileTotalSize = (dic?[fileName] as? Int64) ?? 0
            self.fileFullPath = (kLocalPath as NSString).appendingPathComponent(fileName)
            return true
        }

        guard let url = self.downLoadURL else {
            return false
        }


        var isCanGet = false
        var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: 30.0)
        request.httpMethod = "HEAD"

        // 使用信号量-同步请求
        let semaphore = DispatchSemaphore(value: 1)
        semaphore.wait()
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error == nil {
                self.fileTotalSize = Int64((response?.expectedContentLength) ?? 0)
                if let suggestedFilename = response?.suggestedFilename {
                    self.fileFullPath = (kLocalPath as NSString).appendingPathComponent(suggestedFilename)
                }
                dic?.setValue(self.fileTotalSize, forKey: fileName)
                dic?.write(toFile: headerMsgPath, atomically: true)
                isCanGet = true
            } else {
                isCanGet = false
            }
            semaphore.signal()
        }
        task.resume()

        semaphore.wait()
        print("--------")
        semaphore.signal()

        return isCanGet
    }

    /// 获取文件大小
   static func cacheFileSize(url: URL) -> Int64 {

        let path = (kLocalPath as NSString).appendingPathComponent(url.lastPathComponent)

    return AYFileTool.getFileSize(filePath: path)
    }

    /// 删除文件
    static func removeCacheFile(url: URL){
        let path = (kLocalPath as NSString).appendingPathComponent(url.lastPathComponent)
        AYFileTool.removeFile(filePath: path)
    }

    /// 检测文件是否需要下载
    func checkLocalFile() -> Bool {
        guard let fullPath = self.fileFullPath else {
            print("路径有问题")
            return false
        }

        self.fileCurrentSize = AYFileTool.getFileSize(filePath: fullPath)

        if self.fileCurrentSize > self.fileTotalSize {
            // 删除文件，并重新下载
            AYFileTool.removeFile(filePath: fullPath)
            return true
        }

        if self.fileCurrentSize < self.fileTotalSize {
            return true
        }

        return false
    }
}


// MARK: -URLSessionDataDelegate, URLSessionTaskDelegate
extension AYDownLoader: URLSessionDataDelegate, URLSessionTaskDelegate {

    /// 当接收到服务器响应时调用
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {

        guard let fullPath = self.fileFullPath  else {
            return
        }
        let stream = OutputStream(toFileAtPath: fullPath, append: true)
        self.stream = stream
        self.stream?.open()
        //通过该block告诉系统要如何处理服务器返回给我们的数据
        /*
         NSURLSessionResponseCancel = 0, //取消,不接受数据
         NSURLSessionResponseAllow = 1, //接收
         NSURLSessionResponseBecomeDownload = 2,  //变成下载请求
         NSURLSessionResponseBecomeStream //变成stream
         */
        completionHandler(URLSession.ResponseDisposition.allow)
    }


    /// 当接收到服务器返回的数据时调用，可能被调用多次
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {

        ///data是结构体  使用[UInt8]构造方法得到data的byte数组
        let bytes = [UInt8](data)
        self.stream?.write(UnsafePointer<UInt8>(bytes), maxLength: bytes.count)
        // 计算文件下载进度
        self.fileCurrentSize = self.fileCurrentSize + Int64(data.count)
        progress =  CGFloat(self.fileCurrentSize) / CGFloat(self.fileTotalSize)

        self.progressBlock?(self.progress)
    }


    /// 当请求结束时调用，如果请求失败，那么error有值
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        print("error=========\(error.debugDescription)")

        self.stream?.close()
        self.stream = nil
        isDowning = false

        if let _ = error {
            self.failBlock?()
        } else {
            if let fullPath = self.fileFullPath {
                self.successBlock?(fullPath)
            }
        }

    }


}
