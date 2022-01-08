//
//  PhotoEditorViewController.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit
import Photos

#if canImport(Kingfisher)
import Kingfisher
#endif

open class PhotoEditorViewController: BaseViewController {
    
    public weak var delegate: PhotoEditorViewControllerDelegate?
    
    /*
        这种必传项, 应该在 init 方法内, 进行赋值.
     */
    public let config: PhotoEditorConfiguration
    
    /// 当前编辑的图片
    public private(set) var image: UIImage!
    
    /// 资源类型
    public let sourceType: EditorController.SourceType
    
    /// 当前编辑状态
    public private(set) var state: State = .normal
    
    /// 上一次的编辑结果
    public let editResult: PhotoEditResult?
    
    /// 确认/取消之后自动退出界面
    public var autoBack: Bool = true
    
    var filterHDImage: UIImage?
    var mosaicImage: UIImage?
    var thumbnailImage: UIImage!
    var needRequest: Bool = false
    var requestType: Int = 0
    
    /// 编辑image
    /// - Parameters:
    ///   - image: 对应的 UIImage
    ///   - editResult: 上一次编辑结果
    ///   - config: 编辑配置
    public init( image: UIImage,
                 editResult: PhotoEditResult? = nil,
                 config: PhotoEditorConfiguration ) {
        PhotoManager.shared.appearanceStyle = config.appearanceStyle
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        sourceType = .local
        self.image = image
        self.config = config
        self.editResult = editResult
        super.init(nibName: nil, bundle: nil)
    }
    
    /*
     通过宏, 对于接口进行了控制.
     */
#if HXPICKER_ENABLE_PICKER
    /// 当前编辑的PhotoAsset对象
    public private(set) var photoAsset: PhotoAsset!
    
    /// 编辑 PhotoAsset
    /// - Parameters:
    ///   - photoAsset: 对应数据的 PhotoAsset
    ///   - editResult: 上一次编辑结果
    ///   - config: 编辑配置
    public init(
        photoAsset: PhotoAsset,
        editResult: PhotoEditResult? = nil,
        config: PhotoEditorConfiguration
    ) {
        PhotoManager.shared.appearanceStyle = config.appearanceStyle
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        sourceType = .picker
        requestType = 1
        needRequest = true
        self.config = config
        self.editResult = editResult
        self.photoAsset = photoAsset
        super.init(nibName: nil, bundle: nil)
    }
#endif
    
#if canImport(Kingfisher)
    /// 当前编辑的网络图片地址
    public private(set) var networkImageURL: URL?
    
    /// 编辑网络图片
    /// - Parameters:
    ///   - networkImageURL: 对应的网络地址
    ///   - editResult: 上一次编辑结果
    ///   - config: 编辑配置
    public init( networkImageURL: URL,
                 editResult: PhotoEditResult? = nil,
                 config: PhotoEditorConfiguration ) {
        PhotoManager.shared.appearanceStyle = config.appearanceStyle
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        sourceType = .network
        requestType = 2
        needRequest = true
        self.networkImageURL = networkImageURL
        self.config = config
        self.editResult = editResult
        super.init(nibName: nil, bundle: nil)
    }
#endif
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var topViewIsHidden: Bool = false
    
    var showChartlet: Bool = false
    
    var isFilter = false
    var filterImage: UIImage?
    
    var imageInitializeCompletion = false
    var orientationDidChange: Bool = false
    var imageViewDidChange: Bool = true
    var currentToolOption: EditorToolOptions?
    var toolOptions: EditorToolView.Options = []
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        for options in config.toolView.toolOptions {
            switch options.type {
            case .graffiti:
                toolOptions.insert(.graffiti)
            case .chartlet:
                toolOptions.insert(.chartlet)
            case .text:
                toolOptions.insert(.text)
            case .cropping:
                toolOptions.insert(.cropping)
            case .mosaic:
                toolOptions.insert(.mosaic)
            case .filter:
                toolOptions.insert(.filter)
            case .music:
                toolOptions.insert(.music)
            }
        }
        
        setupViews()
        
