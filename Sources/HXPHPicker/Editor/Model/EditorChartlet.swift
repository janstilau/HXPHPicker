//
//  EditorChartlet.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/26.
//

import UIKit

public typealias EditorTitleChartletResponse = ([EditorChartlet]) -> Void
public typealias EditorChartletListResponse = (Int, [EditorChartlet]) -> Void

/*
    在使用这个 Model 类的时候, 是按照顺序, 读取相应的值进行使用的.
    这个时候, 这些相应的属性, 就应该是 Optinal 的. 
 */
public struct EditorChartlet {
    
    /// 贴图对应的 UIImage 对象, 视频支持gif
    public let image: UIImage?
    
    public let imageData: Data?
    
#if canImport(Kingfisher)
    /// 贴图对应的 网络地址（视频支持gif)
    public let url: URL?
#endif
    
    public let ext: Any?
    
    public init(image: UIImage?,
                imageData: Data? = nil,
                ext: Any? = nil) {
        self.image = image
        self.imageData = imageData
        self.ext = ext
#if canImport(Kingfisher)
        url = nil
#endif
    }
    
#if canImport(Kingfisher)
    public init(
        url: URL?,
        ext: Any? = nil)
    {
        self.url = url
        self.ext = ext
        image = nil
        imageData = nil
    }
#endif
}

// 这种, canImport 的写法, 要比单独手动进行编译控制, 要方便的太多了.
class EditorChartletTitle {
    /// 标题图标 对应的 UIImage 数据
    let image: UIImage?
    
#if canImport(Kingfisher)
    /// 标题图标 对应的 网络地址
    let url: URL?
#endif
    
    init(image: UIImage?) {
        self.image = image
#if canImport(Kingfisher)
        url = nil
#endif
    }
    
#if canImport(Kingfisher)
    init(url: URL?) {
        self.url = url
        image = nil
    }
#endif
    
    /*
        这个值, 就是为了 View 服务的. 
     */
    var isLoading: Bool = false
    var isSelected: Bool = false
    var chartletList: [EditorChartlet] = []
}
