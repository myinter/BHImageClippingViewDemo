//
//  ImageClippingView.m
//  BeautyPlusMe
//
//  Created by xiongweihua on 2018/5/23.
//  Copyright © 2018年 xiongweihua. All rights reserved.
//

#import "BHImageClippingView.h"
#ifdef DEBUG
#define NSLog(...) NSLog(__VA_ARGS__)
#define printf(...) printf(__VA_ARGS__)
#else
#define NSLog(...)
#define printf(...)
#endif
typedef void(^BHImageOutputBlock)(UIImage *image);
@implementation BHImageClippingView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
-(BHImageClippingView *)init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self initialize];
}

-(void)initialize
{
    _imageView = [UIImageView new];
    _clipGridView = [ClipGridView new];
    [self addSubview:_imageView];
    [self addSubview:_clipGridView];
    _clipGridView.backgroundColor = [UIColor clearColor];
    
    _needResetClipGrid = YES;
    self.autoresizesSubviews = NO;
}


-(void)setContentInsect:(CGFloat)contentInsect
{
    _contentInsect = contentInsect;
    _needResetClipGrid = YES;
    [self layoutSubviews];
}

-(void)setWidthHeightRatioConstraint:(CGFloat)widthHeightRatioConstraint{
    _widthHeightRatioConstraint = widthHeightRatioConstraint;
    _needResetClipGrid = YES;
    _bevelEdgeRatio = sqrt(1.0 + _widthHeightRatioConstraint * _widthHeightRatioConstraint);
    if (_widthHeightRatioConstraint != 0.0) {
        [self layoutSubviews];
    }
}
-(void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    _needResetClipGrid = YES;
}

-(void)setBounds:(CGRect)bounds{
    [super setBounds:bounds];
    _needResetClipGrid = YES;
}

-(void)setImage:(UIImage *)image
{
    _imageView.image = image;
    _image = image;
    _needResetClipGrid = YES;
    [self bringSubviewToFront:_clipGridView];
    [self layoutIfNeeded];
}

