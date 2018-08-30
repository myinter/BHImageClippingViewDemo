//
//  PhotoManager.m
//  BeautyPlusMe
//
//  Created by xiongweihua on 2018/5/2.
//  Copyright © 2018年 xiongweihua. All rights reserved.
//

#import "PhotoManager.h"
#import "AppDelegate.h"
#import <UIKit/UIKit.h>
#import "UIImage+resize.h"

static NSMutableDictionary *PhotomanagerImageCache = nil;

@implementation AlbumModel

-(void)loadAllImgsTargetSize:(CGFloat)targetSize success:(void (^)(NSArray<PhotoModel *> *photoList))resultBlock
{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            CGSize size = CGSizeMake(targetSize * [UIScreen mainScreen].scale, targetSize * [UIScreen mainScreen].scale);
            NSMutableArray *photoList = [NSMutableArray arrayWithCapacity:self->_albumInfo.count];
            PHImageRequestOptions *opt = [[PHImageRequestOptions alloc]init];
            opt.synchronous = YES;
            [self->_albumInfo enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
                NSLog(@"PHAsset %@",asset);
                [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFit options:opt resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    if (result) {
                        NSLog(@"resultImg %@ scale = %f",[NSValue valueWithCGSize:result.size],result.scale);
                        PhotoModel *model = [PhotoModel new];
                        model.iconImg = result;
                        NSLog(@"model.iconImg %@",model.iconImg);
                        model.asset = asset;
                        model.URLonLocalDisk = info[@"PHImageFileURLKey"];
                        [photoList addObject:model];
                    }
                }];
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(photoList);
            });
        });
}

//载入本相册，指定位置的某个图片到指定的尺寸
-(void)loadImgTargetSize:(CGFloat)targetSize AtIndex:(NSInteger)index success:(void (^)(UIImage *image))resultBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        CGSize size = CGSizeMake(targetSize * [UIScreen mainScreen].scale, targetSize * [UIScreen mainScreen].scale);
        PHImageRequestOptions *opt = [[PHImageRequestOptions alloc]init];
        opt.synchronous = NO;
        PHAsset *asset = self->_albumInfo[index];
        NSLog(@"PHAsset %@",asset);
        
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:opt resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
           //将图片裁剪到所需要的尺寸
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
                UIImage *image = [UIImage imageWithData:imageData];
                NSLog(@"%f %f",image.size.width,image.size.height);
                [image transformToWidth:size.width height:size.height scale:image.scale];
                NSLog(@"%f %f",image.size.width,image.size.height);
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(image);
                });
            });
        }];
    });
}

void LoadImg(AlbumModel *album,CGFloat targetSize,NSInteger atIndex,ImageBlock success)
{
    NSString *keyForCache = [NSString stringWithFormat:@"%@%d",album.albumCollection.localIdentifier,atIndex];
    UIImage *cachedImg = PhotomanagerImageCache[keyForCache];
    if (cachedImg) {
        success(cachedImg);
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        PHImageRequestOptions *opt = [[PHImageRequestOptions alloc]init];
        opt.synchronous = NO;
        PHAsset *asset = album->_albumInfo[atIndex];
        NSLog(@"PHAsset %@",asset);
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:opt resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            //将图片裁剪到所需要的尺寸
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
                UIImage *image = [UIImage imageWithData:imageData];
                CGFloat objWidth = image.size.width;
                CGFloat objHeight = image.size.height;
                if (!(objWidth < 100 && objHeight < 100)) {
                    if (objWidth > objHeight) {
                        objHeight = 100 * (objHeight / objWidth);
                        objWidth = 100;
                    }
                    else
                    {
                        objWidth = 100 * (objWidth / objHeight);
                        objHeight = 100;
                    }
                }
                NSLog(@"objWidth %f objHeight %f",objWidth,objHeight);
                
                if (PhotomanagerImageCache == nil) {
                    PhotomanagerImageCache = [NSMutableDictionary dictionaryWithCapacity:1000];
                }
                NSLog(@"image.size.width %f image.size.height %f",image.size.width,image.size.height);
                image = [image transformToWidth:objWidth height:objHeight scale:image.scale];
                NSLog(@"%f %f",image.size.width,image.size.height);
                PhotomanagerImageCache[keyForCache] = image;
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(image);
                });
            });
        }];
    });

}

