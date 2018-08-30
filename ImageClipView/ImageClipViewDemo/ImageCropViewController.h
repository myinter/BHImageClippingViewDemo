//
//  ImageCropViewController.h
//  BeautyPlusMe
//
//  Created by xiongweihua on 2018/5/23.
//  Copyright © 2018年 xiongweihua. All rights reserved.
//

#import "BHImageClippingView.h"
#import "BaseViewController.h"

typedef void(^ImageBlock)(UIImage *resultImage);
@protocol ImageCropViewControllerDelegate <NSObject>

@optional
-(void)output:(UIImage *)image;

@end

@interface ImageCropViewController : BaseViewController
{

    UIImage *_originImage;
    
    ImageBlock _resultBlock;
    
    __weak IBOutlet BHImageClippingView *_imageClippingView;
    
    IBOutletCollection(NSLayoutConstraint) NSArray *_topBottomCSTs;
    
    IBOutletCollection(UILabel) NSArray *_ratioLabels;
    
    IBOutletCollection(UIButton) NSArray *_buttons;
    
}
@property (nonatomic) id<ImageCropViewControllerDelegate> delegate;

-(void)setResultBlock:(ImageBlock)block;

-(ImageCropViewController *)initWithImage:(UIImage *)image;

@end
