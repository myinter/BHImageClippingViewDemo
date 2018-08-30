//
//  BaseViewController.m
//  BeautyPlusMe
//
//  Created by xiongweihua on 2018/4/25.
//  Copyright © 2018年 xiongweihua. All rights reserved.
//

#import "BaseViewController.h"
@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if ([UIApplication sharedApplication].keyWindow.frame.size.height / [UIApplication sharedApplication].keyWindow.frame.size.width > (16.0/9.0)) {
        [self adjustForFringeScreen];
    }
    
    //侦听引用进入后台的消息
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)adjustForFringeScreen
{
    //针对刘海屏需要作出的调整
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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