@end
@implementation PhotoModel

#define LOW_PERFORMANCE_MAX_WIDTH 1080
#define LOW_PERFORMANCE_MAX_HEIGHT 1920
#define LOW_PERFORMANCE_1
-(NSMutableArray *)waitingBlockQueue
{
    if (_waitingBlockQueue == nil) {
        _waitingBlockQueue = [NSMutableArray new];
    }
    return _waitingBlockQueue;
}

/*获得对应的全尺寸图像*/
-(void)getFullSizeImg:(void (^)(UIImage *fullSizeImg))resultBlock progressBlock:(ProgressBlock)progressBlock
{
    if (_asset != nil) {
        [self.waitingBlockQueue addObject:resultBlock];
        if (_isLoadingFullSizeImg) {
            
            return;
        }
        _isLoadingFullSizeImg = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSLog(@"photo url = %@",self->_URLonLocalDisk);
            PHImageRequestOptions *opt = [[PHImageRequestOptions alloc]init];
            opt.synchronous = NO;
            opt.networkAccessAllowed = YES;
            [opt setProgressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                if (progressBlock) {
                    progressBlock(progress);
                }
            }];
#ifdef LOW_PERFORMANCE_1
            //低性能设备不加载全尺寸图片，加载图片尺寸收到限制
            if (NO && (self->_asset.pixelWidth > LOW_PERFORMANCE_MAX_WIDTH || self->_asset.pixelHeight > LOW_PERFORMANCE_MAX_HEIGHT)) {
                CGSize objSize;
                if(self->_asset.pixelWidth > LOW_PERFORMANCE_MAX_WIDTH)
                {
                    objSize = CGSizeMake(LOW_PERFORMANCE_MAX_WIDTH, LOW_PERFORMANCE_MAX_WIDTH * (self->_asset.pixelHeight / self->_asset.pixelWidth));
                    if (objSize.height > LOW_PERFORMANCE_MAX_HEIGHT) {
                        objSize = CGSizeMake((objSize.width / objSize.height) * LOW_PERFORMANCE_MAX_HEIGHT, LOW_PERFORMANCE_MAX_HEIGHT);
                    }
                }
                else
                {
                    objSize = CGSizeMake(LOW_PERFORMANCE_MAX_HEIGHT * (self->_asset.pixelWidth / self->_asset.pixelHeight), LOW_PERFORMANCE_MAX_HEIGHT);
                    if (objSize.width > LOW_PERFORMANCE_MAX_WIDTH) {
                        objSize = CGSizeMake(LOW_PERFORMANCE_MAX_WIDTH, LOW_PERFORMANCE_MAX_WIDTH * (self->_asset.pixelHeight/self->_asset.pixelWidth));
                    }
                }
                [[PHImageManager defaultManager]requestImageForAsset:self->_asset targetSize:objSize contentMode:PHImageContentModeAspectFit options:opt resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    self->_isLoadingFullSizeImg = NO;
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        UIImage *resultImage = [result fixOrientation];
                        if ((result.size.width/objSize.width) > 0.5) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSLog(@"result %@ info %@",resultImage,info);
                                [self.waitingBlockQueue enumerateObjectsUsingBlock:^(ImageBlock  _Nonnull block, NSUInteger idx, BOOL * _Nonnull stop) {
                                    block(resultImage);
                                }];
                                BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                                if (downloadFinined) {
                                    NSLog(@"remove");
                                    [self.waitingBlockQueue removeAllObjects];
                                }
                            });
                        }
                    });
                 }];
            }
            else
            {
                
                [[PHImageManager defaultManager] requestImageDataForAsset:self->_asset options:opt resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    NSLog(@"img is loading imageData.length %Ld",imageData.length);
                    if (imageData && imageData.length) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            @autoreleasepool
                            {
                                UIImage *image = [UIImage imageWithData:imageData];
                                image = [image fixOrientation];
                                NSLog(@"full size img %@",image);
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    self->_isLoadingFullSizeImg = NO;
                                    [self.waitingBlockQueue enumerateObjectsUsingBlock:^(ImageBlock  _Nonnull block, NSUInteger idx, BOOL * _Nonnull stop) {
                                        block(image);
                                    }];
                                    [self.waitingBlockQueue removeAllObjects];
                                });
                            }
                        });
                    }
                    else
                    {
                        //若为空，则表明是iCloud上的图片，需要再做一次图片加载操作
                        //icloud加载图片，为了保证加载速度，不使用最大的图片。
                            [[PHImageManager defaultManager]requestImageForAsset:self->_asset targetSize:CGSizeMake(720, 720) contentMode:PHImageContentModeAspectFit options:opt resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                    UIImage *resultImage = [result fixOrientation];
                                    self->_isLoadingFullSizeImg = NO;
                                    NSLog(@"网络加载图片iCloud result %@ info %@ imageSize %@ objSize",resultImage,info,[NSValue valueWithCGSize:result.size]);
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [self.waitingBlockQueue enumerateObjectsUsingBlock:^(ImageBlock  _Nonnull block, NSUInteger idx, BOOL * _Nonnull stop) {
                                            block(resultImage);
                                        }];
                                        if (![[info objectForKey:PHImageResultIsDegradedKey] boolValue] && resultImage) {
                                            NSLog(@"remove");
                                            [self.waitingBlockQueue removeAllObjects];
                                        }
                                    });
                                });
                            }];

                    }
                }];
            }
