//
//  PhotoEditorDrawView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/11.
//

import UIKit

protocol PhotoEditorDrawViewDelegate: AnyObject {
    func drawView(beganDraw drawView: PhotoEditorDrawView)
    func drawView(endDraw drawView: PhotoEditorDrawView)
}

class PhotoEditorDrawView: UIView, UIGestureRecognizerDelegate {
    
    weak var delegate: PhotoEditorDrawViewDelegate?
    
    var lineColor: UIColor = .white
    var lineWidth: CGFloat = 5.0
    var enabled: Bool = false {
        didSet { isUserInteractionEnabled = enabled }
    }
    var scale: CGFloat = 1
    var count: Int { linePaths.count }
    var canUndo: Bool { !linePaths.isEmpty }
    var isDrawing: Bool { (!isUserInteractionEnabled || !enabled) ? false : isTouching }
    
    private var linePaths: [PhotoEditorBrushPath] = []
    private var currentPathPoints: [CGPoint] = []
    private var shapeLayers: [CAShapeLayer] = []
    
    private var isTouching: Bool = false
    private var isBegan: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        isUserInteractionEnabled = false
        
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(hanlePanGesture(panGR:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        addGestureRecognizer(pan)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer ) -> Bool {
        if otherGestureRecognizer.isKind(of: UITapGestureRecognizer.self) &&
            otherGestureRecognizer.view is PhotoEditorView {
            return true
        }
        return false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Undo 就是删除最后一个 Path.
    func undo() {
        if shapeLayers.isEmpty {
            return
        }
        shapeLayers.last?.removeFromSuperlayer()
        shapeLayers.removeLast()
        linePaths.removeLast()
    }
    
    func emptyCanvas() {
        shapeLayers.forEach { (shapeLayer) in
            shapeLayer.removeFromSuperlayer()
        }
        linePaths.removeAll()
        shapeLayers.removeAll()
    }
    
    /*
     UIBezierPath 是一个, 平台相关的数据.
     提交给服务器, 是通用的数据. 所以, 在绘制的过程里面, 不断的记录 Point 的意图就在这里, 颜色值, 宽度值, 都是有着统一的记录的方案.
     但是路径, 只能是把一个个点记录起来. 然后提交给后端进行存储.
     相应的, 从数据反序列化并展示 View 的过程, 就是根据上面的数据, 拼接 Path 的过程.
     这个过程没有太大的问题, 因为, 通过 Gesture 来进行处理的时候, 也是 Path 不断的拼接 Point 来实现的.
     */
    func getBrushData() -> [PhotoEditorBrushData] {
        var brushsData: [PhotoEditorBrushData] = []
        for path in linePaths {
            let brushData = PhotoEditorBrushData.init(color: path.color!,
                                                      points: path.points,
                                                      lineWidth: path.lineWidth)
            brushsData.append(brushData)
        }
        return brushsData
    }
    
    /*
     这个过程, 其实就是根据存储的数据, 还原原本的路径的过程.
     其实就是, 遍历 Point, 回复原有 Path 的过程.
     最终, 根据 Path 创建出相应的 Layer, 添加到屏幕上.
     */
    func setBrushData(_ brushsData: [PhotoEditorBrushData], viewSize: CGSize) {
        for brushData in brushsData {
            let path = PhotoEditorBrushPath()
            path.lineWidth = brushData.lineWidth
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.points = brushData.points
            for (index, point) in brushData.points.enumerated() {
                let cPoint = CGPoint(x: point.x * viewSize.width, y: point.y * viewSize.height)
                if index == 0 {
                    path.move(to: cPoint)
                }else {
                    path.addLine(to: cPoint)
                }
            }
            path.color = brushData.color
            linePaths.append(path)
            let shapeLayer = createdShapeLayer(path: path)
            layer.addSublayer(shapeLayer)
            shapeLayers.append(shapeLayer)
        }
    }
}

private extension PhotoEditorDrawView {
    
    /*
     Pan 开始的时候, 创建一个新的 Path, 一个新的 Shape, 开始重新记录 Points.
     拖动的过程中, 不断的修改 Path, Shape, 记录 points.
     结束, 将 Points 赋值到相应的数据结构.
     */
    @objc private func hanlePanGesture(panGR: UIPanGestureRecognizer) {
        switch panGR.state {
        case .began:
            currentPathPoints.removeAll()
            let point = panGR.location(in: self)
            isTouching = false
            let path = PhotoEditorBrushPath()
            path.lineWidth = lineWidth / scale
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.move(to: point)
            path.color = lineColor
            linePaths.append(path)
            currentPathPoints.append(CGPoint(x: point.x / width, y: point.y / height))
            let shapeLayer = createdShapeLayer(path: path)
            layer.addSublayer(shapeLayer)
            shapeLayers.append(shapeLayer)
        case .changed:
            let point = panGR.location(in: self)
            let path = linePaths.last
            if path?.currentPoint.equalTo(point) == false {
                delegate?.drawView(beganDraw: self)
                isTouching = true
                // 在交互过程中, 也是通过, 不断的给 Path 拼接 Point, 来实现的 Path 的绘制.
                path?.addLine(to: point)
                currentPathPoints.append(CGPoint(x: point.x / width, y: point.y / height))
                let shapeLayer = shapeLayers.last
                // 修改 ShapeLayer 的 Path, 就是修改 ShapeLayer 的展示.
                shapeLayer?.path = path?.cgPath
            }
        case .failed, .cancelled, .ended:
            if isTouching {
                let path = linePaths.last
                path?.points = currentPathPoints
                delegate?.drawView(endDraw: self)
            }else {
                undo()
            }
            currentPathPoints.removeAll()
            isTouching = false
        default:
            break
        }
    }
    
    func createdShapeLayer(path: PhotoEditorBrushPath) -> CAShapeLayer {
        /*
         A layer that draws a cubic Bezier spline in its coordinate space.
         */
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.backgroundColor = UIColor.clear.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        shapeLayer.strokeColor = path.color?.cgColor
        shapeLayer.lineWidth = path.lineWidth
        return shapeLayer
    }
}

/*
 PhotoEditorBrushPath: UIBezierPath 是没有办法序列化的, 能够序列化的只能是基本的数据类型.
 PhotoEditorBrushData 这个类, 就是为了序列化存在的.
 应该添加一个 PhotoEditorBrushData 和 PhotoEditorBrushPath 的相互转化的工厂方法才好.
 */
struct PhotoEditorBrushData {
    let color: UIColor
    let points: [CGPoint]
    let lineWidth: CGFloat
}

extension PhotoEditorBrushData: Codable {
    
    enum CodingKeys: String, CodingKey {
        case color
        case points
        case lineWidth
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let colorData = try container.decode(Data.self, forKey: .color)
        color = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as! UIColor
        points = try container.decode([CGPoint].self, forKey: .points)
        lineWidth = try container.decode(CGFloat.self, forKey: .lineWidth)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if #available(iOS 11.0, *) {
            let colorData = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
            try container.encode(colorData, forKey: .color)
        } else {
            // Fallback on earlier versions
            let colorData = NSKeyedArchiver.archivedData(withRootObject: color)
            try container.encode(colorData, forKey: .color)
        }
        try container.encode(points, forKey: .points)
        try container.encode(lineWidth, forKey: .lineWidth)
    }
}

class PhotoEditorBrushPath: UIBezierPath {
    var color: UIColor?
    var points: [CGPoint] = []
}
