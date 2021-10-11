//
//  ProgressHUD.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/8.
//

import UIKit

extension ProgressHUD {
    enum Mode {
        case indicator
        case image
        case success
    }
}

/*
 各种, HUD 基本都是一个思路.
 自己, BGView 盖住 SuperView.
 然后按照自己的思路, 构建 ContentView 里面的内容.
 ContentView 的大小, 是随着里面的内容变化的.
 */

final class ProgressHUD: UIView {
    private var mode: Mode
    
    private lazy var backgroundView: UIView = {
        let backgroundView = UIView.init()
        backgroundView.layer.cornerRadius = 5
        backgroundView.layer.masksToBounds = true
        backgroundView.alpha = 0
        backgroundView.addSubview(blurEffectView)
        backgroundView.addBorderline(inWidth: 1, color: .red)
        backgroundView.addTip("BGView")
        return backgroundView
    }()
    
    private lazy var blurEffectView: UIVisualEffectView = {
        let effect = UIBlurEffect.init(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: effect)
        return blurEffectView
    }()
    
    private lazy var contentView: UIView = {
        let contentView = UIView.init()
        contentView.addBorderline(inWidth: 1, color: .green)
        contentView.addTip("ContentView")
        return contentView
    }()
    
    private lazy var indicatorView: UIView = {
        /*
         根据 Type 的不同, 创建相应的 View 添加到指示视图里面.
         */
        if indicatorType == .circle {
            let indicatorView = ProgressIndefiniteView(
                frame: CGRect(
                    origin: .zero,
                    size: CGSize(width: 45, height: 45)
                )
            )
            indicatorView.startAnimating()
            indicatorView.addBorderline(inWidth: 1, color: .blue)
            indicatorView.addTip("Indicate")
            return indicatorView
        }else {
            let indicatorView = UIActivityIndicatorView(style: .whiteLarge)
            indicatorView.hidesWhenStopped = true
            indicatorView.startAnimating()
            indicatorView.addBorderline(inWidth: 1, color: .blue)
            indicatorView.addTip("Indicate")
            return indicatorView
        }
    }()
    
    private lazy var textLb: UILabel = {
        let textLb = UILabel.init()
        textLb.textColor = .white
        textLb.textAlignment = .center
        textLb.font = UIFont.systemFont(ofSize: 16)
        textLb.numberOfLines = 0
        textLb.addBorderline(inWidth: 1, color: .purple)
        return textLb
    }()
    
    private lazy var imageView: ProgressImageView = {
        // ProgressImageView 是一个特殊的 View. 里面的显示视图, 都是自己画出来的.
        let imageView = ProgressImageView(
            frame: CGRect(
                x: 0, y: 0,
                width: 60, height: 60
            )
        )
        imageView.addBorderline(inWidth: 1, color: .brown)
        imageView.addTip("ImageView")
        return imageView
    }()
    
    lazy var tickView: ProgressImageView = {
        let tickView = ProgressImageView(
            tickFrame: CGRect(
                x: 0, y: 0,
                width: 80, height: 80
            )
        )
        imageView.addBorderline(inWidth: 1, color: .brown)
        imageView.addTip("TickView")
        return tickView
    }()
    
    /// 加载指示器类型
    let indicatorType: BaseConfiguration.IndicatorType
    
    var text: String?
    var finished: Bool = false
    // 这个逻辑, 应该是和 Toast 学的.
    var showDelayTimer: Timer?
    var hideDelayTimer: Timer?
    
    init(
        addedTo view: UIView,
        mode: Mode,
        indicatorType: BaseConfiguration.IndicatorType = .system
    ) {
        self.indicatorType = indicatorType
        self.mode = mode
        super.init(frame: view.bounds)
        initView()
    }
    
    private func initView() {
        /*
         所有的内容, 都添加到了 BackgroundView 上了
         */
        addSubview(backgroundView)
        contentView.addSubview(textLb)
        /*
         根据, type 的不同, 添加不同的 View 到 Background 上.
         */
        if mode == .indicator {
            contentView.addSubview(indicatorView)
        }else if mode == .image {
            contentView.addSubview(imageView)
        }else if mode == .success {
            contentView.addSubview(tickView)
        }
        backgroundView.addSubview(contentView)
    }
    
