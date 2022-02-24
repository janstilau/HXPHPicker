//
//  PhotoEditorContentView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/26.
//

import UIKit
#if canImport(Kingfisher)
import Kingfisher
#endif

protocol PhotoEditorContentViewDelegate: AnyObject {
    func contentView(drawViewBeganDraw contentView: PhotoEditorContentView)
    func contentView(drawViewEndDraw contentView: PhotoEditorContentView)
    func contentView(_ contentView: PhotoEditorContentView, updateStickerText item: EditorStickerItem)
}

class PhotoEditorContentView: UIView {
    
    weak var delegate: PhotoEditorContentViewDelegate?
    
    var itemViewMoveToCenter: ((CGRect) -> Bool)?
    
    var stickerMinScale: ((CGSize) -> CGFloat)?
    
    var stickerMaxScale: ((CGSize) -> CGFloat)?
    
    // 底图面板.
    // 可以看到, 编辑的图片, 是和这几个 View 在一起显示的.
    lazy var imageView: UIImageView = {
        var imageView: UIImageView
#if canImport(Kingfisher)
        imageView = AnimatedImageView.init()
#else
        imageView = UIImageView.init()
#endif
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    var image: UIImage? { imageView.image }
    
    // 当, ZoomScale 发生变化之后, 进行了同步处理.
    var zoomScale: CGFloat = 1 {
        didSet {
            drawView.scale = zoomScale
            mosaicView.scale = zoomScale
            stickerView.scale = zoomScale
        }
    }
    
    // 涂抹面板
    lazy var drawView: PhotoEditorDrawView = {
        let drawView = PhotoEditorDrawView.init(frame: .zero)
        drawView.backgroundColor = UIColor.blue.withAlphaComponent(0.3)
        drawView.delegate = self
        return drawView
    }()
    
    // 马赛克面板
    lazy var mosaicView: PhotoEditorMosaicView = {
        let view = PhotoEditorMosaicView(mosaicConfig: mosaicConfig)
        view.backgroundColor = UIColor.green.withAlphaComponent(0.3)
        view.delegate = self
        return view
    }()
    
    // 贴图面板
    lazy var stickerView: EditorStickerView = {
        let view = EditorStickerView(frame: .zero)
        view.backgroundColor = UIColor.red.withAlphaComponent(0.3)
        view.delegate = self
        return view
    }()
    
    let mosaicConfig: PhotoEditorConfiguration.MosaicConfig
    
    // 从这里看, 这个 View 就是一个盒子.
    init(mosaicConfig: PhotoEditorConfiguration.MosaicConfig) {
        self.mosaicConfig = mosaicConfig
        super.init(frame: .zero)
        addSubview(imageView) // 最底层的显示
        addSubview(mosaicView) // 马赛克视图
        addSubview(drawView) // 涂抹视图
        addSubview(stickerView) // 贴图视图.
    }
    
    func setMosaicOriginalImage(_ image: UIImage?) {
        mosaicView.originalImage = image
    }
    
    func setImage(_ image: UIImage) {
#if canImport(Kingfisher)
        let view = imageView as! AnimatedImageView
        view.image = image
#else
        imageView.image = image
#endif
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 所有的视图, 都紧紧地贴合到自己的父视图.
        imageView.frame = bounds
        drawView.frame = bounds
        mosaicView.frame = bounds
        stickerView.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PhotoEditorContentView: PhotoEditorDrawViewDelegate {
    func drawView(beganDraw drawView: PhotoEditorDrawView) {
        delegate?.contentView(drawViewBeganDraw: self)
    }
    func drawView(endDraw drawView: PhotoEditorDrawView) {
        delegate?.contentView(drawViewEndDraw: self)
    }
}

extension PhotoEditorContentView: EditorStickerViewDelegate {
    
    func stickerView(_ stickerView: EditorStickerView, updateStickerText item: EditorStickerItem) {
        delegate?.contentView(self, updateStickerText: item)
    }
    
    func stickerView(touchBegan stickerView: EditorStickerView) {
        delegate?.contentView(drawViewBeganDraw: self)
    }
    func stickerView(touchEnded stickerView: EditorStickerView) {
        delegate?.contentView(drawViewEndDraw: self)
    }
    func stickerView(_ stickerView: EditorStickerView, moveToCenter rect: CGRect) -> Bool {
        if let moveToCenter = itemViewMoveToCenter?(rect) {
            return moveToCenter
        }
        return false
    }
    
    func stickerView(_ stickerView: EditorStickerView, minScale itemSize: CGSize) -> CGFloat {
        if let minScale = stickerMinScale?(itemSize) {
            return minScale
        }
        return 0.2
    }
    
    func stickerView(_ stickerView: EditorStickerView, maxScale itemSize: CGSize) -> CGFloat {
        if let maxScale = stickerMaxScale?(itemSize) {
            return maxScale
        }
        return 5
    }
}

extension PhotoEditorContentView: PhotoEditorMosaicViewDelegate {
    func mosaicView(_ mosaicView: PhotoEditorMosaicView, splashColor atPoint: CGPoint) -> UIColor? {
        imageView.color(for: atPoint)
    }
    
    func mosaicView(beganDraw mosaicView: PhotoEditorMosaicView) {
        delegate?.contentView(drawViewBeganDraw: self)
    }
    
    func mosaicView(endDraw mosaicView: PhotoEditorMosaicView) {
        delegate?.contentView(drawViewEndDraw: self)
    }
}
