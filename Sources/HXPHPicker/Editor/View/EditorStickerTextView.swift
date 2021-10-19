//
//  EditorStickerTextView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/22.
//

import UIKit

/*
    EditorStickerTextView 里面, 不仅仅只是一个 TextView, 还有着对于 TextView 配置的其他 OptionView.
 */
class EditorStickerTextView: UIView {
    
    let config: EditorTextConfig
    
    var text: String { textView.text }
    
    var currentSelectedIndex: Int = 0 {
        didSet {
            let targetIndexPath = IndexPath(item: currentSelectedIndex, section: 0)
            collectionView.scrollToItem(at: targetIndexPath,
                                        at: .centeredHorizontally,
                                        animated: true)
        }
    }
    
    /*
     这个值, 仅仅是为了确定下面的各个属性值的.
     在初始化的时候, 如果传过来了 initText, 那么根据里面的值, 修改 View 的信息.
     在需要构建 TextModel 的之后, 是根据 View 的各个属性值, 进行新的数据的构建.
     */
    var initialStickerText: EditorStickerText?
    
    var currentSelectedColor: UIColor = .clear
    var typingAttributes: [NSAttributedString.Key: Any] = [:]
    var showBgColor: Bool = false
    var textBgColor: UIColor = .clear
    var textIsDelete: Bool = false
    var textBgLayer: EditorStickerTextLayer? // 背景图层
    var rectArray: [CGRect] = [] // 背景图层的范围.
    var blankWidth: CGFloat = 22
    var layerRadius: CGFloat = 8
    var keyboardFrame: CGRect = .zero // 主要是为了弹起 OptionView
    var maxIndex: Int = 0
    
    init(config: EditorTextConfig, stickerText: EditorStickerText?) {
        self.config = config
        self.initialStickerText = stickerText
        super.init(frame: .zero)
        
        addSubview(textView)
        addSubview(textButton)
        addSubview(collectionView)
        
        setupTextConfig()
        setupStickerText()
        setupTextColors()
        addKeyboardNotificaition()
        
        self.addBorderline(inWidth: 1, color: .purple)
        self.addTip("Input Text View")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /*
        在 Setup 方法里面, 使用 initialStickerText 里面的数据, 配置相关的信息.
     */
    func setupTextConfig() {
        textView.tintColor = config.tintColor
        textView.font = config.font
    }
    
    func setupStickerText() {
        if let text = initialStickerText {
            showBgColor = text.showBackgroud
            textView.text = text.text
            textButton.isSelected = text.showBackgroud
        }
        setupTextAttributes()
    }
    
    func setupTextAttributes() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        let attributes = [NSAttributedString.Key.font: config.font,
                          NSAttributedString.Key.paragraphStyle: paragraphStyle]
        typingAttributes = attributes
        textView.attributedText = NSAttributedString(string: initialStickerText?.text ?? "",
                                                     attributes: attributes)
    }
    
    func setupTextColors() {
        /*
         这里的逻辑有点问题, 不应该使用遍历.
         其实就是两种情况, 如果有 Init 值, 使用 Init 的值, 确定当前的值.
         如果没有, 使用第一分数据.
         */
        for (index, colorHex) in config.colors.enumerated() {
            let color = colorHex.color
            if let text = initialStickerText {
                if color == text.textColor {
                    if text.showBackgroud {
                        if color.isWhite {
                            changeTextColor(color: .black)
                        }else {
                            changeTextColor(color: .white)
                        }
                        textBgColor = color
                    }else {
                        changeTextColor(color: color)
                    }
                    currentSelectedColor = color
                    currentSelectedIndex = index
                    collectionView.selectItem(
                        at: IndexPath(item: currentSelectedIndex, section: 0),
                        animated: true,
                        scrollPosition: .centeredHorizontally
                    )
                }
            }else {
                if index == 0 {
                    changeTextColor(color: color)
                    currentSelectedColor = color
                    currentSelectedIndex = index
                    collectionView.selectItem(
                        at: IndexPath(item: currentSelectedIndex, section: 0),
                        animated: true,
                        scrollPosition: .centeredHorizontally
                    )
                }
            }
        }
        
        if textButton.isSelected {
            drawTextBackgroudColor()
        }
    }
    
    func addKeyboardNotificaition() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillAppearance),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil
        )
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillDismiss),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil
        )
    }
    
    /*
     没有使用 autolayout, 而是在 LayoutSubViews 里面, 使用的 frame 做的绝对布局
     */
    override func layoutSubviews() {
        super.layoutSubviews()
        
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12 + UIDevice.rightMargin)
        
        // 根据了键盘高度, 来定位了 TextBtn 和 Collection 的位置.
        // 这块逻辑, 应该移交到外界, 因为这样就固定了这个 View 必须底部贴边了.
        let toolBarTop = height -
            (keyboardFrame.equalTo(.zero) ? UIDevice.bottomMargin + 50 : 50 + keyboardFrame.height)
        
        textButton.frame = CGRect( x: UIDevice.leftMargin, y: toolBarTop, width: 50, height: 50)
        collectionView.frame = CGRect(
            x: textButton.frame.maxX,
            y: toolBarTop,
            width: width - textButton.width,
            height: 50
        )
        textView.frame = CGRect(x: 10, y: 0, width: width - 20, height: textButton.y)
    }
    
    private lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 5
        flowLayout.itemSize = CGSize(width: 37, height: 37)
        return flowLayout
    }()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.register(PhotoEditorBrushColorViewCell.self, forCellWithReuseIdentifier: "EditorStickerTextViewCellID")
        collectionView.addBorderline(inWidth: 1, color: .white)
        collectionView.addTip("ColllectionView")
        return collectionView
    }()
    
    private lazy var textButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage("hx_editor_photo_text_normal".image, for: .normal)
        button.setImage("hx_editor_photo_text_selected".image, for: .selected)
        button.addTarget(self, action: #selector(didTextButtonClick(button:)), for: .touchUpInside)
        button.addBorderline(inWidth: 1, color: .green)
        button.addTip("TextBtn")
        return button
    }()
    
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.layoutManager.delegate = self
        /*
         The inset of the text container's layout area within the text view's content area.
         这个值, 控制着 Text 和 TextView 之间的 margin 值.
         */
        textView.textContainerInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        textView.becomeFirstResponder()
        textView.addBorderline(inWidth: 1, color: .blue)
        textView.addTip("TextView")
        return textView
    }()
}

extension EditorStickerTextView {
    
    /*
     监听 Keyboard 的弹出, 是为了控制 ToolBar 的位置.
     将所有的布局逻辑, 都放到了一处.
     UIView.animation 的做法, 也可以保证动画的顺利弹出.
     */
    @objc func keyboardWillDismiss(notifi: Notification) {
        guard let info = notifi.userInfo,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
        else { return }
        
        keyboardFrame = .zero
        UIView.animate(withDuration: duration) {
            self.layoutSubviews()
        }
    }
    
    @objc func keyboardWillAppearance(notifi: Notification) {
        guard let info = notifi.userInfo,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let keyboardFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }
        
        self.keyboardFrame = keyboardFrame
        UIView.animate(withDuration: duration) {
            self.layoutSubviews()
        }
    }
    
    @objc func didTextButtonClick(button: UIButton) {
        button.isSelected = !button.isSelected
        showBgColor = button.isSelected
        textBgColor = currentSelectedColor
        if button.isSelected {
            if currentSelectedColor.isWhite {
                changeTextColor(color: .black)
            }else {
                changeTextColor(color: .white)
            }
        }else {
            changeTextColor(color: currentSelectedColor)
        }
    }
}