        if needRequest {
            if requestType == 1 {
#if HXPICKER_ENABLE_PICKER
                requestImage()
#endif
            }else if requestType == 2 {
#if canImport(Kingfisher)
                requestNetworkImage()
#endif
            }
        }else {
            if !config.fixedCropState {
                localImageHandler()
            }
        }
    }
    open override func deviceOrientationWillChanged(notify: Notification) {
        if showChartlet {
            handleSingleTap()
        }
        photoEditView.undoAllDraw()
        if toolOptions.contains(.graffiti) {
            brushColorView.canUndo = photoEditView.canUndoDraw
        }
        photoEditView.undoAllMosaic()
        if toolOptions.contains(.mosaic) {
            mosaicToolView.canUndo = photoEditView.canUndoMosaic
        }
        photoEditView.undoAllSticker()
        photoEditView.reset(false)
        photoEditView.finishCropping(false)
        if config.fixedCropState {
            return
        }
        state = .normal
        croppingAction()
    }
    open override func deviceOrientationDidChanged(notify: Notification) {
        orientationDidChange = true
        imageViewDidChange = false
    }
    
    func setupViews() {
        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(handleSingleTap))
        singleTap.delegate = self
        view.addGestureRecognizer(singleTap)
        
        view.isExclusiveTouch = true
        view.backgroundColor = .black
        view.clipsToBounds = true
        
        view.addSubview(photoEditView)
        view.addSubview(toolView)
        
        if toolOptions.contains(.cropping) {
            view.addSubview(cropConfirmView)
            view.addSubview(cropToolView)
        }
        
        if config.fixedCropState {
            state = .cropping
            toolView.alpha = 0
            toolView.isHidden = true
            topView.alpha = 0
            topView.isHidden = true
        } else {
            state = config.state
            if toolOptions.contains(.graffiti) {
                view.addSubview(brushColorView)
            }
            if toolOptions.contains(.chartlet) {
                view.addSubview(chartletView)
            }
            if toolOptions.contains(.mosaic) {
                view.addSubview(mosaicToolView)
            }
            if toolOptions.contains(.filter) {
                view.addSubview(filterView)
            }
        }
        
        view.layer.addSublayer(topMaskLayer)
        view.addSubview(topView)
    }
    
    // 在 LayoutSubViews 里面, 对于各个 View, 进行了布局控制.
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // ToolView 的位置确认.
        toolView.frame = CGRect( x: 0,
                                 y: view.height - UIDevice.bottomMargin - 50,
                                 width: view.width,
                                 height: 50 + UIDevice.bottomMargin)
        toolView.reloadContentInset()
        
        // TopView 的位置确定.
        topView.width = view.width
        topView.height = navigationController?.navigationBar.height ?? 44
        let cancelButton = topView.subviews.first
        cancelButton?.x = UIDevice.leftMargin
        if let modalPresentationStyle = navigationController?.modalPresentationStyle,
           UIDevice.isPortrait {
            if modalPresentationStyle == .fullScreen || modalPresentationStyle == .custom {
                topView.y = UIDevice.generalStatusBarHeight
            }
        }else if (modalPresentationStyle == .fullScreen || modalPresentationStyle == .custom) && UIDevice.isPortrait {
            topView.y = UIDevice.generalStatusBarHeight
        }
        topMaskLayer.frame = CGRect(x: 0, y: 0, width: view.width, height: topView.frame.maxY + 10)
        
        // Crop
        let cropToolFrame = CGRect(x: 0, y: cropConfirmView.y - 60, width: view.width, height: 60)
        if toolOptions.contains(.cropping) {
            cropConfirmView.frame = toolView.frame
            cropToolView.frame = cropToolFrame
            cropToolView.updateContentInset()
        }
        if toolOptions.contains(.graffiti) {
            brushColorView.frame = cropToolFrame
        }
        if toolOptions.contains(.mosaic) {
            mosaicToolView.frame = cropToolFrame
        }
        if toolOptions.isSticker {
            setChartletViewFrame()
        }
        if toolOptions.contains(.filter) {
            setFilterViewFrame()
        }
        
        // 没有使用 AutoLyaout, 在这里, 进行了相关 View 的位置的确定.
        if !photoEditView.frame.equalTo(view.bounds) && !photoEditView.frame.isEmpty && !imageViewDidChange {
            photoEditView.frame = view.bounds
            photoEditView.reset(false)
            photoEditView.finishCropping(false)
            orientationDidChange = true
        } else {
            photoEditView.frame = view.bounds
        }
        if !imageInitializeCompletion {
            if !needRequest || image != nil {
                photoEditView.setImage(image)
                if let editedData = editResult?.editedData {
                    photoEditView.setEditedData(editedData: editedData)
                    if toolOptions.contains(.graffiti) {
                        brushColorView.canUndo = photoEditView.canUndoDraw
                    }
                    if toolOptions.contains(.mosaic) {
                        mosaicToolView.canUndo = photoEditView.canUndoMosaic
                    }
                }
                if state == .cropping {
                    photoEditView.startCropping(true)
                    croppingAction()
                }
                imageInitializeCompletion = true
            }
        }
        
        if orientationDidChange {
            photoEditView.orientationDidChange()
            if config.fixedCropState {
                photoEditView.startCropping(false)
            }
            orientationDidChange = false
            imageViewDidChange = true
        }
    }
    
    func setChartletViewFrame() {
        var viewHeight = config.chartlet.viewHeight
        if viewHeight > view.height {
            viewHeight = view.height * 0.6
        }
        if showChartlet {
            chartletView.frame = CGRect(x: 0,
                                        y: view.height - viewHeight - UIDevice.bottomMargin,
                                        width: view.width,
                                        height: viewHeight + UIDevice.bottomMargin)
        } else {
            chartletView.frame = CGRect(x: 0,
                                        y: view.height,
                                        width: view.width,
                                        height: viewHeight + UIDevice.bottomMargin)
        }
    }
    
    func setFilterViewFrame() {
        if isFilter {
            filterView.frame = CGRect(
                x: 0,
                y: view.height - 150 - UIDevice.bottomMargin,
                width: view.width,
                height: 150 + UIDevice.bottomMargin
            )
        }else {
            filterView.frame = CGRect(
                x: 0,
                y: view.height + 10,
                width: view.width,
                height: 150 + UIDevice.bottomMargin
            )
        }
    }
    
    open override var prefersStatusBarHidden: Bool {
        return config.prefersStatusBarHidden
    }
    
    open override var prefersHomeIndicatorAutoHidden: Bool {
        false
    }
    
    open override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        .all
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if navigationController?.topViewController != self &&
            navigationController?.viewControllers.contains(self) == false {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if navigationController?.viewControllers.count == 1 {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }else {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
    
    func setImage(_ image: UIImage) {
        self.image = image
    }
    
    
    lazy var photoEditView: PhotoEditorView = createPhotoEditorView()
    public lazy var cropConfirmView: EditorCropConfirmView = createEditorCropConfirmView()
    public lazy var toolView: EditorToolView = createEditorToolView()
    // TopView, 模拟 NavBar 上面的返回按钮.
    public lazy var topView: UIView = createTopView()
    public lazy var topMaskLayer: CAGradientLayer = createTopMask()
    public lazy var brushColorView: PhotoEditorBrushColorView = createPhotoEditorBrushColorView()
    public lazy var cropToolView: PhotoEditorCropToolView = createPhotoEditorCropToolView()
    lazy var mosaicToolView: PhotoEditorMosaicToolView = createPhotoEditorMosaicToolView()
    lazy var filterView: PhotoEditorFilterView = createPhotoEditorFilterView()
    lazy var chartletView: EditorChartletView = createEditorChartletView()
}

extension PhotoEditorViewController {
    
    @objc func handleSingleTap() {
        if state == .cropping {
            return
        }
        
        photoEditView.deselectedSticker()
        func resetOtherOption() {
            if let option = currentToolOption {
                if option.type == .graffiti {
                    photoEditView.drawEnabled = true
                }else if option.type == .mosaic {
                    photoEditView.mosaicEnabled = true
                }
            }
            showTopView()
        }
        if isFilter {
            isFilter = false
            resetOtherOption()
            hiddenFilterView()
            return
        }
        if showChartlet {
            photoEditView.isEnabled = true
            showChartlet = false
            resetOtherOption()
            hiddenChartletView()
            return
        }
        if topViewIsHidden {
            showTopView()
        }else {
            hidenTopView()
        }
    }
    
    @objc func didBackButtonClick() {
        didBackClick(true)
    }
    
    func didBackClick(_ isCancel: Bool = false) {
        if isCancel {
            delegate?.photoEditorViewController(didCancel: self)
        }
        if autoBack {
            if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            }else {
                dismiss(animated: true, completion: nil)
            }
        }
    }
}

