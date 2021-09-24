//
//  EditorStickerTextView+CollectionView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

extension EditorStickerTextView: UICollectionViewDataSource,
                                 UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        config.colors.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "EditorStickerTextViewCellID",
            for: indexPath
        ) as! PhotoEditorBrushColorViewCell
        cell.colorHex = config.colors[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: IndexPath(item: currentSelectedIndex, section: 0), animated: true)
        if currentSelectedIndex == indexPath.item { return }
        
        /*
            如果, 有背景色, 那么这里选择的就是背景色.
            文字颜色只有黑白两种.
            如果, 没有背景色, 那么这里选择的就是文字颜色.
         */
        let color = config.colors[indexPath.item].color
        currentSelectedColor = color
        currentSelectedIndex = indexPath.item
        if showBackgroudColor {
            useBgColor = color
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