#endif
        });
        
    }
    else
    {
        resultBlock(nil);
    }
}


@end

@implementation PhotoManager

#define ICON_SIZE 60.0f*[UIScreen mainScreen].scale

static NSArray<AlbumModel *> *albumList = nil;

void ReleaseAlbumCache()
{
    albumList = nil;
}

void LoadAlbumList(AlbumListBlock resultBlock)
{
    if (albumList) {
        if (resultBlock) {
            resultBlock(albumList);
        }
        return;
    }
    
    PHAuthorizationStatus photoStatus = [PHPhotoLibrary authorizationStatus];
    
    void(^loadBlock)() = ^() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            //先拿到相机胶卷，这个相册独立于所有智能相册
            PHFetchResult *smartAlbums = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
            NSLog(@"smartAlbums %ld",smartAlbums.count);
            NSMutableArray *array = [NSMutableArray arrayWithCapacity:smartAlbums.count + 1];
            CGSize iconSize = CGSizeMake(ICON_SIZE, ICON_SIZE);
            PHFetchResult *cameraRoll = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
            PHImageRequestOptions *opt = [[PHImageRequestOptions alloc]init];
            opt.synchronous = YES;
            opt.networkAccessAllowed = YES;
            
            if (cameraRoll.count) {
                PHAsset *cameraImg = cameraRoll.lastObject;
                if (cameraImg) {
                    [[PHImageManager defaultManager]requestImageForAsset:cameraImg targetSize:iconSize contentMode:PHImageContentModeAspectFill options:opt resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                        NSLog(@"result.size%@ result.scale%f",[NSValue valueWithCGSize:result.size],result.scale);
                        NSLog(@"Album Info %@",info);
                        if (result) {
                            AlbumModel *model = [AlbumModel new];
                            model.albumTitle = NSLocalizedString(@"All Photos", nil);
                            model.iconImg = result;
                            model.albumInfo = cameraRoll;
                            model.albumCollection = nil;
                            [array addObject:model];
                        }
                    }];
                }
            }
            
            for (NSInteger i = 0; i < smartAlbums.count; i++) {
                PHCollection *collection = smartAlbums[i];
                //遍历获取相册
                if ([collection isKindOfClass:[PHAssetCollection class]]) {
                    PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
                    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
                    PHAsset *asset = fetchResult.lastObject;
                    if (asset) {
                        //取第一张图片为缩略样例图
                        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:iconSize contentMode:PHImageContentModeAspectFill options:opt resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                            if (result) {
                                AlbumModel *model = [AlbumModel new];
                                model.albumTitle = collection.localizedTitle;
                                model.iconImg = result;
                                model.albumInfo = fetchResult;
                                model.albumCollection = collection;
                                NSLog(@"Album Info model.albumTitle %@ model.albumInfo.count %d",model.albumTitle,model.albumInfo.count);
                                [array addObject:model];
                            }
                        }];
                    }
                }
            }
            //将结果输出出去。
            albumList = array;
            
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(array);
                });
            }

        });
    };
    
    if (photoStatus != PHAuthorizationStatusAuthorized) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                switch (status) {
                    case PHAuthorizationStatusAuthorized: //已获取权限
                    {
                        loadBlock();
                    }
                        break;
                    case PHAuthorizationStatusDenied: //用户已经明确否认了这一照片数据的应用程序访问
                    case PHAuthorizationStatusRestricted://此应用程序没有被授权访问的照片数据。可能是家长控制权限
                    {
                    }
                        break;
                    default://其他。。。
                        break;
                }
            });
        }];
    }
    else
    {
        loadBlock();
    }

}

