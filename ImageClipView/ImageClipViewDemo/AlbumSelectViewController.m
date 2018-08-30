//
//  AlbumSelectViewController.m
//  BeautyPlusMe
//
//  Created by xiongweihua on 2018/4/28.
//  Copyright © 2018年 xiongweihua. All rights reserved.
//

#import "AlbumSelectViewController.h"
#import <Photos/Photos.h>
#import "BPMAlbumCell.h"
#import "PhotoSelectViewController.h"

@interface AlbumSelectViewController ()

@end

#define CELL_REUSE_ID @"bpmalbumCell"

@implementation AlbumSelectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // 所有智能相册
    if (!_isForNonFullScreen) {
        [self loadAllAlbums];
    }
    
    if (_isForNonFullScreen) {
        _topNavBar.hidden = YES;
        _tableViewTopCST.constant = 0.0;
        _navBarHeightCST.constant = 0.0;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadAllAlbums
{
    [PhotoManager loadAlbumList:^(NSArray<AlbumModel *> *albumList) {
        self->_albumList = albumList;
        [self->_tableView reloadData];
    }];
    return;
}

-(void)setAlbums:(NSArray<AlbumModel *> *)albumList
{
    _albumList = albumList;
    [_tableView reloadData];
}

-(void)adjustForFringeScreen
{
    if (!_isForNonFullScreen) {
        [super adjustForFringeScreen];
        _tableViewTopCST.constant = 34.0f;
        _tableViewBottomCST.constant += 34.0f;
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _albumList.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BPMAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_REUSE_ID];
    if (cell == nil) {
        cell = [BPMAlbumCell cellFromNib];
    }
    AlbumModel *model = _albumList[indexPath.row];
    cell.titleLabel.text = model.albumTitle;
    if (model.albumInfo.count) {
        cell.imgView.image = model.iconImg;
    }
    else
    {
        cell.imgView.image = nil;
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AlbumModel *model = _albumList[indexPath.row];
    if (_delegate) {
        [_delegate selectedAlbum:model];
    }
    else
    {
        PhotoSelectViewController *vc = [[PhotoSelectViewController alloc]initWithAlbum:model];
        [self.navigationController pushViewController:vc animated:YES];
    }
}
- (IBAction)buttonsClicked:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