/*
    ToolView 的回调方法.
 */
extension PhotoEditorViewController: EditorToolViewDelegate {
    
    // 完成按钮的回调
    func toolView(didFinishButtonClick toolView: EditorToolView) {
        exportResources()
    }
    
    func toolView(_ toolView: EditorToolView, didSelectItemAt model: EditorToolOptions) {
        switch model.type {
        case .graffiti:
            currentToolOption = nil
            photoEditView.mosaicEnabled = false
            hiddenMosaicToolView()
            photoEditView.drawEnabled = !photoEditView.drawEnabled
            toolView.stretchMask = photoEditView.drawEnabled
            toolView.layoutSubviews()
            if photoEditView.drawEnabled {
                photoEditView.stickerEnabled = false
                showBrushColorView()
                currentToolOption = model
            }else {
                photoEditView.stickerEnabled = true
                hiddenBrushColorView()
            }
        case .chartlet:
            chartletView.firstRequest()
            photoEditView.deselectedSticker()
            photoEditView.drawEnabled = false
            photoEditView.mosaicEnabled = false
            photoEditView.stickerEnabled = false
            photoEditView.isEnabled = false
            showChartlet = true
            hidenTopView()
            showChartletView()
        case .text:
            photoEditView.deselectedSticker()
            let textVC = EditorStickerTextViewController(config: config.text)
            textVC.delegate = self
            let nav = EditorStickerTextController(rootViewController: textVC)
            nav.modalPresentationStyle = config.text.modalPresentationStyle
            present(nav, animated: true, completion: nil)
        case .cropping:
            photoEditView.drawEnabled = false
            photoEditView.mosaicEnabled = false
            photoEditView.stickerEnabled = false
            state = .cropping
            photoEditView.startCropping(true)
            croppingAction()
        case .mosaic:
            currentToolOption = nil
            photoEditView.drawEnabled = false
            hiddenBrushColorView()
            photoEditView.mosaicEnabled = !photoEditView.mosaicEnabled
            toolView.stretchMask = photoEditView.mosaicEnabled
            toolView.layoutSubviews()
            if photoEditView.mosaicEnabled {
                photoEditView.stickerEnabled = false
                showMosaicToolView()
                currentToolOption = model
            }else {
                photoEditView.stickerEnabled = true
                hiddenMosaicToolView()
            }
        case .filter:
            photoEditView.drawEnabled = false
            photoEditView.mosaicEnabled = false
            photoEditView.stickerEnabled = false
            isFilter = true
            hidenTopView()
            showFilterView()
        default:
            break
        }
    }
}

