//
//  BaseViewController.h
//  BeautyPlusMe
//
//  Created by xiongweihua on 2018/4/25.
//  Copyright © 2018年 xiongweihua. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseViewController : UIViewController

/*对刘海屏进行适配和调整*/
-(void)adjustForFringeScreen;

/*app进入后台*/
-(void)appEnterBackground;

/*app进入前台*/
-(void)appEnterForeground;

-(void)goBack;

-(void)goBackAnimated:(BOOL)animated;

@end
