//
//  AlbumSelectViewController.h
//  BeautyPlusMe
//
//  Created by xiongweihua on 2018/4/28.
//  Copyright © 2018年 xiongweihua. All rights reserved.
//

#import "BaseViewController.h"
@class PHFetchResult;
#import "PhotoManager.h"
@protocol AlbumSelectViewControllerDelegate <NSObject>

-(void)selectedAlbum:(AlbumModel *)selectedAlbum;

@end
@interface AlbumSelectViewController : BaseViewController<UITableViewDelegate,UITableViewDataSource>
{
    __weak IBOutlet NSLayoutConstraint *_tableViewTopCST;
        
    __weak IBOutlet NSLayoutConstraint *_tableViewBottomCST;
    
    __weak IBOutlet UITableView *_tableView;
    
    NSArray<AlbumModel *> *_albumList;
    
    __weak IBOutlet UIView *_topNavBar;
    
    __weak IBOutlet NSLayoutConstraint *_navBarHeightCST;
}

-(void)loadAllAlbums;

@property(nonatomic,weak) id<AlbumSelectViewControllerDelegate> delegate;

@property(nonatomic) BOOL isForNonFullScreen;

-(void)setAlbums:(NSArray<AlbumModel *> *)albumList;

@end
