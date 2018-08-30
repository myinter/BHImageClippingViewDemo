//
//  ImageClippingView.h
//  BeautyPlusMe
//
//  Created by xiongweihua on 2018/5/23.
//  Copyright © 2018年 xiongweihua. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ClipGridView.h"
typedef NS_ENUM(NSUInteger, ImgClipQuadrant) {
    ImgClipQuadrantNone = 0,
    ImgClipQuadrant1 = 100,
    ImgClipQuadrant2,
    ImgClipQuadrant3,
    ImgClipQuadrant4,
    ImgClipOriginArea,
};
typedef void(^ClipResultBlock)(UIImage *image);
typedef struct ClipBounds {
    CGFloat top;
    CGFloat bottom;
    CGFloat left;
    CGFloat right;
}ClipBounds;

inline CGRect ConvertClipBoundsToCGRect(ClipBounds bounds)
{
    CGFloat height = ABS(bounds.bottom - bounds.top);
    CGFloat width = ABS(bounds.right - bounds.left);
    CGFloat x = MIN(bounds.left, bounds.right);
    CGFloat y = MIN(bounds.top,bounds.bottom);
    return CGRectMake(x, y, width, height);
}

//图片剪裁视图
@interface BHImageClippingView : UIView
{
    //选区网格视图
    ClipGridView *_clipGridView;
    
    UIImageView *_imageView;
    
    CGPoint _touchBeganPoint;
    
    ImgClipQuadrant _currentImageQuadrant;
    
    CGRect _clipGridOriginFrame;
        
    BOOL _isMoving;
    
    BOOL _needResetClipGrid;
    
    int _touchMoveCount;
    
    CGFloat _bevelEdgeRatio;
        
}

/*剪切的视图rect*/
@property (nonatomic) CGRect imageClipRect;
//长宽比限制，为0的时候不做限制，可以自由活动。
@property (nonatomic) CGFloat widthHeightRatioConstraint;
/*内容同视图边界的间距*/
@property (nonatomic) CGFloat contentInsect;
/*用于剪裁的UIImage*/
@property (nonatomic,weak) UIImage *image;

/*最小尺寸*/
@property (nonatomic) CGSize minSize;

-(void)clipImage:(ClipResultBlock)resultBlock;

@end
