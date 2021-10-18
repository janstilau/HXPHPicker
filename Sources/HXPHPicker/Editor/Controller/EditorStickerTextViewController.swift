//
//  EditorStickerTextViewController.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/22.
//

import UIKit

protocol EditorStickerTextViewControllerDelegate: AnyObject {
    func stickerTextViewController( _ controller: EditorStickerTextViewController,
                                    didFinish stickerText: EditorStickerText )
    func stickerTextViewController( _ controller: EditorStickerTextViewController,
                                    didFinish stickerItem: EditorStickerItem )
}

class EditorStickerTextController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}

class EditorStickerTextViewController: BaseViewController {
    
    weak var delegate: EditorStickerTextViewControllerDelegate?
    
    let config: EditorTextConfig
    let stickerItem: EditorStickerItem?
    
    init(config: EditorTextConfig, stickerItem: EditorStickerItem? = nil) {
        self.config = config
        self.stickerItem = stickerItem
        super.init(nibName: nil, bundle: nil)
    }
    
    /*
        Nav 的唯一的用途, 应该就是这里了,  使用 NavBar, 为两个按钮, 提供了位置.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        navigationController?.view.backgroundColor = .clear
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: finishButton)
        view.addSubview(bgView)
        view.addSubview(textView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.shadowImage = UIImage.image(for: UIColor.clear,
                                                                           havingSize: .zero)
        let clearImg = UIImage.image(for: UIColor.clear, havingSize: .zero )
        navigationController?.navigationBar.setBackgroundImage( clearImg, for: .default)
        navigationController?.navigationBar.barTintColor = .clear
        navigationController?.navigationBar.backgroundColor = .clear
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bgView.frame = view.bounds
        textView.x = 0
        textView.y = navigationController?.navigationBar.frame.maxY ?? UIDevice.navigationBarHeight
        textView.width = view.width
        textView.height = view.height - textView.y
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var finishButton: UIButton = {
        let button = UIButton(type: .system)
        let text = "完成".localized
        button.setTitle(text, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        var textWidth = text.width(ofFont: .systemFont(ofSize: 17), maxHeight: 30)
        if textWidth < 60 {
            textWidth = 60
        }else {
            textWidth += 10
        }
        button.size = CGSize(width: textWidth, height: 30)
        let btnBgImage = UIImage.image( for: config.tintColor, havingSize: button.size, radius: 3)
        button.setBackgroundImage(btnBgImage, for: .normal)
        button.addTarget(self, action: #selector(didFinishButtonClick), for: .touchUpInside)
        return button
    }()
    
    /*
        当完成按钮按下之后, 会根据 TextView 的当前信息, 构建出一个新的 EditorStickerText 出来.
        TextView 内部, 没有将这部分逻辑进行封装. 感觉应该是转移过去.
     */
    @objc func didFinishButtonClick() {
        // 当, Done 按钮点击之后, 会使用 textView 生成一张图片. 这样做的效果, 可以使得添加贴纸表情, 和添加文字图片, 是一个处理逻辑.
        if let image = textView.textImage(),
           !textView.text.isEmpty {
            let stickerText = EditorStickerText(
                image: image,
                text: textView.text,
                textColor: textView.currentSelectedColor,
                showBackgroud: textView.showBgColor
            )
            if stickerItem != nil {
                let stickerItem = EditorStickerItem(image: image, imageData: nil, text: stickerText)
                delegate?.stickerTextViewController(self, didFinish: stickerItem)
            }else {
                delegate?.stickerTextViewController(self, didFinish: stickerText)
            }
        }
        textView.textView.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    lazy var textView: EditorStickerTextView = {
        let view = EditorStickerTextView(config: config, stickerText: stickerItem?.text)
        return view
    }()
    
    // BGView 可以遮盖后面的内容.
    /*
        extraLight 的效果, 整个背景整体泛白
        light 的效果, 虚化浅白
        dark 的效果, 常见的 UI 效果.
        regular 根据黑暗模式变化.
     */
    lazy var bgView: UIVisualEffectView = {
        let effext = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView.init(effect: effext)
        return view
    }()
    
    lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("取消".localized, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.size = CGSize(width: 60, height: 30)
        button.addTarget(self, action: #selector(didCancelButtonClick), for: .touchUpInside)
        return button
    }()
    
    // 取消的话, 什么都不做, 直接进行 dismiss
    @objc func didCancelButtonClick() {
        dismiss(animated: true, completion: nil)
    }
}