/*
 BrushColorView 的代理方法, 当 BrushView 上面的按钮被点击之后, 触发相应的回调. 
 */
extension PhotoEditorViewController: PhotoEditorBrushColorViewDelegate {
    
    func brushColorView(didUndoButton colorView: PhotoEditorBrushColorView) {
        photoEditView.undoDraw()
        brushColorView.canUndo = photoEditView.canUndoDraw
    }
    func brushColorView(_ colorView: PhotoEditorBrushColorView, changedColor colorHex: String) {
        photoEditView.drawColorHex = colorHex
    }
}

// MARK: EditorCropConfirmViewDelegate
extension PhotoEditorViewController: EditorCropConfirmViewDelegate {
    /// 点击完成按钮
    /// - Parameter cropConfirmView: 裁剪视图
    func cropConfirmView(didFinishButtonClick cropConfirmView: EditorCropConfirmView) {
        if config.fixedCropState {
            photoEditView.imageResizerView.finishCropping(false, completion: nil, updateCrop: false)
            exportResources()
            return
        }
        state = .normal
        photoEditView.finishCropping(true)
        croppingAction()
    }
    
    /// 点击还原按钮
    /// - Parameter cropConfirmView: 裁剪视图
    func cropConfirmView(didResetButtonClick cropConfirmView: EditorCropConfirmView) {
        cropConfirmView.resetButton.isEnabled = false
        photoEditView.reset(true)
        cropToolView.reset(animated: true)
    }
    
    /// 点击取消按钮
    /// - Parameter cropConfirmView: 裁剪视图
    func cropConfirmView(didCancelButtonClick cropConfirmView: EditorCropConfirmView) {
        if config.fixedCropState {
            didBackClick(true)
            return
        }
        state = .normal
        photoEditView.cancelCropping(true)
        croppingAction()
    }
}

