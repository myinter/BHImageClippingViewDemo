# BHImageClippingViewDemo
Clipper for UIImage,very easy to use..iOS 图片剪裁器,使用非常简单。

设置要剪裁的图片

```Objective-C
    
    [_imageClippingView setImage:_originImage];
对当前选中区域进行剪裁
    
    [_imageClippingView clipImage:^(UIImage *image) {
          //获得剪裁后得到的结果UIImage
    }];
