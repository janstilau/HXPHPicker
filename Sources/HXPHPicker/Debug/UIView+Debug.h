//
//  UIView+Debug.h
//  MCMoego
//
//  Created by JustinLau on 2019/3/25.
//  Copyright © 2019年 Moca Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIColor+Debug.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 主要用来调试, 显示 View 在视图上的位置.
 */

@interface UIView (Debug)

/**
 * 增加边框, 用于动态调试时, 确定 View 的实际位置. 边框颜色随机
 */
- (void)addBorderLine;
- (void)addBorderLineInWidth:(CGFloat)width;
- (void)addBorderlineInWidth:(CGFloat)width color:(UIColor*)color;

/**
 * 增加描述文字, 用于动态调试时, 确定 View 的功能. 文字颜色随机
 */
- (void)addTip:(NSString *)tip;

@end

NS_ASSUME_NONNULL_END

