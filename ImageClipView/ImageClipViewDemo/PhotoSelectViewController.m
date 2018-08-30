//
//  PhotoSelectViewController.m
//  BeautyPlusMe
//
//  Created by xiongweihua on 2018/4/28.
//  Copyright © 2018年 xiongweihua. All rights reserved.
//

#import "PhotoSelectViewController.h"
#import <Photos/Photos.h>
#import "PhotoCell.h"

@interface PhotoSelectViewController ()

@end

@implementation PhotoSelectViewController

static NSString *cellReuseId = @"PhotoCell";
#define ITEM_GAP 3.0F
#define INSECT 3.0f
#define STANDARD_ITEM_SIZE 85

-(PhotoSelectViewController *)initWithImageBlock:(ImageBlock)block
{
    self = [self init];
    if (self) {
        _imageBlock = block;
    }
    return self;
}
-(PhotoSelectViewController *)initWithAlbum:(AlbumModel *)album
{
    self = [super init];
    if(self)
    {
        
    }
    return self;
}

-(PhotoSelectViewController *)init
{
    self = [super init];
    if (self) {
        _viewDidLoadSemaphore = dispatch_semaphore_create(0);
        [self reloadAllPhotos];
    }
    return self;
}

- (void)reloadAllPhotos{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        self->_albumSelectVC = [AlbumSelectViewController new];
        self->_albumSelectVC.delegate = self;
        self->_albumSelectVC.isForNonFullScreen = YES;
        LoadAlbumList(^(NSArray<AlbumModel *> *albumList) {
            if (self->_viewDidLoaded) {
                [self->_albumSelectVC setAlbums:albumList];
                self.currentAlbum = albumList.firstObject;
            }
            else
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    dispatch_semaphore_wait(self->_viewDidLoadSemaphore, DISPATCH_TIME_FOREVER);
                    [self->_albumSelectVC setAlbums:albumList];
                    self.currentAlbum = albumList.firstObject;
                });
            }
        });
    });
}

-(void)aNewPhotoSaved
{
    ReleaseAlbumCache();
    [self reloadAllPhotos];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [_collectionView registerNib:[UINib nibWithNibName:cellReuseId bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:cellReuseId];
    [_titleButton setTitle:self.title forState:UIControlStateNormal];
    //设置上拉加载更多
    _fixedSizeFlowLayout.sectionInset = UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0);
    _fixedSizeFlowLayout.columnNumber =  MAX(4, sqrt(([UIScreen mainScreen].bounds.size.width / 411)) * 4);
    _fixedSizeFlowLayout.horizontalMargin = 5.0;
    _fixedSizeFlowLayout.verticalMargin = 5.0;
    dispatch_semaphore_signal(self->_viewDidLoadSemaphore);
    _viewDidLoaded = YES;
    _fixedSizeFlowLayout.delegate = self;
}