// MARK: PhotoEditorViewDelegate
extension PhotoEditorViewController: PhotoEditorViewDelegate {
    func checkResetButton() {
        cropConfirmView.resetButton.isEnabled = photoEditView.canReset()
    }
    func editorView(willBeginEditing editorView: PhotoEditorView) {
    }
    
    func editorView(didEndEditing editorView: PhotoEditorView) {
        checkResetButton()
    }
    
    func editorView(willAppearCrop editorView: PhotoEditorView) {
        cropToolView.reset(animated: false)
        cropConfirmView.resetButton.isEnabled = false
    }
    
    func editorView(didAppear editorView: PhotoEditorView) {
        checkResetButton()
    }
    
    func editorView(willDisappearCrop editorView: PhotoEditorView) {
    }
    
    func editorView(didDisappearCrop editorView: PhotoEditorView) {
    }
    
    func editorView(drawViewBeganDraw editorView: PhotoEditorView) {
        hidenTopView()
    }
    
    func editorView(drawViewEndDraw editorView: PhotoEditorView) {
        showTopView()
        brushColorView.canUndo = editorView.canUndoDraw
        mosaicToolView.canUndo = editorView.canUndoMosaic
    }
    func editorView(_ editorView: PhotoEditorView, updateStickerText item: EditorStickerItem) {
        let textVC = EditorStickerTextViewController(config: config.text,
                                                     stickerItem: item)
        textVC.delegate = self
        let nav = EditorStickerTextController(rootViewController: textVC)
        nav.modalPresentationStyle = config.text.modalPresentationStyle
        present(nav, animated: true, completion: nil)
    }
}

extension PhotoEditorViewController: PhotoEditorCropToolViewDelegate {
    func cropToolView(didRotateButtonClick cropToolView: PhotoEditorCropToolView) {
        photoEditView.rotate()
    }
    
    func cropToolView(didMirrorHorizontallyButtonClick cropToolView: PhotoEditorCropToolView) {
        photoEditView.mirrorHorizontally(animated: true)
    }
    
    func cropToolView(didChangedAspectRatio cropToolView: PhotoEditorCropToolView, at model: PhotoEditorCropToolModel) {
        photoEditView.changedAspectRatio(of: CGSize(width: model.widthRatio, height: model.heightRatio))
    }
}
extension PhotoEditorViewController: PhotoEditorMosaicToolViewDelegate {
    func mosaicToolView(
        _ mosaicToolView: PhotoEditorMosaicToolView,
        didChangedMosaicType type: PhotoEditorMosaicView.MosaicType
    ) {
        photoEditView.mosaicType = type
    }
    
    func mosaicToolView(didUndoClick mosaicToolView: PhotoEditorMosaicToolView) {
        photoEditView.undoMosaic()
        mosaicToolView.canUndo = photoEditView.canUndoMosaic
    }
}
extension PhotoEditorViewController: PhotoEditorFilterViewDelegate {
    
    func filterView(shouldSelectFilter filterView: PhotoEditorFilterView) -> Bool {
        true
    }
    