+(void)loadAlbumList:(void (^)(NSArray<AlbumModel *> *albumList))resultBlock;
{
    if (albumList) {
        resultBlock(albumList);
        return;
    }
    
    PHAuthorizationStatus photoStatus = [PHPhotoLibrary authorizationStatus];
    
    void(^loadBlock)() = ^() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            //先拿到相机胶卷，这个相册独立于所有智能相册
            PHFetchResult *smartAlbums = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
            NSLog(@"smartAlbums %ld",smartAlbums.count);
            NSMutableArray *array = [NSMutableArray arrayWithCapacity:smartAlbums.count + 1];
            CGSize iconSize = CGSizeMake(ICON_SIZE, ICON_SIZE);
            PHFetchResult *cameraRoll = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
            PHImageRequestOptions *opt = [[PHImageRequestOptions alloc]init];
            opt.synchronous = YES;
            
            if (cameraRoll.count) {
                PHAsset *cameraImg = cameraRoll.lastObject;
                if (cameraImg) {
                    [[PHImageManager defaultManager]requestImageForAsset:cameraImg targetSize:iconSize contentMode:PHImageContentModeAspectFill options:opt resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                        NSLog(@"result.size%@ result.scale%f",[NSValue valueWithCGSize:result.size],result.scale);
                        NSLog(@"Album Info %@",info);
                        if (result) {
                            AlbumModel *model = [AlbumModel new];
                            model.albumTitle = NSLocalizedString(@"All Photos", nil);
                            model.iconImg = result;
                            model.albumInfo = cameraRoll;
                            model.albumCollection = nil;
                            [array addObject:model];
                        }
                    }];
                }
            }
            
            for (NSInteger i = 0; i < smartAlbums.count; i++) {
                PHCollection *collection = smartAlbums[i];
                //遍历获取相册
                if ([collection isKindOfClass:[PHAssetCollection class]]) {
                    PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
                    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
                    PHAsset *asset = fetchResult.lastObject;
                    if (asset) {
                        //取第一张图片为缩略样例图
                        PHImageRequestOptions *opt = [[PHImageRequestOptions alloc]init];
                        opt.synchronous = YES;
                        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:iconSize contentMode:PHImageContentModeAspectFill options:opt resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                            if (result) {
                                AlbumModel *model = [AlbumModel new];
                                model.albumTitle = collection.localizedTitle;
                                model.iconImg = result;
                                model.albumInfo = fetchResult;
                                model.albumCollection = collection;
                                NSLog(@"Album Info model.albumTitle %@ model.albumInfo.count %d",model.albumTitle,model.albumInfo.count);
                                [array addObject:model];
                            }
                        }];
                    }
                }
            }
            //将结果输出出去。
            albumList = array;
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(array);
            });
        });
    };

    if (photoStatus != PHAuthorizationStatusAuthorized) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                switch (status) {
                    case PHAuthorizationStatusAuthorized: //已获取权限
                    {
                        loadBlock();
                    }
                        break;
                    case PHAuthorizationStatusDenied: //用户已经明确否认了这一照片数据的应用程序访问
                    case PHAuthorizationStatusRestricted://此应用程序没有被授权访问的照片数据。可能是家长控制权限
                    {
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"未能获得照片权限", @"") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
                    }
                        break;
                    default://其他。。。
                        break;
                }
            });
        }];
    }
    else
    {
        loadBlock();
    }
}