-(void)clipImage:(ClipResultBlock)resultBlock
{
    GetPartOfImageInRect(_imageClipRect, _imageView.image, resultBlock);
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    printf("touch began");
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    _touchBeganPoint = CGPointZero;
    _touchMoveCount = 0;
    _touchBeganPoint = point;
    _clipGridOriginFrame = _clipGridView.clipRect;
    _needResetClipGrid = NO;

    //判断点击的的位置是否已在
    if (CGRectContainsPoint(CGRectMake(_clipGridView.frame.origin.x - 80, _clipGridView.frame.origin.y - 80, _clipGridView.frame.size.width + 100, _clipGridView.frame.size.height + 100), point)) {
        _isMoving = YES;
        CGPoint gridCenter = _clipGridView.center;
        

        if (_widthHeightRatioConstraint != 0.0) {
            
            if (ABS(gridCenter.x - point.x) < _clipGridView.frame.size.width / 4.0 || ABS(gridCenter.y - point.y) < _clipGridView.frame.size.height / 4.0) {
                printf("中央区域");
                _currentImageQuadrant = ImgClipOriginArea;
                return;
            }

            
            if (point.x > gridCenter.x) {
                if (point.y > gridCenter.y) {
                    _currentImageQuadrant = ImgClipQuadrant4;
                }
                else
                {
                    _currentImageQuadrant = ImgClipQuadrant1;
                }
            }
            else
            {
                if (point.y > gridCenter.y) {
                    _currentImageQuadrant = ImgClipQuadrant3;
                }
                else
                {
                    _currentImageQuadrant = ImgClipQuadrant2;
                }
            }

            
        }
        else
        {
            
            if (ABS(gridCenter.x - point.x) < _clipGridView.frame.size.width / 6.0 && ABS(gridCenter.y - point.y) < _clipGridView.frame.size.height / 6.0) {
                printf("中央区域");
                _currentImageQuadrant = ImgClipOriginArea;
                return;
            }

            if (point.x > gridCenter.x) {
                if (point.y > gridCenter.y) {
                    _currentImageQuadrant = ImgClipQuadrant4;
                }
                else
                {
                    _currentImageQuadrant = ImgClipQuadrant1;
                }
            }
            else
            {
                if (point.y > gridCenter.y) {
                    _currentImageQuadrant = ImgClipQuadrant3;
                }
                else
                {
                    _currentImageQuadrant = ImgClipQuadrant2;
                }
            }
        }
    }
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    if (!_isMoving) {
        return;
    }
    
        ImgClipQuadrant blockCurrentImageQuadrant = _currentImageQuadrant;
        CGFloat blockWidthHeightRatioConstraint = _widthHeightRatioConstraint;
        CGRect blockClipGridOriginFrame = _clipGridOriginFrame;
        CGRect imageViewFrame = _imageView.frame;
        CGFloat blockBevelEdgeRatio = _bevelEdgeRatio;
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    //求出当前选择矩形，四个选择框的位置
    if (CGPointEqualToPoint(self->_touchBeganPoint,CGPointZero)) {
        self->_touchBeganPoint = point;
        return;
    }
    
    if (self->_minSize.width > 0 && self->_minSize.height > 0) {
        if (blockClipGridOriginFrame.size.height <= self->_minSize.height || blockClipGridOriginFrame.size.width <= self->_minSize.width) {
            return;
        }
    }
    
    CGFloat top = blockClipGridOriginFrame.origin.y;
    CGFloat bottom = top + blockClipGridOriginFrame.size.height;
    CGFloat left = blockClipGridOriginFrame.origin.x;
    CGFloat right = left + blockClipGridOriginFrame.size.width;
    CGFloat height = ABS(bottom - top);
    CGFloat width = ABS(right - left);
    
    CGFloat imageViewRight = imageViewFrame.size.width + imageViewFrame.origin.x;
    CGFloat imageViewLeft = imageViewFrame.origin.x;
    CGFloat imageViewTop = imageViewFrame.origin.y;
    CGFloat imageViewBottom = imageViewFrame.size.height + imageViewFrame.origin.y;
    
    CGFloat moveOffsetY = point.y - self->_touchBeganPoint.y;
    CGFloat moveOffsetX = point.x - self->_touchBeganPoint.x;
    
    CGFloat moveOffsetYOri = moveOffsetY;
    CGFloat moveOffsetXOri = moveOffsetX;
    
    CGRect clipRect = self->_clipGridView.clipRect;
    
    if (blockWidthHeightRatioConstraint != 0.0) {
        
        if (blockCurrentImageQuadrant != ImgClipOriginArea) {
            CGFloat totalOffset = sqrt(moveOffsetY * moveOffsetY + moveOffsetX * moveOffsetX);
            moveOffsetX = (totalOffset / blockBevelEdgeRatio) * blockWidthHeightRatioConstraint * (moveOffsetX >= 0 ? 1 : -1);
            moveOffsetY = (totalOffset / blockBevelEdgeRatio) * (moveOffsetY >= 0 ? 1 : -1);
        }
        
        CGFloat currentTop = clipRect.origin.y;
        CGFloat currentBottom = currentTop + clipRect.size.height;
        CGFloat currentLeft = clipRect.origin.x;
        CGFloat currentRight = currentLeft + clipRect.size.width;
        
        //触点位于哪个象限
        switch (blockCurrentImageQuadrant) {
            case ImgClipQuadrant1:
            {
                if (moveOffsetXOri > 0 && currentRight == imageViewRight) {
                    return;
                }
                if (moveOffsetYOri < 0 && currentTop == imageViewTop) {
                    return;
                }
            }
                break;
            case ImgClipQuadrant2:
            {
                if (moveOffsetXOri < 0 && currentLeft == imageViewLeft) {
                    return;
                }
                
                if (moveOffsetYOri < 0 && currentTop == imageViewTop) {
                    return;
                }
            }
                break;
            case ImgClipQuadrant3:
            {
                if (moveOffsetXOri < 0 && currentLeft == imageViewLeft) {
                    return;
                }
                
                if (moveOffsetYOri < 0 && currentBottom == imageViewBottom) {
                    return;
                }
            }
                break;
            case ImgClipQuadrant4:
            {
                if (moveOffsetXOri > 0 && currentRight == imageViewRight) {
                    return;
                }
                
                if (moveOffsetYOri > 0 && currentBottom == imageViewBottom) {
                    return;
                }
                
                printf("\n================== imageViewBottom %f bottom %f =====================",imageViewBottom,currentBottom);
            }
                break;
            case ImgClipOriginArea:
            {
                CGFloat newTop = top + moveOffsetYOri;
                CGFloat newBottom = bottom + moveOffsetYOri;
                CGFloat newLeft = left + moveOffsetXOri;
                CGFloat newRight = right + moveOffsetXOri;
                
                if (newTop < imageViewTop) {
                    newTop = imageViewTop;
                    newBottom = newTop + self->_clipGridOriginFrame.size.height;
                }
                
                if (newLeft < imageViewLeft) {
                    newLeft = imageViewLeft;
                    newRight = newLeft + self->_clipGridOriginFrame.size.width;
                }
                
                if (newBottom > imageViewBottom) {
                    newBottom = imageViewBottom;
                    newTop = newBottom - self->_clipGridOriginFrame.size.height;
                }
                
                if (newRight > imageViewRight) {
                    newRight = imageViewRight;
                    newLeft = newRight - self->_clipGridOriginFrame.size.width;
                }
                
                top = newTop;
                bottom = newBottom;
                left = newLeft;
                right = newRight;
                
                self->_clipGridView.center = CGPointMake( (left + right) / 2 ,(top + bottom) / 2);
                
                CGFloat ratio = self->_image.size.width / self->_imageView.frame.size.width;
                self->_imageClipRect = CGRectMake((clipRect.origin.x - self->_imageView.frame.origin.x) * ratio, (clipRect.origin.y - self->_imageView.frame.origin.y) * ratio, clipRect.size.width * ratio, clipRect.size.height * ratio);
                
                return;
            }
                break;
            default:
                break;
        }
        
        
        switch (blockCurrentImageQuadrant) {
            case ImgClipQuadrant1:
            {
                //从第一象限开始,设置right 和 top
                NSLog(@"ImgClipQuadrant1");
                top = point.y;
                //当前条件下顶部的极限
                CGFloat topMin = bottom - (imageViewRight - left) / blockWidthHeightRatioConstraint;
                if (top < topMin) {
                    top = topMin;
                }
                else
                {
                    CGFloat topMax = top + (right - imageViewLeft) / blockWidthHeightRatioConstraint;
                    if ( top > topMax) {
                        topMax = topMax;
                    }
                }
                right = left + (bottom - top) * blockWidthHeightRatioConstraint;
                
                NSLog(@"topMax %f vector from %f",topMin,(right - left) / (top - bottom));
            }
                break;
            case ImgClipQuadrant2:
            {
                //从第二象限开始,设置left 和 top
                top = point.y;
                
                CGFloat topMin = bottom - (right - imageViewLeft ) / blockWidthHeightRatioConstraint;
                if (topMin > top) {
                    top = topMin;
                }
                else
                {
                    CGFloat topMax = bottom + (imageViewRight - right) / blockWidthHeightRatioConstraint;
                    if (top > topMax) {
                        top = topMax;
                    }
                }
                left = right - (bottom - top) * blockWidthHeightRatioConstraint;
                NSLog(@"topMax %f vector from %f",topMin,(right - left) / (top - bottom));
            }
                break;
            case ImgClipQuadrant3:
            {
                //从第三象限开始,设置left和bottom
                
                left = point.x;
                if (left < 0) {
                    left = 0;
                }
                bottom = top + (right - left) / blockWidthHeightRatioConstraint;
                CGFloat bottomMax = top + (right - imageViewLeft) / blockWidthHeightRatioConstraint;
                
                printf("before \n ==========bottomMax %f bottom %f =============",bottomMax,bottom);
                if (bottom > bottomMax) {
                    bottom = bottomMax;
                }
                printf("\n after  ==========bottomMax %f bottom %f =============",bottomMax,bottom);
                
                NSLog(@"topMax %f vector from %f",bottomMax,(right - left) / (top - bottom));
            }
                break;
            case ImgClipQuadrant4:
            {
                //从第四象限开始,设置right 和 top
                right = point.x;
                bottom = top + (right - left) / blockWidthHeightRatioConstraint;
                CGFloat bottomMax = top + (imageViewRight - left ) / blockWidthHeightRatioConstraint;
                if (bottom > bottomMax) {
                    bottom = bottomMax;
                }
            }
                break;
            default:
                break;
        }
    }
    else
    {
        switch (blockCurrentImageQuadrant) {
            case ImgClipQuadrant1:
            {
                //从第一象限开始
                right += moveOffsetX;
                top += moveOffsetY;
                
            }
                break;
            case ImgClipQuadrant2:
            {
                //从第二象限开始
                left += moveOffsetX;
                top += moveOffsetY;
            }
                break;
            case ImgClipQuadrant3:
            {
                //从第三象限开始
                left += moveOffsetX;
                bottom += moveOffsetY;
            }
                break;
            case ImgClipQuadrant4:
            {
                //从第四象限开始
                right += moveOffsetX;
                bottom += moveOffsetY;
            }
                break;
            case ImgClipOriginArea:
            {
                CGFloat newTop = top + moveOffsetY;
                CGFloat newBottom = bottom + moveOffsetY;
                CGFloat newLeft = left + moveOffsetX;
                CGFloat newRight = right + moveOffsetX;
                
                if (newTop < imageViewTop) {
                    newTop = imageViewTop;
                    newBottom = newTop + self->_clipGridOriginFrame.size.height;
                }
                
                if (newLeft < imageViewLeft) {
                    newLeft = imageViewLeft;
                    newRight = newLeft + self->_clipGridOriginFrame.size.width;
                }
                
                if (newBottom > imageViewBottom) {
                    newBottom = imageViewBottom;
                    newTop = newBottom - self->_clipGridOriginFrame.size.height;
                }
                
                if (newRight > imageViewRight) {
                    newRight = imageViewRight;
                    newLeft = newRight - self->_clipGridOriginFrame.size.width;
                }
                
                top = newTop;
                bottom = newBottom;
                left = newLeft;
                right = newRight;
                if (self->_isMoving) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self->_clipGridView.center = CGPointMake( (left + right) / 2 ,(top + bottom) / 2);
                    });
                }
                CGFloat ratio = self->_image.size.width / self->_imageView.frame.size.width;
                self->_imageClipRect = CGRectMake((clipRect.origin.x - self->_imageView.frame.origin.x) * ratio, (clipRect.origin.y - self->_imageView.frame.origin.y) * ratio, clipRect.size.width * ratio, clipRect.size.height * ratio);
                return;
            }
                break;
            default:
                return;
                break;
        }
    }
    
    //根据新的 top bottom left right 设置
    //确保四个数值全部大于0，且不超过 _imageView的范围
    top < 0 ? top = 0:top;
    left < 0 ? left = 0:left;
    right < 0 ? right = 0:right;
    bottom < 0 ? bottom = 0:bottom;
    
    height = ABS(bottom - top);
    width = ABS(right - left);
    CGFloat x = MIN(left, right);
    CGFloat y = MIN(top,bottom);
    
    x < imageViewFrame.origin.x ? x = imageViewFrame.origin.x : (x);
    y < imageViewFrame.origin.y ? y = imageViewFrame.origin.y : (y);
    (height + y) > (imageViewFrame.origin.y + imageViewFrame.size.height) ? height = (imageViewFrame.origin.y + imageViewFrame.size.height - y) : (height);
    (width + x) > (imageViewFrame.origin.x + imageViewFrame.size.width) ? width = (imageViewFrame.origin.x + imageViewFrame.size.width - x) : (width);
    
    //最后修正一下长宽比
    
    //不超过_imageView的范围
    clipRect = CGRectMake(x, y, width, height);
    
    self->_clipGridView.clipRect = clipRect;
    
    CGFloat ratio = self->_image.size.width / self->_imageView.frame.size.width;
    self->_imageClipRect = CGRectMake((clipRect.origin.x - self->_imageView.frame.origin.x) * ratio, (clipRect.origin.y - self->_imageView.frame.origin.y) * ratio, clipRect.size.width * ratio, clipRect.size.height * ratio);
    
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    _isMoving = NO;
    _touchBeganPoint = CGPointZero;
    _touchMoveCount = 0;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    //设置imageView的合适位置
    if (_image) {
        CGRect selfFrame = self.frame;
        CGFloat contentHeight = selfFrame.size.height - _contentInsect * 2;
        CGFloat contentWidth = selfFrame.size.width - _contentInsect * 2;
        if (_image.size.width < contentWidth && _image.size.height < contentHeight) {
            //_image无需缩小，直接按照最大的存放
            CGFloat imageHeight = contentWidth * (_image.size.height / _image.size.width);
            _imageView.frame = CGRectMake(_contentInsect, _contentInsect + (contentHeight - imageHeight) / 2, contentWidth,imageHeight );
        }
        else
        {
            CGSize objSize;
            CGRect selfFrame = self.frame;
            CGFloat imageWidthHeigthRatio = _image.size.width / _image.size.height;
            CGFloat contentImageWidthHeightRatio = contentWidth / contentHeight;
            if (imageWidthHeigthRatio > contentImageWidthHeightRatio) {
                objSize = CGSizeMake(contentWidth, contentWidth / imageWidthHeigthRatio);
            }
            else
            {
                objSize = CGSizeMake(contentHeight * imageWidthHeigthRatio, contentHeight);
            }
            _imageView.bounds = CGRectMake(0.0, 0.0, objSize.width, objSize.height);
            _imageView.center = CGPointMake(selfFrame.size.width / 2,selfFrame.size.height / 2 );
        }
    }
    else
    {
        _imageView.frame = self.bounds;
    }
    
    if (_needResetClipGrid) {
        if (_widthHeightRatioConstraint) {
            //限制了宽高比例
            CGRect objRect;
            if (_widthHeightRatioConstraint > (_imageView.frame.size.width / _imageView.frame.size.height)) {
                CGFloat height = _imageView.frame.size.width / _widthHeightRatioConstraint;
                objRect = CGRectMake(_imageView.frame.origin.x, _imageView.frame.origin.y + (_imageView.frame.size.height - height) / 2, _imageView.frame.size.width,height);
            }
            else
            {
                CGFloat width = _imageView.frame.size.height * _widthHeightRatioConstraint;
                objRect = CGRectMake(_imageView.frame.origin.x + (_imageView.frame.size.width - width) / 2,_imageView.frame.origin.y, width,_imageView.frame.size.height);
            }
            _clipGridView.clipRect = objRect;
            _imageClipRect = objRect;
        }
        else
        {
            _clipGridView.clipRect = _imageView.frame;
            _imageClipRect = _imageView.frame;
        }
    }
    CGFloat ratio = self->_image.size.width / self->_imageView.frame.size.width;
    self->_imageClipRect = CGRectMake((_clipGridView.clipRect.origin.x - self->_imageView.frame.origin.x) * ratio, (_clipGridView.clipRect.origin.y - self->_imageView.frame.origin.y) * ratio, _clipGridView.clipRect.size.width * ratio, _clipGridView.clipRect.size.height * ratio);
    _needResetClipGrid = NO;
}

static inline void GetPartOfImageInRect(CGRect partRect,UIImage *image,BHImageOutputBlock resultBlock){
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        CGImageRef imageRef = image.CGImage;
        CGImageRef imagePartRef = CGImageCreateWithImageInRect(imageRef, partRect);
        UIImage *retImg = [UIImage imageWithCGImage:imagePartRef];
        CGImageRelease(imagePartRef);
        dispatch_async(dispatch_get_main_queue(), ^{
            resultBlock(retImg);
        });
    });
}

@end
