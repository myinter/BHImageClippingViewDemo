//
//  UIImage+resize.h
//  BeautyPlusMe
//
//  Created by xiongweihua on 2018/5/14.
//  Copyright © 2018年 xiongweihua. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^ImageBlock)(UIImage *image);
typedef void(^ProgressBlock)(CGFloat progress);
UIImage * UIImageTransform(UIImage *image,CGSize toSize);

@interface UIImage (resize)
- (UIImage *)reSizeToSize:(CGSize)reSize;
-(void)getPartInCenterPoint:(CGPoint)targetCenter rectRadius:(CGFloat)rectRadius resultBlock:(ImageBlock)resultBlock;
-(void)getPartInRect:(CGRect)partRect resultBlock:(ImageBlock)resultBlock;
- (UIImage *)transformToWidth:(CGFloat)width height:(CGFloat)height scale:(CGFloat)scale;

- (UIImage *)imageWithColor:(UIColor *)color;

- (UIImage *)applyGaussianBlur;

-(UIImage *)fixOrientation;

UIImage *fixOrientation(UIImage *aImage);
@end
