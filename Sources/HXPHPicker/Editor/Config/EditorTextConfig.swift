//
//  EditorTextConfig.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/16.
//

import UIKit

/*
    Config 类, 就是 Model 类.
    将, 公用的数据纳入到一个类型里面, 使得使用的地方成员结构清晰.
 */
public class EditorTextConfig {
    
    /// 文本颜色数组
    public lazy var colors: [String] = PhotoTools.defaultColors()
    /// 确定按钮背景颜色、文本光标颜色
    public lazy var tintColor: UIColor = .systemTintColor
    /// 文本字体
    public lazy var font: UIFont = .boldSystemFont(ofSize: 25)
    /// 最大字数限制，0为不限制
    public var maximumLimitTextLength: Int = 0
    /// 文本视图推出样式
    public lazy var modalPresentationStyle: UIModalPresentationStyle = {
        if #available(iOS 13.0, *) {
            return .automatic
        } else {
            return .fullScreen
        }
    }()
    
    public init() { }
}
