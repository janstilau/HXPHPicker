//
//  PhotoEditorViewController+Views.swift
//  HXPHPicker
//
//  Created by JustinLau on 2022/1/9.
//

import Foundation

extension PhotoEditorViewController {
    
    func createPhotoEditorView() -> PhotoEditorView {
        let imageView = PhotoEditorView.init(config: config)
        imageView.editorDelegate = self
        
//        imageView.addBorderline(inWidth: 4, color: UIColor.red)
        return imageView
    }
    
    func createEditorCropConfirmView() -> EditorCropConfirmView {
        let cropConfirmView = EditorCropConfirmView.init(config: config.cropConfimView, showReset: true)
        cropConfirmView.alpha = 0
        cropConfirmView.isHidden = true
        cropConfirmView.delegate = self
        
//        cropConfirmView.addBorderline(inWidth: 2, color: UIColor.random())
//        cropConfirmView.addTip("CropConfirmView")
        return cropConfirmView
    }
    
    func createEditorToolView() -> EditorToolView {
        let toolView = EditorToolView.init(config: config.toolView)
        toolView.delegate = self
        
//        toolView.addBorderline(inWidth: 2, color: UIColor.blue)
//        toolView.addTip("ToolView")
        return toolView
    }
    
    func createTopView() -> UIView {
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        let cancelBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: 57, height: 44))
        cancelBtn.setImage(UIImage.image(for: "hx_editor_back"), for: .normal)
        cancelBtn.addTarget(self, action: #selector(didBackButtonClick), for: .touchUpInside)
        view.addSubview(cancelBtn)
        
//        view.addBorderline(inWidth: 2, color: UIColor.brown)
//        view.addTip("TopView")
        return view
    }
    
    func createTopMask() -> CAGradientLayer {
        let layer = PhotoTools.getGradientShadowLayer(true)
        return layer
    }
    
    func createPhotoEditorBrushColorView() -> PhotoEditorBrushColorView {
        let view = PhotoEditorBrushColorView.init(frame: .zero)
        view.delegate = self
        view.brushColors = config.brushColors
        view.currentColorIndex = config.defaultBrushColorIndex
        view.alpha = 0
        view.isHidden = true
        
//        view.addBorderLine()
//        view.addTip("BrushColorView")
        return view
    }
    
    func createPhotoEditorCropToolView() -> PhotoEditorCropToolView {
        var showRatios = true
        if config.cropping.fixedRatio || config.cropping.isRoundCrop {
            showRatios = false
        }
        let view = PhotoEditorCropToolView.init(showRatios: showRatios)
        view.delegate = self
        view.themeColor = config.cropping.aspectRatioSelectedColor
        view.alpha = 0
        view.isHidden = true
        
//        view.addBorderLine()
//        view.addTip("CropToolView")
        return view
    }
    
    func createPhotoEditorMosaicToolView() -> PhotoEditorMosaicToolView {
        let view = PhotoEditorMosaicToolView(selectedColor: config.toolView.toolSelectedColor)
        view.delegate = self
        view.alpha = 0
        view.isHidden = true
        
//        view.addBorderLine()
//        view.addTip("MosaicToolView")
        return view
    }
    
    func createPhotoEditorFilterView() -> PhotoEditorFilterView {
        let filter = editResult?.editedData.filter
        let value = editResult?.editedData.filterValue
        let view = PhotoEditorFilterView.init(filterConfig: config.filter,
                                              sourceIndex: filter?.sourceIndex ?? -1,
                                              value: value ?? 0)
        view.delegate = self
        
//        view.addBorderLine()
//        view.addTip("FilterView")
        return view
    }
    
    func createEditorChartletView() -> EditorChartletView {
        let view = EditorChartletView(config: config.chartlet, editorType: .photo)
        view.delegate = self
        
//        view.addBorderLine()
//        view.addTip("ChartletView")
        return view
    }
}
