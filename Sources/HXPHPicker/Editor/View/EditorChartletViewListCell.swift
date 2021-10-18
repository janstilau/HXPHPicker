//
//  EditorChartletViewListCell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit
#if canImport(Kingfisher)
import Kingfisher
#endif

// 将, 单个表情被点击之后, 通过代理的方式, 回传到上一层.
protocol EditorChartletViewListCellDelegate: AnyObject {
    func listCell(_ cell: EditorChartletViewListCell, didSelectImage image: UIImage, imageData: Data?)
}

/*
    一个 EditorChartletViewListCell, 代表的是一组表情包.
    里面有一个 CollectionView, 来展示, 所有的表情.
 */
class EditorChartletViewListCell: UICollectionViewCell,
                                  UICollectionViewDataSource,
                                  UICollectionViewDelegate,
                                  UICollectionViewDelegateFlowLayout {
    weak var delegate: EditorChartletViewListCellDelegate?
    
    var rowCount: Int = 4
    var chartletList: [EditorChartlet] = [] {
        didSet {
            collectionView.reloadData()
            resetOffset()
        }
    }
    var editorType: EditorController.EditorType = .photo
    
    func resetOffset() {
        collectionView.contentOffset = CGPoint(
            x: -collectionView.contentInset.left,
            y: -collectionView.contentInset.top
        )
    }
    
    func startLoading() {
        loadingView.startAnimating()
    }
    
    func stopLoad() {
        loadingView.stopAnimating()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(collectionView)
        contentView.addSubview(loadingView)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return chartletList.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "EditorChartletViewListCellID",
            for: indexPath
        ) as! EditorChartletViewCell
        cell.editorType = editorType
        cell.chartlet = chartletList[indexPath.item]
        return cell
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let rowCount = !UIDevice.isPortrait && !UIDevice.isPad ? 7 : CGFloat(self.rowCount)
        let margin = collectionView.contentInset.left + collectionView.contentInset.right
        let spacing = flowLayout.minimumLineSpacing * (rowCount - 1)
        let itemWidth = (width - margin - spacing) / rowCount
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath ) {
        collectionView.deselectItem(at: indexPath, animated: false)
        
        let cell = collectionView.cellForItem(at: indexPath) as! EditorChartletViewCell
        if var image = cell.chartlet.image {
            let imageData: Data?
            if editorType == .photo {
                if let count = image.images?.count,
                   let img = image.images?.first,
                   count > 0 {
                    image = img
                }
                imageData = nil
            }else {
                imageData = cell.chartlet.imageData
            }
            
            delegate?.listCell(
                self,
                didSelectImage: image,
                imageData: imageData
            )
        } else {
#if canImport(Kingfisher)
            // 只要, 在图片已经下载完成的情况下, 点击之后才应该触发回调操作.
            if let url = cell.chartlet.url, cell.downloadCompletion {
                let options: KingfisherOptionsInfo = []
                PhotoTools.downloadNetworkImage(
                    with: url,
                    cancelOrigianl: false,
                    options: options,
                    completionHandler: { [weak self] (image) in
                        guard let self = self else { return }
                        if let image = image {
                            if self.editorType == .photo {
                                if let data = image.kf.gifRepresentation(),
                                   let img = UIImage(data: data) {
                                    self.delegate?.listCell(self, didSelectImage: img, imageData: nil)
                                    return
                                }
                                self.delegate?.listCell(self, didSelectImage: image, imageData: nil)
                            } else {
                                self.delegate?.listCell(self,
                                                        didSelectImage: image,
                                                        imageData: image.kf.gifRepresentation())
                            }
                        }
                    })
            }
#endif
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds
        loadingView.center = CGPoint(x: width * 0.5, y: height * 0.5)
        collectionView.contentInset = UIEdgeInsets(
            top: 60,
            left: 15 + UIDevice.leftMargin,
            bottom: 15 + UIDevice.bottomMargin,
            right: 15 + UIDevice.rightMargin
        )
        collectionView.scrollIndicatorInsets = UIEdgeInsets(
            top: 60,
            left: UIDevice.leftMargin,
            bottom: 15 + UIDevice.bottomMargin,
            right: UIDevice.rightMargin
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var loadingView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .white)
        view.hidesWhenStopped = true
        return view
    }()
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 5
        flowLayout.minimumInteritemSpacing = 5
        return flowLayout
    }()
    
    lazy var collectionView: UICollectionView = {
        let view = UICollectionView.init(frame: .zero, collectionViewLayout: flowLayout)
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
        view.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .never
        }
        view.register(EditorChartletViewCell.self, forCellWithReuseIdentifier: "EditorChartletViewListCellID")
        return view
    }()
}
