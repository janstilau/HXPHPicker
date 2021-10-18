//
//  EditorStickerTextView+CollectionView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

// 将 EditorStickerTextView 的具体实现, 按照功能模块, 使用 extension 进行分层

extension EditorStickerTextView: UICollectionViewDataSource,
                                 UICollectionViewDelegate {
    func collectionView( _ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        config.colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "EditorStickerTextViewCellID",
            for: indexPath ) as! PhotoEditorBrushColorViewCell
        cell.colorHex = config.colors[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: IndexPath(item: currentSelectedIndex, section: 0), animated: true)
        if currentSelectedIndex == indexPath.item { return }
        
        let color = config.colors[indexPath.item].color
        currentSelectedColor = color
        currentSelectedIndex = indexPath.item
        if showBgColor {
            textBgColor = color
            if color.isWhite {
                changeTextColor(color: .black)
            }else {
                changeTextColor(color: .white)
            }
        } else {
            changeTextColor(color: color)
        }
    }
}