+(void)loadAllImgFromPhotoAlbum:(AlbumModel *)album targetSize:(CGFloat)size success:(void (^)(NSArray<PhotoModel *> *photoList))resultBlock
{
    [self loadAllImgFromPhotoCollection:album.albumInfo targetSize:size success:resultBlock];
}

+(void)loadImgFromPhotoAlbum:(AlbumModel *)album fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex targetSize:(CGFloat)size success:(void (^)(NSArray<PhotoModel *> *photoList))resultBlock
{
    [self loadImgFromPhotoCollection:album.albumInfo fromIndex:fromIndex toIndex:toIndex targetSize:size success:resultBlock];
}

+(void)loadAllImgFromPhotoCollection:(PHFetchResult *)objCollection targetSize:(CGFloat)targetSize success:(void (^)(NSArray<PhotoModel *> *photoList))resultBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        CGSize size = CGSizeMake(targetSize * [UIScreen mainScreen].scale, targetSize * [UIScreen mainScreen].scale);
        NSMutableArray *photoList = [NSMutableArray arrayWithCapacity:objCollection.count];
        PHImageRequestOptions *opt = [[PHImageRequestOptions alloc]init];
        opt.synchronous = YES;
        [objCollection enumerateObjectsUsingBlock:^(PHAsset   * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
            NSLog(@"PHAsset %@",asset);
            [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFit options:opt resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                if (result) {
                    NSLog(@"resultImg %@ scale = %f",[NSValue valueWithCGSize:result.size],result.scale);
                    PhotoModel *model = [PhotoModel new];
                    model.iconImg = result;
                    NSLog(@"model.iconImg %@",model.iconImg);
                    model.asset = asset;
                    model.URLonLocalDisk = info[@"PHImageFileURLKey"];
                    [photoList addObject:model];
                }
            }];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            resultBlock(photoList);
        });
    });
}

void RequestCameraAuthorization(AuthorizationBlock authorizeBlock)
{
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (authorizationStatus) {
        case AVAuthorizationStatusNotDetermined:
        {
            //现状为未授权，请求授权 Status is unauthorized, request authorization
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                authorizeBlock(granted);
            }];
        }
            break;
        case AVAuthorizationStatusAuthorized:
        {
            authorizeBlock(YES);
        }
            break;
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                authorizeBlock(granted);
            }];
        }
            break;
        default:
            break;
    }
}

+ (void)cameraAuthorization:(void (^)(BOOL isAuthorized))authorizeBlock
{
    
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (authorizationStatus) {
        case AVAuthorizationStatusNotDetermined:
            {
                //现状为未授权，请求授权 Status is unauthorized, request authorization
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    authorizeBlock(granted);
                }];
            }
            break;
        case AVAuthorizationStatusAuthorized:
        {
            authorizeBlock(YES);
        }
            break;
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
        {
            authorizeBlock(NO);
        }
            break;
        default:
            break;
    }
}

void albumLoadIconImage(AlbumModel *objAlbum,CGFloat targetSize,NSInteger index,ImageBlock block)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @autoreleasepool
        {
            CGSize size = CGSizeMake(targetSize * [UIScreen mainScreen].scale, targetSize * [UIScreen mainScreen].scale);
            PHImageRequestOptions *opt = [[PHImageRequestOptions alloc]init];
            opt.synchronous = YES;
            PHFetchResult *albumInfo = objAlbum.albumInfo;
            if (index < albumInfo.count) {
                PHAsset *asset = albumInfo[index];
                [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFit options:opt resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    if (result) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            block(result);
                        });
                    }
                }];
            }
        }
    });
}

void ReleaseImgCache(void)
{
    PhotomanagerImageCache = nil;
}

