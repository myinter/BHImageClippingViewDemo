//
//  PhotoSelectViewController.h
//  BeautyPlusMe
//
//  Created by xiongweihua on 2018/4/28.
//  Copyright © 2018年 xiongweihua. All rights reserved.
//

#import "BaseViewController.h"
#import "PhotoManager.h"
#import "AlbumSelectViewController.h"
#import "BHWaterFlowLayout.h"

@interface PhotoSelectViewController : BaseViewController<UICollectionViewDelegate,UICollectionViewDataSource,AlbumSelectViewControllerDelegate,UIScrollViewDelegate>
{    
    __weak IBOutlet UICollectionView *_collectionView;
        
    __weak IBOutlet UIButton *_titleButton;
    
    __weak IBOutlet NSLayoutConstraint *_viewTopCST;
    
    __weak IBOutlet NSLayoutConstraint *_viewBottomCST;
    
    NSMutableArray<PhotoModel *> *_photoList;
    //用来指示菜单的imgView
    __weak IBOutlet UIImageView *_menuTriangleImgView;
    
    __weak IBOutlet UITableView *_albumSelectTableView;
        
    AlbumSelectViewController *_albumSelectVC;
    
    __weak IBOutlet UIControl *_dimView;
    
    NSInteger _currentImgIndex;
    
    dispatch_semaphore_t _viewDidLoadSemaphore;
    
    BOOL _viewDidLoaded;
    
    __weak IBOutlet BHWaterFlowLayout *_fixedSizeFlowLayout;
    
    BOOL _isLoadMoreImage;
    
    ImageBlock _imageBlock;
    
}

@property(nonatomic,strong) AlbumModel *currentAlbum;


-(PhotoSelectViewController *)initWithImageBlock:(ImageBlock)imageBlock;

-(PhotoSelectViewController *)initWithAlbum:(AlbumModel *)album;


@end
