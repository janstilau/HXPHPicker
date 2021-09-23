//
//  BaseViewController.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

/*
    基类, 仅仅是提供了公共的对于机器方向改变的监听.
 */
open class BaseViewController: UIViewController {
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationDidChanged(notify:)),
            name: UIApplication.didChangeStatusBarOrientationNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationWillChanged(notify:)),
            name: UIApplication.willChangeStatusBarOrientationNotification,
            object: nil
        )
    }
    
    @objc open func deviceOrientationDidChanged(notify: Notification) {
        
    }
    
    @objc open func deviceOrientationWillChanged(notify: Notification) {
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