    private func showHUD(
        text: String?,
        animated: Bool,
        afterDelay: TimeInterval
    ) {
        self.text = text
        textLb.text = text
        updateFrame()
        if afterDelay > 0 {
            let timer = Timer(
                timeInterval: afterDelay,
                target: self,
                selector: #selector(handleShowTimer(timer:)),
                userInfo: animated,
                repeats: false
            )
            RunLoop.current.add(
                timer,
                forMode: RunLoop.Mode.common
            )
            self.showDelayTimer = timer
        }else {
            showViews(animated: animated)
        }
    }
    
    @objc func handleShowTimer(timer: Timer) {
        showViews(animated: (timer.userInfo != nil))
    }
    
    private func showViews(animated: Bool) {
        if finished {
            return
        }
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.backgroundView.alpha = 1
            }
        }else {
            self.backgroundView.alpha = 1
        }
    }
    
    func hide(
        withAnimated animated: Bool,
        afterDelay: TimeInterval
    ) {
        finished = true
        self.showDelayTimer?.invalidate()
        if afterDelay > 0 {
            let timer = Timer(
                timeInterval: afterDelay,
                target: self,
                selector: #selector(handleHideTimer(timer:)),
                userInfo: animated,
                repeats: false
            )
            RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
            self.hideDelayTimer = timer
        }else {
            hideViews(animated: animated)
        }
    }
    
    @objc func handleHideTimer(timer: Timer) {
        hideViews(animated: (timer.userInfo != nil))
    }
    
    func hideViews(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.backgroundView.alpha = 0
            } completion: { (finished) in
                self.indicatorView._stopAnimating()
                self.removeFromSuperview()
            }
        }else {
            backgroundView.alpha = 0
            removeFromSuperview()
            indicatorView._stopAnimating()
        }
    }
    
    func updateText(text: String) {
        self.text = text
        textLb.text = text
        updateFrame()
    }
    
    /*
     具体的 Location 的逻辑, 都集中到这里.
     */
    private func updateFrame() {
        if text != nil {
            var textWidth = text!.width(ofFont: textLb.font, maxHeight: 15)
            if textWidth < 60 {
                textWidth = 60
            }
            if textWidth > width - 100 {
                textWidth = width - 100
            }
            let height = text!.height(ofFont: textLb.font, maxWidth: textWidth)
            textLb.size = CGSize(width: textWidth, height: height)
        }
        
        var textMaxWidth = textLb.width + 60
        if textMaxWidth < 100 {
            textMaxWidth = 100
        }
        
        let centenrX = textMaxWidth / 2
        textLb.centerX = centenrX
        if mode == .indicator {
            indicatorView.centerX = centenrX
            if text != nil {
                textLb.y = indicatorView.frame.maxY + 10
            }else {
                textLb.y = indicatorView.frame.maxY
            }
        }else if mode == .image {
            imageView.centerX = centenrX
            if text != nil {
                textLb.y = imageView.frame.maxY + 15
            }else {
                textLb.y = imageView.frame.maxY
            }
        }else if mode == .success {
            tickView.centerX = centenrX
            textLb.y = tickView.frame.maxY
        }
        
        /*
         根据 Content 的位置信息, 来计算 Container 的大小.
         */
        contentView.height = textLb.frame.maxY
        contentView.width = textMaxWidth
        if contentView.height + 40 < 100 {
            backgroundView.height = 100
        }else {
            backgroundView.height = contentView.height + 40
        }
        if textMaxWidth < backgroundView.height {
            backgroundView.width = backgroundView.height
        }else {
            backgroundView.width = textMaxWidth
        }
        
        contentView.center = CGPoint(x: backgroundView.width * 0.5, y: backgroundView.height * 0.5)
        backgroundView.center = CGPoint(x: width * 0.5, y: height * 0.5)
        blurEffectView.frame = backgroundView.bounds
    }
    
    /*
     类方法, 就是对于包装实例对象的创建, 和弹出.
     在 Swift 里面, 有默认参数这种形式, 这种 OC 的写法, 其实是越来越少了.
     */
    @discardableResult
    class func showLoading(
        addedTo view: UIView?,
        animated: Bool
    ) -> ProgressHUD? {
        showLoading(
            addedTo: view,
            text: nil,
            animated: animated
        )
    }
    
    @discardableResult
    class func showLoading(
        addedTo view: UIView?,
        afterDelay: TimeInterval,
        animated: Bool
    ) -> ProgressHUD? {
        showLoading(
            addedTo: view,
            text: nil,
            afterDelay: afterDelay,
            animated: animated
        )
    }
    
    @discardableResult
    class func showLoading(addedTo view: UIView?, text: String?, animated: Bool) -> ProgressHUD? {
        showLoading(
            addedTo: view,
            text: text,
            afterDelay: 0,
            animated: animated
        )
    }
    
    /*
     Load 的终点入口.
     */
    @discardableResult
    class func showLoading(
        addedTo view: UIView?,
        text: String?,
        afterDelay: TimeInterval ,
        animated: Bool,
        indicatorType: BaseConfiguration.IndicatorType? = nil
    ) -> ProgressHUD? {
        guard let view = view else { return nil }
        
        let type: BaseConfiguration.IndicatorType
        if let indicatorType = indicatorType {
            type = indicatorType
        }else {
            type = PhotoManager.shared.indicatorType
        }
        
        let progressView = ProgressHUD(
            addedTo: view,
            mode: .indicator,
            indicatorType: type
        )
        
        progressView.showHUD(
            text: text,
            animated: animated,
            afterDelay: afterDelay
        )
        
        progressView.addBorderline(inWidth: 2, color: .yellow)
        view.addSubview(progressView)
        return progressView
    }
    
    class func showWarning(
        addedTo view: UIView?,
        text: String?,
        animated: Bool,
        delayHide: TimeInterval
    ) {
        self.showWarning(
            addedTo: view,
            text: text,
            afterDelay: 0,
            animated: animated
        )
        self.hide(
            forView: view,
            animated: animated,
            afterDelay: delayHide
        )
    }
    
    class func showWarning(
        addedTo view: UIView?,
        text: String?,
        afterDelay: TimeInterval,
        animated: Bool
    ) {
        guard let view = view else { return }
        let progressView = ProgressHUD(
            addedTo: view,
            mode: .image
        )
        progressView.showHUD(
            text: text,
            animated: animated,
            afterDelay: afterDelay
        )
        view.addSubview(progressView)
    }
    
    class func showSuccess(
        addedTo view: UIView?,
        text: String?,
        animated: Bool,
        delayHide: TimeInterval
    ) {
        self.showSuccess(
            addedTo: view,
            text: text,
            afterDelay: 0,
            animated: animated
        )
        self.hide(
            forView: view,
            animated: animated,
            afterDelay: delayHide
        )
    }
    
    class func showSuccess(
        addedTo view: UIView?,
        text: String?,
        afterDelay: TimeInterval,
        animated: Bool
    ) {
        guard let view = view else { return }
        let progressView = ProgressHUD(
            addedTo: view,
            mode: .success
        )
        progressView.showHUD(
            text: text,
            animated: animated,
            afterDelay: afterDelay
        )
        view.addSubview(progressView)
    }
    
    class func hide(
        forView view: UIView?,
        animated: Bool
    ) {
        hide(
            forView: view,
            animated: animated,
            afterDelay: 0
        )
    }
    
    class func hide(
        forView view: UIView?,
        animated: Bool,
        afterDelay: TimeInterval
    ) {
        guard let view = view else { return }
        for subView in view.subviews where
        subView is ProgressHUD {
            (subView as! ProgressHUD).hide(
                withAnimated: animated,
                afterDelay: afterDelay
            )
        }
    }
    
    /*
     ProgressView 是覆盖到 SuperView 上的.
     然后在中间, 显示一个 IndicatorView
     */
    override func layoutSubviews() {
        super.layoutSubviews()
        if !frame.equalTo(superview?.bounds ?? frame) {
            frame = superview?.bounds ?? frame
            updateFrame()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ProgressIndefiniteView: UIView {
    
    lazy var circleLayer: CAShapeLayer = {
        let circleLayer = CAShapeLayer()
        circleLayer.frame = bounds
        circleLayer.contentsScale = UIScreen.main.scale
        circleLayer.strokeColor = UIColor.white.cgColor
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineCap = .round
        circleLayer.lineJoin = .bevel
        circleLayer.lineWidth = lineWidth
        let path = UIBezierPath(
            arcCenter: CGPoint(x: width * 0.5, y: height * 0.5),
            radius: width * 0.5 - lineWidth * 0.5,
            startAngle: -CGFloat.pi * 0.5,
            endAngle: -CGFloat.pi * 0.5 + CGFloat.pi * 4,
            clockwise: true
        )
        circleLayer.path = path.cgPath
        /*
         The layer’s alpha channel determines how much of the layer’s content and background shows through.
         Fully or partially opaque pixels allow the underlying content to show through, but fully transparent pixels block that content.
         The default value of this property is nil. When configuring a mask, remember to set the size and position of the mask layer to ensure it is aligned properly with the layer it masks.
         */
        circleLayer.mask = maskLayer
        return circleLayer
    }()
    
    lazy var maskLayer: CALayer = {
        let maskLayer = CALayer()
        maskLayer.contentsScale = UIScreen.main.scale
        maskLayer.frame = bounds
        let topLayer = CAGradientLayer.init()
        topLayer.frame = CGRect(x: width * 0.5, y: 0, width: width * 0.5, height: height)
        topLayer.colors = [
            UIColor.white.withAlphaComponent(0.8).cgColor,
            UIColor.white.withAlphaComponent(0.4).cgColor
        ]
        
        topLayer.startPoint = CGPoint(x: 0, y: 0)
        topLayer.endPoint = CGPoint(x: 0, y: 1)
        maskLayer.addSublayer(topLayer)
        let bottomLayer = CAGradientLayer.init()
        
        bottomLayer.frame = CGRect(x: 0, y: 0, width: width * 0.5, height: height)
        bottomLayer.colors = [
            UIColor.white.withAlphaComponent(0.4).cgColor,
            UIColor.white.withAlphaComponent(0).cgColor
        ]
        bottomLayer.startPoint = CGPoint(x: 0, y: 1)
        bottomLayer.endPoint = CGPoint(x: 0, y: 0)
        maskLayer.addSublayer(bottomLayer)
        return maskLayer
    }()
    
    var isAnimating: Bool = false
    
    let lineWidth: CGFloat
    
    init(frame: CGRect, lineWidth: CGFloat = 3) {
        self.lineWidth = lineWidth
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
     通过 willMove 可以检测到, View 是否添加到 SuperView 上.
     通过 willMoveToWindow 可以检测到, View 是否可见.
     */
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview != nil {
            layer.addSublayer(circleLayer)
        }else {
            circleLayer.removeFromSuperlayer()
            _stopAnimating()
        }
    }
    
    func startAnimating() {
        if isAnimating { return }
        isAnimating = true
        
        let duration: CFTimeInterval = 2
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * 2
        animation.duration = duration
        animation.repeatCount = MAXFLOAT
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        circleLayer.mask?.add(animation, forKey: nil)
        
        let animationGroup = CAAnimationGroup()
        animationGroup.duration = duration
        animationGroup.repeatCount = MAXFLOAT
        animationGroup.isRemovedOnCompletion = false
        animationGroup.timingFunction = CAMediaTimingFunction(name: .linear)
        
        let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
        strokeStartAnimation.fromValue = 0.015
        strokeStartAnimation.toValue = 0.515
        
        let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.fromValue = 0.485
        strokeEndAnimation.toValue = 0.985
        
        animationGroup.animations = [strokeStartAnimation, strokeEndAnimation]
        circleLayer.add(animationGroup, forKey: nil)
    }
    
    func stopAnimating() {
        if !isAnimating { return }
        
        maskLayer.removeAllAnimations()
        isAnimating = false
    }
}

fileprivate extension UIView {
    
    func _startAnimating() {
        if let indefiniteView = self as? ProgressIndefiniteView {
            indefiniteView.startAnimating()
        }else if let indefiniteView = self as? UIActivityIndicatorView {
            indefiniteView.startAnimating()
        }
    }
    
    func _stopAnimating() {
        if let indefiniteView = self as? ProgressIndefiniteView {
            indefiniteView.stopAnimating()
        }else if let indefiniteView = self as? UIActivityIndicatorView {
            indefiniteView.stopAnimating()
        }
    }
}
