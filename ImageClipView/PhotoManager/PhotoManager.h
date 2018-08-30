//
//  PhotoManager.h
//  BeautyPlusMe
//
//  Created by xiongweihua on 2018/5/2.
//  Copyright © 2018年 xiongweihua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
@class AlbumModel;
@class PhotoModel;
typedef void(^ProgressBlock)(CGFloat progress);
typedef void(^AuthorizationBlock)(BOOL isAuthorized);
typedef void(^PhotoListBlock)(NSArray<PhotoModel *> *photoList);
typedef void(^AlbumListBlock)(NSArray<AlbumModel *> *albumList);
typedef void(^ImageBlock)(UIImage *image);

//从一个PHFetchResult中获取指定位置的图片

void LoadImgFromPhotoCollection(PHFetchResult *objCollection,NSInteger fromIndex,NSInteger toIndex,CGFloat targetSize,PhotoListBlock resultBlock);
void LoadAlbumList(AlbumListBlock resultBlock);
void RefreshAlbumInfo();
void LoadImgFromAlbum(AlbumModel *objAlbum,NSInteger fromIndex,NSInteger toIndex,CGFloat targetSize,PhotoListBlock resultBlock);
//申请获取相机权限
void RequestCameraAuthorization(AuthorizationBlock authorizeBlock);
//获取一个相册指定位置的缩略图
void albumLoadIconImage(AlbumModel *objAlbum,CGFloat targetSize,NSInteger index,ImageBlock block);
//获取一个结果集合指定位置的缩略图
void loadIconImage(AlbumModel *objAlbum,CGFloat targetSize,NSInteger index,ImageBlock block);
void LoadImg(AlbumModel *album,CGFloat targetSize,NSInteger atIndex,ImageBlock success);
void ReleaseImgCache(void);
void ReleaseAlbumCache(void);
@interface AlbumModel : NSObject
/*相册标题*/
@property(strong,nonatomic) NSString *albumTitle;
/*相册范例img*/
@property(strong,nonatomic) UIImage *iconImg;
/*相册的信息*/
@property(strong,nonatomic) PHFetchResult *albumInfo;
/*相册 为空的时候相册为“相机胶卷”*/
@property(strong,nonatomic) PHCollection *albumCollection;

@end

@interface PhotoModel : NSObject
/*相册范例img*/
@property(strong,nonatomic) UIImage *iconImg;
/*照片对应的信息*/
@property(strong,nonatomic) PHAsset *asset;
/*获得对应的全尺寸图像*/
-(void)getFullSizeImg:(void (^)(UIImage *fullSizeImg))resultBlock progressBlock:(ProgressBlock)progressBlock;
/**/
@property(strong,nonatomic) NSString *URLonLocalDisk;

@property(strong,nonatomic) NSMutableArray<ImageBlock> *waitingBlockQueue;

@property(nonatomic) BOOL isLoadingFullSizeImg;
@end

@interface PhotoManager : NSObject
/*获取所有相册的列表，包括相机胶卷*/
+(void)loadAlbumList:(void (^)(NSArray<AlbumModel *> *albumList))resultBlock;
/*获取某一个相册全部的缩略图*/
+(void)loadAllImgFromPhotoAlbum:(AlbumModel *)album targetSize:(CGFloat)size success:(void (^)(NSArray<PhotoModel *> *photoList))resultBlock;
/*获取某一个相册部分的缩略图*/
+(void)loadImgFromPhotoAlbum:(AlbumModel *)album fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex targetSize:(CGFloat)size success:(void (^)(NSArray<PhotoModel *> *photoList))resultBlock;
/*获取某一个PHFetchResult全部的缩略图*/
+(void)loadAllImgFromPhotoCollection:(PHFetchResult *)objCollection targetSize:(CGFloat)size success:(void (^)(NSArray<PhotoModel *> *photoList))resultBlock;
/*获取某一个PHFetchResult指定范围内的缩略图*/
+(void)loadImgFromPhotoCollection:(PHFetchResult *)objCollection fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex targetSize:(CGFloat)targetSize success:(void (^)(NSArray<PhotoModel *> *photoList))resultBlock;

@end
