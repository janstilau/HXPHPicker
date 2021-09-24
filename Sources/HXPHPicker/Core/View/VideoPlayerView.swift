//
//  VideoPlayerView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit
import AVKit


/*
    这个 View 子类化, 唯一的目的就是, 外界可以直接操作 View 了.
    而 View 的 Frame 操作, autolayout 操作, 要比 Layer 方便的太多了.
 */
class VideoPlayerView: UIView {
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    lazy var player: AVPlayer = {
        let player = AVPlayer.init()
        return player
    }()
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    var avAsset: AVAsset?
    
    init() {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
