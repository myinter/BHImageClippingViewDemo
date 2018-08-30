//
//  ClipGridView.h
//  BeautyPlusMe
//
//  Created by xiongweihua on 2018/5/23.
//  Copyright © 2018年 xiongweihua. All rights reserved.
//

#import <UIKit/UIKit.h>
//图片剪裁框网格视图
@interface ClipGridView : UIView

//是否需要四个角上的圆角矩形条
@property (nonatomic) BOOL needRoundedLabels;
/*是否需要四个角上的圆片*/
@property (nonatomic) BOOL needCornerRounds;
/*线框的颜色*/
@property (nonatomic,strong) UIColor *color;
/*竖直条数量,极限255条*/
@property (nonatomic) int8_t columnLinesNumber;
/*横直条数量,极限255条*/
@property (nonatomic) int8_t rowLinesNumber;
/*最小尺寸*/
@property (nonatomic) CGFloat minSize;

@property (nonatomic) CGFloat contentInsect;

/*当前视图剪裁区域的frame(位置是相对于当前视图的父视图)，同时也会设置当前视图的frame*/
@property(nonatomic) CGRect clipRect;

@end
