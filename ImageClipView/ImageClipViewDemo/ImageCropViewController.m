//
//  ImageCropViewController.m
//  BeautyPlusMe
//
//  Created by xiongweihua on 2018/5/23.
//  Copyright © 2018年 xiongweihua. All rights reserved.
//

#import "ImageCropViewController.h"
#import "UIImage+color.h"

@interface ImageCropViewController ()

@end

@implementation ImageCropViewController

-(void)setResultBlock:(ImageBlock)block
{
    _resultBlock = block;
}


-(ImageCropViewController *)initWithImage:(UIImage *)image
{
    self = [self init];
    if (self) {
        _originImage = image;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [_imageClippingView setImage:_originImage];
    
    if ([UIApplication sharedApplication].keyWindow.frame.size.height / [UIApplication sharedApplication].keyWindow.frame.size.width > (16.0/9.0)) {
        [self adjustForFringeScreen];
    }
    
    _imageClippingView.minSize = CGSizeMake(50, 50);
    
    //侦听引用进入后台的消息
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];

    
    for (UIButton *button in _buttons) {
        [button setImage:[[button imageForState:UIControlStateNormal]imageWithColor:[UIColor darkGrayColor]]
                forState:UIControlStateNormal];
        [button setImage:[[button imageForState:UIControlStateNormal]imageWithColor:[UIColor redColor]] forState:UIControlStateSelected];
        button.selected = !button.tag;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#define FREE 0
#define RATIO_11 1
#define RATIO_34 2
#define RATIO_43 3
#define RATIO_9_16 4
#define RATIO_16_9 5
- (IBAction)changeRatioMode:(UIButton *)sender {
    
    for (UIButton *button in _buttons) {
        button.selected = NO;
    }
    
    switch (sender.tag) {
        case FREE:
        {
            _imageClippingView.widthHeightRatioConstraint = 0.0;
        }
            break;
        case RATIO_11:
        {
            _imageClippingView.widthHeightRatioConstraint = 1.0;
        }
            break;
        case RATIO_34:
        {
            _imageClippingView.widthHeightRatioConstraint = 3.0/4.0;
        }
            break;
        case RATIO_43:
        {
            _imageClippingView.widthHeightRatioConstraint = 4.0/3.0;
        }
            break;
        case RATIO_9_16:
        {
            _imageClippingView.widthHeightRatioConstraint = 9.0/16.0;
        }
            break;
        case RATIO_16_9:
        {
            _imageClippingView.widthHeightRatioConstraint = 16.0/9.0;
        }
            break;
        default:
            break;
    }
    sender.selected = YES;
    for (UILabel *label in _ratioLabels) {
        label.textColor = label.tag == sender.tag ? [UIColor redColor] : [UIColor colorWithRed:109.0/255.0 green:109.0/255.0 blue:109.0/255.0 alpha:1.0];

    }
}

#define OK 500
#define CANCEL 1900

- (IBAction)OKCancelButtonsClicked:(UIButton *)sender {
    
    switch (sender.tag) {
        case OK:
        {
            if (_resultBlock || [_delegate respondsToSelector:@selector(output:)]) {
                NSLog(@"_imageClippingView.imageClipRect %@",[NSValue valueWithCGRect:_imageClippingView.imageClipRect]);
                if (_imageClippingView.imageClipRect.size.width) {
                    [_imageClippingView clipImage:^(UIImage *image) {
                        if (self->_resultBlock) {
                            self->_resultBlock(image);
                        }
                        if ([self->_delegate respondsToSelector:@selector(output:)]) {
                            [self->_delegate output:image];
                        }
                        self->_resultBlock = nil;
                        [self goBackAnimated:NO];
                    }];
                }
                else{
                    
                    if (self->_resultBlock) {
                        self->_resultBlock(_originImage);
                    }
                    if ([self->_delegate respondsToSelector:@selector(output:)]) {
                        [self->_delegate output:_originImage];
                    }
                    self->_resultBlock = nil;
                    [self goBackAnimated:NO];
                }
            }
        }
            break;
        case CANCEL:
        {
            [self goBackAnimated:NO];
        }
            break;
        default:
            break;
    }
}

-(void)adjustForFringeScreen
{
    for (NSLayoutConstraint *cst in _topBottomCSTs) {
        cst.constant += 34.0;
    }
}


-(void)appEnterBackground
{
    //应用进入后台
}

-(void)appEnterForeground
{
    //引用进入前台
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

-(void)goBackAnimated:(BOOL)animated
{
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:animated];
    }else if (self.presentingViewController)
    {
        [self dismissViewControllerAnimated:animated completion:nil];
    }
}

-(void)goBack
{
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    }else if (self.presentingViewController)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    if (UI_USER_INTERFACE_IDIOM()== UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
    return UIInterfaceOrientationMaskPortrait;
}


@end
