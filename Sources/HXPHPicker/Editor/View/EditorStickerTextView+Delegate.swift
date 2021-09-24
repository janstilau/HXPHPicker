//
//  EditorStickerTextView+Delegate.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

extension EditorStickerTextView: UITextViewDelegate {
    
    /*
        The text view calls this method in response to user-initiated changes to the text. This method is not called in response to programmatically initiated changes.
        用户行为, 才会触发这个代理方法.
        所以, 在这个方法里面, 进行 text 的修改, 不会造成方法的循环调用陷入死循环.
     */
    func textViewDidChange(_ textView: UITextView) {
        /*
            The attributes to apply to new text that the user enters.
            This dictionary contains the attribute keys (and corresponding values) to apply to newly typed text. When the text view’s selection changes,
            the contents of the dictionary are cleared automatically.
         */
        textView.typingAttributes = typingAttributes
        
        if textIsDelete {
            drawTextBackgroudColor()
            textIsDelete = false
        }
        
        if !textView.text.isEmpty {
            if textView.text.count > config.maximumLimitTextLength &&
                config.maximumLimitTextLength > 0 {
                let text = textView.text[..<config.maximumLimitTextLength]
                textView.text = text
            }
        } else {
            textBgLayer?.frame = .zero
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text.isEmpty {
            textIsDelete = true
        }
        return true
    }
}

/*
    通过这个方法, 可以在任何 TextView 变化的时候, 进行 drawTextBackgroudColor 的调用.
    文字变化.
    方向改变.
    textView 的位置变化等等.
 */
extension EditorStickerTextView: NSLayoutManagerDelegate {
    func layoutManager( _ layoutManager: NSLayoutManager,
                        didCompleteLayoutFor textContainer: NSTextContainer?,
                        atEnd layoutFinishedFlag: Bool ) {
        if layoutFinishedFlag {
            drawTextBackgroudColor()
        }
    }
}

class EditorStickerTextLayer: CAShapeLayer { }