    func filterView(
        _ filterView: PhotoEditorFilterView,
        didSelected filter: PhotoEditorFilter,
        atItem: Int
    ) {
        if filter.isOriginal {
            photoEditView.imageResizerView.filter = nil
            photoEditView.updateImage(image)
            photoEditView.setMosaicOriginalImage(mosaicImage)
            return
        }
        photoEditView.imageResizerView.filter = filter
        ProgressHUD.showLoading(addedTo: view, animated: true)
        let value = filterView.sliderView.value
        let lastImage = photoEditView.image
        DispatchQueue.global().async {
            let filterInfo = self.config.filter.infos[atItem]
            if let newImage = filterInfo.filterHandler(self.thumbnailImage, lastImage, value, .touchUpInside) {
                let mosaicImage = newImage.mosaicImage(level: self.config.mosaic.mosaicWidth)
                DispatchQueue.main.sync {
                    ProgressHUD.hide(forView: self.view, animated: true)
                    self.photoEditView.updateImage(newImage)
                    self.photoEditView.imageResizerView.filterValue = value
                    self.photoEditView.setMosaicOriginalImage(mosaicImage)
                }
            }else {
                DispatchQueue.main.sync {
                    ProgressHUD.hide(forView: self.view, animated: true)
                    ProgressHUD.showWarning(addedTo: self.view, text: "设置失败!".localized, animated: true, delayHide: 1.5)
                }
            }
        }
    }
    func filterView(_ filterView: PhotoEditorFilterView,
                    didChanged value: Float) {
        let filterInfo = config.filter.infos[filterView.currentSelectedIndex - 1]
        if let newImage = filterInfo.filterHandler(thumbnailImage, photoEditView.image, value, .valueChanged) {
            photoEditView.updateImage(newImage)
            photoEditView.imageResizerView.filterValue = value
            if mosaicToolView.canUndo {
                let mosaicImage = newImage.mosaicImage(level: config.mosaic.mosaicWidth)
                photoEditView.setMosaicOriginalImage(mosaicImage)
            }
        }
    }
    func filterView(_ filterView: PhotoEditorFilterView, touchUpInside value: Float) {
        let filterInfo = config.filter.infos[filterView.currentSelectedIndex - 1]
        if let newImage = filterInfo.filterHandler(thumbnailImage, photoEditView.image, value, .touchUpInside) {
            photoEditView.updateImage(newImage)
            photoEditView.imageResizerView.filterValue = value
            let mosaicImage = newImage.mosaicImage(level: config.mosaic.mosaicWidth)
            photoEditView.setMosaicOriginalImage(mosaicImage)
        }
    }
}

extension PhotoEditorViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is EditorStickerContentView {
            return false
        }
        if let isDescendant = touch.view?.isDescendant(of: photoEditView), isDescendant {
            return true
        }
        return false
    }
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

/*
    增加完 Text 的回调.
 */
extension PhotoEditorViewController: EditorStickerTextViewControllerDelegate {
    func stickerTextViewController( _ controller: EditorStickerTextViewController,
                                    didFinish stickerItem: EditorStickerItem ) {
        photoEditView.updateSticker(item: stickerItem)
    }
    
    // 在这里, 完成了 Text 和 Sticker 的统一处理.
    // Text 变为了图片, 就是一个 Sticker
    func stickerTextViewController( _ controller: EditorStickerTextViewController,
                                    didFinish stickerText: EditorStickerText ) {
        let item = EditorStickerItem(image: stickerText.image, imageData: nil, text: stickerText)
        photoEditView.addSticker(item: item, isSelected: false)
    }
}

extension PhotoEditorViewController: EditorChartletViewDelegate {
    func chartletView(
        _ chartletView: EditorChartletView,
        loadTitleChartlet response: @escaping ([EditorChartlet]) -> Void
    ) {
        if let editorDelegate = delegate {
            editorDelegate.photoEditorViewController(
                self,
                loadTitleChartlet: response
            )
        }else {
#if canImport(Kingfisher)
            let titles = PhotoTools.defaultTitleChartlet()
            response(titles)
#else
            response([])
#endif
        }
    }
    func chartletView(backClick chartletView: EditorChartletView) {
        handleSingleTap()
    }
    
    // 在 PhotoEditVC 里面, 也会将这些, 代理给外界. 或者, 使用默认的一些数据.
    // 这些都是取值的过程, 可以在开始的版本, 写简单一些, 直接使用单例从 ChartletManager 中取值就得了.
    func chartletView(_ chartletView: EditorChartletView,
                      titleChartlet: EditorChartlet,
                      titleIndex: Int,
                      loadChartletList response: @escaping (Int, [EditorChartlet]) -> Void) {
        if let editorDelegate = delegate {
            editorDelegate.photoEditorViewController(self,
                                                     titleChartlet: titleChartlet,
                                                     titleIndex: titleIndex,
                                                     loadChartletList: response)
        }else {
            /// 默认加载这些贴图
#if canImport(Kingfisher)
            let chartletList = PhotoTools.defaultNetworkChartlet()
            response(titleIndex, chartletList)
#else
            response(titleIndex, [])
#endif
        }
    }
    
    func chartletView( _ chartletView: EditorChartletView,
                       didSelectImage image: UIImage,
                       imageData: Data?) {
        let item = EditorStickerItem(image: image, imageData: imageData, text: nil )
        photoEditView.addSticker( item: item, isSelected: false )
        handleSingleTap()
    }
}