-(CGFloat)heightWidthRatioForItemAtIndex:(NSInteger)index
{
    return 1.0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setCurrentAlbum:(AlbumModel *)currentAlbum
{
    if (currentAlbum != _currentAlbum) {
        [_fixedSizeFlowLayout refresh];
        _currentImgIndex = currentAlbum.albumInfo.count - 1;
        NSLog(@"currentAlbum.albumInfo.count %d",currentAlbum.albumInfo.count);
        _currentAlbum = currentAlbum;
        if (!_photoList) {
            _photoList = [NSMutableArray arrayWithCapacity:3000];
        }
        self.title = _currentAlbum.albumTitle;
        [_titleButton setTitle:self.title forState:UIControlStateNormal];
        //因为是新加载，所以清空原有的布局信息。
        [self loadMoreImage:YES];
    }
}

- (IBAction)cancelButtonClicked:(UIButton *)sender {
    //取消,cancel
    [self.navigationController popViewControllerAnimated:YES];
}
#define SHOW_ALBUMS_MENU 10086
#define GO_BACK 586
#define DIM_VIEW 4399
- (IBAction)buttonsClicked:(UIControl *)sender {
    switch (sender.tag) {
        case SHOW_ALBUMS_MENU:
        {
            if (_albumSelectVC.view.superview) {
                [self AlbumSelectMenuShow:NO];
            }
            else
            {
                [self AlbumSelectMenuShow:YES];
            }
        }
            break;
        case GO_BACK:
        {
            if (_albumSelectVC.view.superview) {
                [self AlbumSelectMenuShow:NO];
            }
            else
            {
                [self goBackAnimated:YES];
            }
        }
            break;
        case DIM_VIEW:
        {
            _dimView.hidden = YES;
            [self AlbumSelectMenuShow:NO];
        }
            break;
        default:
            break;
    }
}

//显示相册选择
-(void)AlbumSelectMenuShow:(BOOL)show
{
    if (show) {
        _dimView.hidden = NO;
        [self.view addSubview:_albumSelectVC.view];
        _albumSelectVC.view.frame = CGRectMake(0.0f, _collectionView.frame.size.height + _collectionView.frame.origin.y, _collectionView.frame.size.width, _collectionView.frame.size.height);
        [UIView animateWithDuration:0.4 animations:^{
            self->_menuTriangleImgView.transform = CGAffineTransformMakeRotation(-M_PI/2);
            self->_albumSelectVC.view.frame = self->_collectionView.frame;
        }];
    }
    else
    {
        _dimView.hidden = YES;
        [UIView animateWithDuration:0.5 animations:^{
            self->_menuTriangleImgView.transform =CGAffineTransformMakeRotation(0);
            self->_albumSelectVC.view.frame = CGRectMake(0.0f, self->_collectionView.frame.size.height + self->_collectionView.frame.origin.y, self->_collectionView.frame.size.width, self->_collectionView.frame.size.height);
        } completion:^(BOOL finished) {
            [self->_albumSelectVC.view removeFromSuperview];
        }];
    }
}

-(void)loadMoreImage:(BOOL)refresh
{
    
    if (_isLoadMoreImage) {
        return;
    }
    _isLoadMoreImage = YES;
    
    NSInteger itemPerPage = (_collectionView.frame.size.width / _fixedSizeFlowLayout.itemSize.width) * (_collectionView.frame.size.height / _fixedSizeFlowLayout.itemSize.height) * 1.2;
    
    LoadImgFromAlbum(_currentAlbum, _currentImgIndex, _currentImgIndex-itemPerPage, _fixedSizeFlowLayout.itemSize.width, ^(NSArray<PhotoModel *> *photoList) {
        NSLog(@"imageLoaded");
        if (refresh) {
            [self->_photoList removeAllObjects];
            [self->_fixedSizeFlowLayout refresh];
            [self->_collectionView reloadData];
        }
        
        if (self->_viewDidLoaded) {
            NSInteger formerIndex = self->_photoList.count;
            [self->_photoList addObjectsFromArray:photoList];
            self->_fixedSizeFlowLayout.numberOfItems = self->_photoList.count;
            self->_currentImgIndex = self->_currentAlbum.albumInfo.count - self->_photoList.count;
            if (photoList.count == itemPerPage && self->_photoList.count < 40) {
                [self loadMoreImage:NO];
            }
            else
            {
                [self->_fixedSizeFlowLayout calculateLayoutFromIndex:formerIndex reloadAfterCalculated:YES];
            }
        }
        else
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                dispatch_semaphore_wait(self->_viewDidLoadSemaphore,DISPATCH_TIME_FOREVER);
                NSInteger formerIndex = self->_photoList.count;
                [self->_photoList addObjectsFromArray:photoList];
                self->_fixedSizeFlowLayout.numberOfItems = self->_photoList.count;
                self->_currentImgIndex = self->_currentAlbum.albumInfo.count - self->_photoList.count;
                if (photoList.count == itemPerPage && self->_photoList.count < 40) {
                    [self loadMoreImage:NO];
                }
                else
                {
                    [self->_fixedSizeFlowLayout calculateLayoutFromIndex:formerIndex reloadAfterCalculated:YES];
                }
            });
        }
        self->_isLoadMoreImage = NO;
    });
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _photoList.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellReuseId forIndexPath:indexPath];
    
    if (indexPath.row < _photoList.count) {
        //呈现照片的Cell
        cell.imgView.contentMode = UIViewContentModeScaleAspectFill;
        cell.imgView.image = _photoList[indexPath.row].iconImg;
        cell.imgView.backgroundColor = [UIColor lightGrayColor];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_imageBlock) {
        PhotoModel *model = _photoList[indexPath.row];
        __weak PhotoSelectViewController *weakSelf = self;
        [model getFullSizeImg:^(UIImage *fullSizeImg) {
            __strong PhotoSelectViewController *strongSelf = weakSelf;
            if (strongSelf) {
                strongSelf->_imageBlock(fullSizeImg);
                strongSelf->_imageBlock = nil;
                [strongSelf goBackAnimated:YES];
            }
        } progressBlock:^(CGFloat progress) {
            
        }];
    }
}

-(void)selectedAlbum:(AlbumModel *)selectedAlbum
{
    if (_titleButton.userInteractionEnabled) {
        self.currentAlbum = selectedAlbum;
        [self AlbumSelectMenuShow:NO];
    }
}

-(void)adjustForFringeScreen
{
    [super adjustForFringeScreen];
    _viewTopCST.constant += 34.0f;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self AlbumSelectMenuShow:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
//    NSLog(@"scrollView.contentSize.height - scrollView.contentOffset.y = %f",scrollView.contentSize.height - scrollView.contentOffset.y);
    if ((scrollView.contentSize.height - scrollView.contentOffset.y) < scrollView.frame.size.height * 3.14) {
        [self loadMoreImage:NO];
    }
}

-(BOOL)shouldAutorotate
{
    return YES;
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
        [_fixedSizeFlowLayout.layoutAttributes removeAllObjects];
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
