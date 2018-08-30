//
//  ViewController.m
//  ImageClipView
//
//  Created by bighiung on 2018/7/31.
//  Copyright © 2018年 bighiung. All rights reserved.
//

#import "ViewController.h"
#import "PhotoSelectViewController.h"
#import "ImageCropViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSLog(@"%@",self.view);
}

- (IBAction)buttonsClicked:(UIButton *)sender {
    
    switch (sender.tag) {
        case 0:
        {
            __weak ViewController *weakSelf = self;
            PhotoSelectViewController *selectVC = [[PhotoSelectViewController alloc]initWithImageBlock:^(UIImage *image) {
                __strong ViewController *strongSelf = weakSelf;
                if (strongSelf) {
                    strongSelf->_imageView.image = image;
                }
            }];
            [self presentViewController:selectVC animated:YES completion:nil];
        }
            break;
        case 1:
        {

            if (_imageView.image) {
                ImageCropViewController *vc = [[ImageCropViewController alloc]initWithImage:_imageView.image];
                __weak ViewController *weakSelf = self;
                [vc setResultBlock:^(UIImage *resultImage) {
                    __strong ViewController *strongSelf = weakSelf;
                    if (strongSelf) {
                        strongSelf.imageView.image = resultImage;
                    }
                }];
                
                [self presentViewController:vc animated:YES completion:nil];
            }
        }
            break;
        default:
            break;
    }
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





@end
