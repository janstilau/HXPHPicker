//
//  AssetManager+Authorization.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import Photos

public extension AssetManager {
    
    /// 获取当前相册权限状态
    /// - Returns: 权限状态
    static func authorizationStatus() -> PHAuthorizationStatus {
        let status: PHAuthorizationStatus
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            // Fallback on earlier versions
            status = PHPhotoLibrary.authorizationStatus()
        }
        return status
    }
    
    /// 获取相机权限
    /// - Parameter completionHandler: 获取结果
    static func requestCameraAccess(
        completionHandler: @escaping (Bool) -> Void
    ) {
        /*
         This call will not block while the user is being asked for access, allowing the client to continue running.
         Until access has been granted, any AVCaptureDevices for the media type will vend silent audio samples or black video frames.
         The user is only asked for permission the first time the client requests access. Later calls use the permission granted by the user.
         */
        /*
            所以, 其实在没有权限的时候, Capture 还是会有音视频的数据过来的.
            只不过这些数据, 都是一些无效数据.
         */
        AVCaptureDevice.requestAccess( for: .video ) { (granted) in
            DispatchQueue.main.async {
                completionHandler(granted)
            }
        }
    }
    
    /// 当前相机权限状态
    /// - Returns: 权限状态
    static func cameraAuthorizationStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
    }
    
    /// 当前相册权限状态是否是Limited
    static func authorizationStatusIsLimited() -> Bool {
        if #available(iOS 14, *) {
            if authorizationStatus() == .limited {
                return true
            }
        }
        return false
    }
    
    /// 请求获取相册权限
    /// - Parameters:
    ///   - handler: 请求权限完成
    /*
        因为, 这个类叫做 ASSETManager. 所以, requestAuthorization 被当做是了 PHAsset 的权限获取.
     
        Assets contain only metadata. The underlying image or video data for any given asset might not be stored on the local device.
     
        However, depending on how you plan to use this data, you may not need to download all of it.
     
        If you need to populate a collection view with thumbnail images, the Photos framework can manage downloading, generating, and caching thumbnails for each asset.
     */
    static func requestAuthorization(
        with handler: @escaping (PHAuthorizationStatus) -> Void
    ) {
        let status = authorizationStatus()
        if status == PHAuthorizationStatus.notDetermined {
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(
                    for: .readWrite
                ) { (authorizationStatus) in
                    DispatchQueue.main.async {
                        handler(authorizationStatus)
                    }
                }
            } else {
                PHPhotoLibrary.requestAuthorization { (authorizationStatus) in
                    DispatchQueue.main.async {
                        handler(authorizationStatus)
                    }
                }
            }
        }else {
            handler(status)
        }
    }
}
