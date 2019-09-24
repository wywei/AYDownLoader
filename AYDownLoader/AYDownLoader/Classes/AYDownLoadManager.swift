

//
//  AYDownLoadManager.swift
//  AYDownLoader
//
//  Created by Andy on 2019/3/19.
//  Copyright © 2019 wangyawei. All rights reserved.
//  下载管理器

import UIKit

class AYDownLoadManager: NSObject {
    static let shareInstance = AYDownLoadManager()

    // 存放下载器
    lazy var downLoadDic = [String: AYDownLoader]()

    // 根据key获取下载器
    func loader(url: URL?) -> AYDownLoader? {
        guard let uri = url else {
            return nil
        }
        return self.downLoadDic[uri.lastPathComponent]
    }

    /// 下载方法
    ///
    /// - Parameters:
    ///   - url: 下载链接
    ///   - progressBlock: 下载进度的回调
    ///   - successBlock: 下载成功的回调
    ///   - failBlock: 下载失败的回调
    func downLoad(url: URL, progressBlock: @escaping ((_ progress: CGFloat) -> Void), successBlock: @escaping ((_ fileFullPath: String) -> Void), failBlock: @escaping (() -> Void)) {

        var downLoader = self.loader(url: url)
        if let loader = downLoader {
            loader.resumeDownLoad()
        } else {
            downLoader = AYDownLoader()
            self.downLoadDic[url.lastPathComponent] = downLoader!
            downLoader?.downLoad(url: url, progressBlock: { (progress) in
                progressBlock(progress)
            }, successBlock: { [weak self] (downLoadPath :String) in
                guard let weakSelf = self else { return }
                successBlock(downLoadPath)
                // 移除对象
                weakSelf.downLoadDic.removeValue(forKey: (downLoadPath as NSString).lastPathComponent)
                }, failBlock: {
                    failBlock()
            })
        }
    }


    /// 暂停下载
    ///
    /// - Parameter url: 暂停下载的链接
    func pauseDownLoad(url: URL){
        //  有问题？
        let downloader = loader(url: url)
        downloader?.pauseDownLoad()
    }

    /// 继续下载
    ///
    /// - Parameter url: 继续下载的链接
    func resumeDownLoad(url: URL){
        let downloader = loader(url: url)
        downloader?.resumeDownLoad()
    }

    /// 取消下载
    ///
    /// - Parameter url: 取消下载的链接
    func cancelDownLoad(url: URL) {
        let downLoader = downLoadDic[url.lastPathComponent]
        if let loader = downLoader {
            loader.cancelDownLoad()
        } else {
            AYDownLoader.removeCacheFile(url: url)
        }

    }



}
