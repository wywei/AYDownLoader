//
//  ViewController.swift
//  AYDownLoader
//
//  Created by Andy on 2019/3/18.
//  Copyright © 2019 wangyawei. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    func demo() {
        let url = URL(string: "https://vipbookedge.sinaedge.com/static/wangdou/font/NotoSerifCJKsc-Regular.otf")
        AYDownLoadManager.shareInstance.downLoad(url: url!, progressBlock: { (progress) in
            print("progress========\(progress)")
        }, successBlock: { (filePath) in
            print("filePath=========\(filePath)")
        }) {
        }
    }

    // 点击屏幕下载
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        demo()
    }

}