void loadIconImage(AlbumModel *objAlbum,CGFloat targetSize,NSInteger index,ImageBlock block)
{
    NSString *keyForCache = [NSString stringWithFormat:@"%@%d%f",objAlbum.albumCollection.localIdentifier,index,targetSize];
    UIImage *cachedImg = PhotomanagerImageCache[keyForCache];
    if (cachedImg) {
        block(cachedImg);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        CGSize size = CGSizeMake(targetSize * [UIScreen mainScreen].scale, targetSize * [UIScreen mainScreen].scale);
        PHImageRequestOptions *opt = [[PHImageRequestOptions alloc]init];
        opt.synchronous = YES;
            if (index < objAlbum.albumInfo.count) {
                NSLog(@"load img %d",index);
                PHAsset *asset = objAlbum.albumInfo[index];
                [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFit options:opt resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    
                    if (PhotomanagerImageCache == nil) {
                        PhotomanagerImageCache = [NSMutableDictionary dictionaryWithCapacity:1000];
                    }
                    
                    PhotomanagerImageCache[keyForCache] = result;
                    
                    if (result) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            block(result);
                        });
                    }
                }];
            }
    });
}

void LoadImgFromAlbum(AlbumModel *objAlbum,NSInteger fromIndex,NSInteger toIndex,CGFloat targetSize,PhotoListBlock resultBlock)
{
    loadImgFromPhotoCollection(objAlbum.albumInfo, fromIndex, toIndex, targetSize, resultBlock);
}

void loadImgFromPhotoCollection(PHFetchResult *objCollection,NSInteger fromIndex,NSInteger toIndex,CGFloat targetSize,PhotoListBlock resultBlock)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        CGSize size = CGSizeMake(targetSize * [UIScreen mainScreen].scale, targetSize * [UIScreen mainScreen].scale);
        NSMutableArray *photoList = [NSMutableArray arrayWithCapacity:objCollection.count];
        PHImageRequestOptions *opt = [[PHImageRequestOptions alloc]init];
        opt.synchronous = YES;
        NSInteger step;
        if (toIndex > fromIndex) {
            step = 1;
        }
        else
        {
            step = -1;
        }
        
        for (NSInteger i = fromIndex; toIndex > fromIndex ? i <= toIndex : i >= toIndex ;i+=step) {
            if (i < objCollection.count && i >= 0) {
                PHAsset *asset = objCollection[i];
                NSLog(@"current INDEX imageLoaded %d",i);
                [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFit options:opt resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    if (result) {
                        PhotoModel *model = [PhotoModel new];
                        model.iconImg = result;
                        model.asset = asset;
                        NSLog(@"photo url = %@",info[@"PHImageFileURLKey"]);
                        model.URLonLocalDisk = info[@"PHImageFileURLKey"];
                        [photoList addObject:model];
                    }
                }];
            }
            else
            {
                break;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            resultBlock(photoList);
        });
    });
}

+(void)loadImgFromPhotoCollection:(PHFetchResult *)objCollection fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex targetSize:(CGFloat)targetSize success:(void (^)(NSArray<PhotoModel *> *photoList))resultBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            CGSize size = CGSizeMake(targetSize * [UIScreen mainScreen].scale, targetSize * [UIScreen mainScreen].scale);
            NSMutableArray *photoList = [NSMutableArray arrayWithCapacity:objCollection.count];
            PHImageRequestOptions *opt = [[PHImageRequestOptions alloc]init];
            opt.synchronous = YES;
            NSInteger step;
            if (toIndex > fromIndex) {
                step = 1;
            }
            else
            {
                step = -1;
            }
        
            for (NSInteger i = fromIndex; toIndex > fromIndex ? i <= toIndex : i >= toIndex ;i+=step) {
                if (i < objCollection.count && i >= 0) {
                    PHAsset *asset = objCollection[i];
                    NSLog(@"currentIndex %d",i);
                    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFit options:opt resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                        if (result) {
                            PhotoModel *model = [PhotoModel new];
                            model.iconImg = result;
                            model.asset = asset;
                            model.URLonLocalDisk = info[@"PHImageFileURLKey"];
                            [photoList addObject:model];
                        }
                    }];
                }
                else
                {
                    break;
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(photoList);
            });
    });
}


@end
